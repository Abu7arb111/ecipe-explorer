import XCTest
@testable import RecipeExplorer

/// Tests for RecipeStore: adding, deleting, favorites, saving, error cases,
/// grocery list management, checklist persistence, and user profiles.
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
               author: "Tester", imageURL: "", tags: ["Vegetarian", "Quick & Easy"],
               ingredients: [Ingredient(item: "Salt", amount: "1 tsp"), Ingredient(item: "Pepper", amount: "1/2 tsp")],
               instructions: ["Mix.", "Cook."], isUserCreated: true)
    }

    // MARK: - Ideal conditions (everything works normally)

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

    // Reposting makes a new copy that is credited to the user with a "Repost:" title.
    func testRepostCreatesAttributedCopy() {
        let original = store.recipes[0]
        store.repost(original)
        let copy = store.recipes[0]
        XCTAssertNotEqual(copy.id, original.id)
        XCTAssertTrue(copy.title.hasPrefix("Repost: "))
        XCTAssertEqual(copy.author, store.userProfile.name)
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

    // Adding ingredients to grocery list creates attributed items.
    func testAddIngredientsToGroceryList() {
        let r = makeRecipe("Pancake Breakfast")
        store.addIngredientsToGrocery(r.ingredients, from: r)
        XCTAssertEqual(store.groceryList.count, 2)
        XCTAssertEqual(store.groceryList.first?.recipeTitle, "Pancake Breakfast")
        XCTAssertFalse(store.groceryList.first?.isPurchased ?? true)
    }

    // Toggling grocery item purchased state flips isPurchased.
    func testToggleGroceryItemPurchased() {
        store.addCustomGroceryItem(item: "Apples", amount: "3")
        guard let item = store.groceryList.first else { return XCTFail("Missing item") }
        store.toggleGroceryItemPurchased(item)
        XCTAssertTrue(store.groceryList.first?.isPurchased ?? false)
        guard let updated = store.groceryList.first else { return XCTFail("Missing item") }
        store.toggleGroceryItemPurchased(updated)
        XCTAssertFalse(store.groceryList.first?.isPurchased ?? true)
    }

    // Clearing purchased grocery items keeps unpurchased items.
    func testClearPurchasedGroceryItems() {
        store.addCustomGroceryItem(item: "Milk", amount: "1 gallon")
        store.addCustomGroceryItem(item: "Bread", amount: "1 loaf")
        guard let first = store.groceryList.first else { return XCTFail("Missing item") }
        store.toggleGroceryItemPurchased(first)
        store.clearPurchasedGroceryItems()
        XCTAssertEqual(store.groceryList.count, 1)
        XCTAssertEqual(store.groceryList.first?.item, "Bread")
    }

    // Grocery list persists across app relaunches.
    func testGroceryListPersistsAcrossLaunches() {
        store.addCustomGroceryItem(item: "Olive Oil", amount: "500ml")
        let relaunched = RecipeStore(defaults: defaults)
        XCTAssertEqual(relaunched.groceryList.count, 1)
        XCTAssertEqual(relaunched.groceryList.first?.item, "Olive Oil")
    }

    // Ingredient checklist states persist per recipe across sessions.
    func testIngredientChecklistPersistence() {
        let r = makeRecipe("Pasta Carbonara")
        store.add(r)
        let ingID = r.ingredients[0].id
        XCTAssertFalse(store.isIngredientChecked(recipeID: r.id, ingredientID: ingID))
        store.toggleIngredientChecked(recipeID: r.id, ingredientID: ingID)
        XCTAssertTrue(store.isIngredientChecked(recipeID: r.id, ingredientID: ingID))
        
        // Simulates app relaunch
        let relaunched = RecipeStore(defaults: defaults)
        XCTAssertTrue(relaunched.isIngredientChecked(recipeID: r.id, ingredientID: ingID))
        
        // Clear checklist
        store.clearCheckedIngredients(recipeID: r.id)
        XCTAssertFalse(store.isIngredientChecked(recipeID: r.id, ingredientID: ingID))
    }

    // User profile updates persist across relaunches.
    func testUserProfilePersistsAcrossLaunches() {
        store.updateProfile(name: "Executive Chef", bio: "Cooking delicious food", dietaryPreferences: ["Vegan", "Gluten-Free"])
        let relaunched = RecipeStore(defaults: defaults)
        XCTAssertEqual(relaunched.userProfile.name, "Executive Chef")
        XCTAssertEqual(relaunched.userProfile.bio, "Cooking delicious food")
        XCTAssertEqual(relaunched.userProfile.dietaryPreferences, ["Vegan", "Gluten-Free"])
    }

    // MARK: - Non-ideal conditions (bad input or broken data)

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

    // Reject adding empty or whitespace custom grocery items.
    func testBlankCustomGroceryItemIsRejected() {
        let addedEmpty = store.addCustomGroceryItem(item: "", amount: "1")
        let addedWhitespace = store.addCustomGroceryItem(item: "   ", amount: "1")
        XCTAssertFalse(addedEmpty)
        XCTAssertFalse(addedWhitespace)
        XCTAssertEqual(store.groceryList.count, 0)
    }

    // Whitespace profile name defaults cleanly to Chef Ahmad.
    func testBlankProfileNameDefaultsCleanly() {
        store.updateProfile(name: "   ", bio: "Bio", dietaryPreferences: [])
        XCTAssertEqual(store.userProfile.name, "Chef Ahmad")
    }

    // If saved recipe data is garbage, the app falls back to samples and reports an error.
    func testCorruptedSavedRecipesFallBackToSamplesAndReportError() {
        defaults.set(Data("not json".utf8), forKey: RecipeStore.recipesKey)
        let broken = RecipeStore(defaults: defaults)
        XCTAssertEqual(broken.recipes.count, SampleRecipes.all.count)
        XCTAssertNotNil(broken.storageError)
    }

    // If saved grocery data is corrupted, resets cleanly and reports error.
    func testCorruptedSavedGroceryFallsBackAndReportsError() {
        defaults.set(Data("invalid grocery binary".utf8), forKey: RecipeStore.groceryKey)
        let broken = RecipeStore(defaults: defaults)
        XCTAssertEqual(broken.groceryList.count, 0)
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
