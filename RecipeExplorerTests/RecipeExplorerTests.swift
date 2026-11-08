import XCTest
@testable import RecipeExplorer

/// Tests for RecipeStore: adding, deleting, favorites, saving, and error cases.
@MainActor
final class RecipeStoreTests: XCTestCase {
    private var suiteName = ""
    private var defaults: UserDefaults!
    private var store: RecipeStore!

    // Runs before every test: creates a fresh, temporary storage so tests
    // never touch the real app data or each other.
    override func setUp() async throws {
        suiteName = "RecipeExplorerTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        store = RecipeStore(defaults: defaults)
    }

    // Runs after every test: deletes the temporary storage.
    override func tearDown() async throws {
        defaults.removePersistentDomain(forName: suiteName)
    }

    // Helper that builds a simple user-created recipe for the tests.
    private func makeRecipe(_ title: String = "Test Recipe") -> Recipe {
        Recipe(title: title, description: "desc", category: "Dinner", cuisine: "Test",
               prepTime: 5, cookTime: 10, servings: 2, difficulty: "Easy", rating: 0,
               author: "Tester", imageURL: "", tags: [],
               ingredients: [Ingredient(item: "Salt", amount: "1 tsp")],
               instructions: ["Mix."], isUserCreated: true)
    }

    // MARK: Ideal conditions (everything works normally)

    // A brand-new install should show the built-in sample recipes with no error.
    func testFirstLaunchLoadsSampleRecipes() {
        XCTAssertEqual(store.recipes.count, SampleRecipes.all.count)
        XCTAssertNil(store.storageError)
    }

    // A newly added recipe appears at the top of the list.
    func testAddInsertsRecipeAtFront() {
        let r = makeRecipe("Brand New")
        store.add(r)
        XCTAssertEqual(store.recipes.first?.id, r.id)
    }

    // Tapping the heart twice should favorite then un-favorite.
    func testToggleFavoriteOnAndOff() {
        let r = store.recipes[0]
        store.toggleFavorite(r)
        XCTAssertTrue(store.isFavorite(r))
        store.toggleFavorite(r)
        XCTAssertFalse(store.isFavorite(r))
    }

    // Simulates closing and reopening the app: a second store using the same
    // storage should see the recipe and favorite saved by the first.
    func testDataPersistsAcrossLaunches() {
        let r = makeRecipe("Persist Me")
        store.add(r)
        store.toggleFavorite(r)
        let relaunched = RecipeStore(defaults: defaults)
        XCTAssertTrue(relaunched.recipes.contains { $0.id == r.id })
        XCTAssertTrue(relaunched.isFavorite(r))
    }

    // Deleting a user-created recipe removes it.
    func testDeleteRemovesUserRecipe() {
        let r = makeRecipe()
        store.add(r)
        store.delete(r)
        XCTAssertFalse(store.recipes.contains { $0.id == r.id })
    }

    // Reposting makes a new copy that is credited to "You" with a "Repost:" title.
    func testRepostCreatesAttributedCopy() {
        let original = store.recipes[0]
        store.repost(original)
        let copy = store.recipes[0]
        XCTAssertNotEqual(copy.id, original.id)
        XCTAssertTrue(copy.title.hasPrefix("Repost: "))
        XCTAssertEqual(copy.author, "You")
    }

    // Liking twice should add one like, then remove it (not add two).
    func testLikeTogglesInsteadOfInflating() {
        let r = makeRecipe()
        store.add(r)
        store.react(to: r, like: true)
        XCTAssertEqual(store.recipes.first { $0.id == r.id }?.likes, 1)
        store.react(to: r, like: true)
        XCTAssertEqual(store.recipes.first { $0.id == r.id }?.likes, 0)
    }

    // MARK: Non-ideal conditions (bad input or broken data)

    // The built-in sample recipes must not be deletable.
    func testSampleRecipesCannotBeDeleted() {
        let sample = store.recipes.first { !$0.isUserCreated }!
        let before = store.recipes.count
        store.delete(sample)
        XCTAssertEqual(store.recipes.count, before)
    }

    // Out-of-range ratings get pulled back to the 1-5 range.
    func testRatingIsClampedToOneThroughFive() {
        let r = makeRecipe()
        store.add(r)
        store.rate(r, stars: 99)
        XCTAssertEqual(store.recipes.first { $0.id == r.id }?.userRating, 5)
        store.rate(r, stars: -3)
        XCTAssertEqual(store.recipes.first { $0.id == r.id }?.userRating, 1)
    }

    // If saved data is garbage, the app should fall back to the samples
    // and report an error instead of crashing or silently ignoring it.
    func testCorruptedSavedRecipesFallBackToSamplesAndReportError() {
        defaults.set(Data("not json".utf8), forKey: RecipeStore.recipesKey)
        let broken = RecipeStore(defaults: defaults)
        XCTAssertEqual(broken.recipes.count, SampleRecipes.all.count)
        XCTAssertNotNil(broken.storageError)
    }
}

/// Tests for the form validation helpers.
final class RecipeValidatorTests: XCTestCase {
    // The image URL is optional, so blank is allowed.
    func testEmptyImageURLIsAllowed() {
        XCTAssertTrue(RecipeValidator.isValidImageURL(""))
    }

    // A normal web address is accepted.
    func testValidImageURL() {
        XCTAssertTrue(RecipeValidator.isValidImageURL("https://example.com/a.jpg"))
    }

    // Plain text, the wrong kind of link, and a link with no website are rejected.
    func testInvalidImageURLs() {
        XCTAssertFalse(RecipeValidator.isValidImageURL("not a url"))
        XCTAssertFalse(RecipeValidator.isValidImageURL("ftp://example.com/a.jpg"))
        XCTAssertFalse(RecipeValidator.isValidImageURL("http://"))
    }

    // Lines 2, 3, and 4 are wrong (no "|", missing amount, missing item),
    // so those line numbers should be reported.
    func testMalformedIngredientLinesAreReported() {
        let text = "2 cups | Flour\nJust salt\n | Sugar\n1 cup |"
        XCTAssertEqual(RecipeValidator.malformedIngredientLines(text), [2, 3, 4])
    }

    // Properly formatted ingredient lines produce no errors.
    func testWellFormedIngredientsHaveNoBadLines() {
        XCTAssertTrue(RecipeValidator.malformedIngredientLines("2 cups | Flour\n1 tsp | Salt").isEmpty)
    }
}
