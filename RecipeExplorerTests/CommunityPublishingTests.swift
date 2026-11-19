import XCTest
@testable import RecipeExplorer

/// Tests for publishing recipes to the community feed and author-only editing/deleting.
/// Two stores with separate storage ("Alice" and "Bob") share one community service,
/// which simulates two users on different phones talking to the same server.
@MainActor
final class CommunityPublishingTests: XCTestCase {
    private var community: LocalCommunityService!
    private var aliceDefaults: UserDefaults!
    private var bobDefaults: UserDefaults!
    private var alice: RecipeStore!
    private var bob: RecipeStore!
    private var suiteNames: [String] = []

    override func setUp() async throws {
        community = LocalCommunityService(defaults: nil, seed: [])   // in-memory, empty feed
        aliceDefaults = makeDefaults()
        bobDefaults = makeDefaults()
        alice = RecipeStore(defaults: aliceDefaults, community: community)
        bob = RecipeStore(defaults: bobDefaults, community: community)
    }

    override func tearDown() async throws {
        for name in suiteNames { UserDefaults(suiteName: name)?.removePersistentDomain(forName: name) }
        suiteNames = []
    }

    // MARK: - Helpers

    private func makeDefaults() -> UserDefaults {
        let name = "CommunityTests-\(UUID().uuidString)"
        suiteNames.append(name)
        return UserDefaults(suiteName: name)!
    }

    private func makeRecipe(_ title: String = "Shared Soup") -> Recipe {
        Recipe(title: title, description: "desc", category: "Dinner", cuisine: "Test",
               prepTime: 5, cookTime: 10, servings: 2, difficulty: "Easy", rating: 0,
               author: "Alice", imageURL: "", tags: ["Vegetarian"],
               ingredients: [Ingredient(item: "Water", amount: "2 cups")],
               instructions: ["Boil.", "Serve."], isUserCreated: true)
    }

    // Alice creates and publishes a recipe, then Bob loads the feed.
    private func alicePublishes(_ title: String = "Shared Soup") async throws -> Recipe {
        let recipe = makeRecipe(title)
        alice.add(recipe)
        try await alice.publish(recipe)
        await bob.refreshCommunity()
        return recipe
    }

    private func bobsCopy(of recipe: Recipe) -> Recipe? {
        bob.communityRecipes.first { $0.id == recipe.id }
    }

    // XCTAssertThrowsError doesn't support async code, so this does the same job.
    private func assertThrows(_ expected: CommunityError,
                              file: StaticString = #filePath, line: UInt = #line,
                              _ body: () async throws -> Void) async {
        do {
            try await body()
            XCTFail("Expected \(expected) to be thrown", file: file, line: line)
        } catch let error as CommunityError {
            XCTAssertEqual(error, expected, file: file, line: line)
        } catch {
            XCTFail("Unexpected error: \(error)", file: file, line: line)
        }
    }

    // MARK: - Ideal conditions

    // A published recipe shows up for another user, credited to its author.
    func testPublishedRecipeIsVisibleToOtherUsers() async throws {
        let recipe = try await alicePublishes()
        let shared = try XCTUnwrap(bobsCopy(of: recipe))
        XCTAssertEqual(shared.title, "Shared Soup")
        XCTAssertEqual(shared.authorID, alice.authorID)
        XCTAssertNotEqual(alice.authorID, bob.authorID)
        XCTAssertTrue(alice.isPublished(recipe))
        XCTAssertNotNil(alice.recipes.first { $0.id == recipe.id }?.publishedAt)
    }

    // Only the author gets edit/delete rights.
    func testOnlyAuthorCanModifyPublishedRecipe() async throws {
        let recipe = try await alicePublishes()
        XCTAssertTrue(alice.canModify(recipe))
        XCTAssertFalse(bob.canModify(try XCTUnwrap(bobsCopy(of: recipe))))
    }

    // The author's edits reach everyone; the original publish date is kept.
    func testAuthorEditsArePublishedToOtherUsers() async throws {
        let recipe = try await alicePublishes()
        let originalDate = try XCTUnwrap(bobsCopy(of: recipe)?.publishedAt)
        var edited = try XCTUnwrap(alice.recipes.first { $0.id == recipe.id })
        edited.title = "Even Better Soup"
        try await alice.saveEdits(edited)
        await bob.refreshCommunity()
        XCTAssertEqual(bobsCopy(of: recipe)?.title, "Even Better Soup")
        XCTAssertEqual(bobsCopy(of: recipe)?.publishedAt, originalDate)
        XCTAssertEqual(alice.recipes.first { $0.id == recipe.id }?.title, "Even Better Soup")
    }

    // Deleting a published recipe removes it from the device and from the feed.
    func testAuthorDeleteRemovesRecipeEverywhere() async throws {
        let recipe = try await alicePublishes()
        try await alice.deleteEverywhere(recipe)
        XCTAssertFalse(alice.recipes.contains { $0.id == recipe.id })
        await bob.refreshCommunity()
        XCTAssertNil(bobsCopy(of: recipe))
    }

    // Unpublishing hides it from others but keeps it in My Recipes.
    func testUnpublishKeepsLocalCopy() async throws {
        let recipe = try await alicePublishes()
        try await alice.unpublish(recipe)
        XCTAssertTrue(alice.recipes.contains { $0.id == recipe.id })
        XCTAssertFalse(alice.isPublished(recipe))
        await bob.refreshCommunity()
        XCTAssertNil(bobsCopy(of: recipe))
    }

    // Saving someone else's recipe makes a private copy owned by the person saving it.
    func testSavingCommunityRecipeCreatesPrivateOwnedCopy() async throws {
        let recipe = try await alicePublishes()
        bob.repost(try XCTUnwrap(bobsCopy(of: recipe)))
        let copy = try XCTUnwrap(bob.recipes.first)
        XCTAssertNotEqual(copy.id, recipe.id)
        XCTAssertEqual(copy.authorID, bob.authorID)
        XCTAssertNil(copy.publishedAt)
        XCTAssertTrue(bob.canModify(copy))
        XCTAssertTrue(copy.description.contains("Originally shared by Alice"))
    }

    // Renaming yourself or relaunching the app doesn't change who owns your recipes.
    func testOwnershipSurvivesProfileRenameAndRelaunch() async throws {
        let recipe = try await alicePublishes()
        alice.updateProfile(name: "Renamed Chef", bio: "", dietaryPreferences: [])
        XCTAssertTrue(alice.canModify(recipe))
        let relaunched = RecipeStore(defaults: aliceDefaults, community: community)
        XCTAssertEqual(relaunched.authorID, alice.authorID)
        XCTAssertTrue(relaunched.canModify(recipe))
        XCTAssertTrue(relaunched.isPublished(recipe))
    }

    // MARK: - Non-ideal conditions

    // Another user can't save edits to someone else's published recipe.
    func testOtherUserCannotEditPublishedRecipe() async throws {
        let recipe = try await alicePublishes()
        var hacked = try XCTUnwrap(bobsCopy(of: recipe))
        hacked.title = "Hacked"
        await assertThrows(.notOwner) { try await self.bob.saveEdits(hacked) }
        await alice.refreshCommunity()
        XCTAssertEqual(alice.communityRecipes.first { $0.id == recipe.id }?.title, "Shared Soup")
    }

    // Another user can't unpublish or delete someone else's recipe.
    func testOtherUserCannotDeletePublishedRecipe() async throws {
        let recipe = try await alicePublishes()
        let shared = try XCTUnwrap(bobsCopy(of: recipe))
        await assertThrows(.notOwner) { try await self.bob.unpublish(shared) }
        await assertThrows(.notOwner) { try await self.bob.deleteEverywhere(shared) }
        await bob.refreshCommunity()
        XCTAssertNotNil(bobsCopy(of: recipe))
    }

    // The service itself rejects someone using the author's (public) ID without their secret,
    // so ownership doesn't depend on the app hiding buttons.
    func testServiceRejectsForgedAuthorIdentity() async throws {
        let recipe = try await alicePublishes()
        var shared = try XCTUnwrap(bobsCopy(of: recipe))
        shared.title = "Hacked"
        let forged = AuthorIdentity(id: alice.authorID, token: "not-alices-secret-token")
        await assertThrows(.notOwner) { _ = try await self.community.update(shared, as: forged) }
        await assertThrows(.notOwner) { try await self.community.delete(recipeID: recipe.id, as: forged) }
        await assertThrows(.notOwner) { _ = try await self.community.update(shared, as: self.bob.identity) }
        await bob.refreshCommunity()
        XCTAssertEqual(bobsCopy(of: recipe)?.title, "Shared Soup")
    }

    // Your likes and personal star rating are not shared with other users.
    func testPublishingStripsPersonalData() async throws {
        let recipe = makeRecipe()
        alice.add(recipe)
        alice.react(to: recipe, like: true)
        alice.rate(recipe, stars: 4)
        try await alice.publish(recipe)
        await bob.refreshCommunity()
        let shared = try XCTUnwrap(bobsCopy(of: recipe))
        XCTAssertEqual(shared.likes, 0)
        XCTAssertNil(shared.userRating)
        XCTAssertNil(shared.userReaction)
        // Alice's own copy keeps them.
        XCTAssertEqual(alice.recipes.first { $0.id == recipe.id }?.likes, 1)
        XCTAssertEqual(alice.recipes.first { $0.id == recipe.id }?.userRating, 4)
    }

    // Built-in samples aren't yours, so they can't be published.
    func testSampleRecipesCannotBePublished() async {
        let sample = alice.recipes.first { !$0.isUserCreated }!
        await assertThrows(.notOwner) { try await self.alice.publish(sample) }
    }

    // Publishing the same recipe twice is rejected.
    func testCannotPublishTwice() async throws {
        let recipe = try await alicePublishes()
        await assertThrows(.alreadyPublished) { try await self.alice.publish(recipe) }
    }

    // Recipes saved before this feature existed belong to the install that created them.
    func testLegacyRecipesBecomeOwnedByThisInstall() throws {
        let legacyDefaults = makeDefaults()
        let legacy = makeRecipe("Old Favorite")   // authorID is nil, like data saved by older versions
        legacyDefaults.set(try JSONEncoder().encode([legacy]), forKey: RecipeStore.recipesKey)
        let store = RecipeStore(defaults: legacyDefaults, community: community)
        XCTAssertEqual(store.recipes.first?.authorID, store.authorID)
        XCTAssertTrue(store.canModify(legacy))
    }

    // If a published recipe disappears from the feed, its "Published" badge clears on refresh.
    func testPublishedBadgeClearsWhenRecipeLeavesFeed() async throws {
        let recipe = try await alicePublishes()
        try await community.delete(recipeID: recipe.id, as: alice.identity)
        await alice.refreshCommunity()
        XCTAssertFalse(alice.isPublished(recipe))
    }

    // The on-device demo feed comes with read-only recipes from other authors.
    func testSeededCommunityRecipesAreReadOnly() async {
        let store = RecipeStore(defaults: makeDefaults())
        await store.refreshCommunity()
        XCTAssertEqual(store.communityRecipes.count, SampleRecipes.community.count)
        XCTAssertTrue(store.communityRecipes.allSatisfy { !store.canModify($0) })
    }

    // Bad server addresses are rejected and leave the current setting unchanged.
    func testInvalidServerAddressIsRejected() {
        XCTAssertNotNil(RecipeValidator.communityServerURL("http://127.0.0.1:8080"))
        XCTAssertNil(RecipeValidator.communityServerURL(""))
        XCTAssertNil(RecipeValidator.communityServerURL("ftp://example.com"))
        XCTAssertNil(RecipeValidator.communityServerURL("localhost:8080"))
        XCTAssertFalse(alice.setCommunityServer("not a url"))
        XCTAssertTrue(alice.isUsingLocalCommunity)
    }
}
