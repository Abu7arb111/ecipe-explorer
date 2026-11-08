import Foundation
import Combine

/// Holds all recipes, favorites, grocery items, user profile, and session states,
/// saving them defensively to the phone's storage (UserDefaults).
@MainActor final class RecipeStore: ObservableObject {
    // Keys used to save and load data. Public so the tests can use them too.
    static let recipesKey = "recipeExplorer.recipes.v1"
    static let favoritesKey = "recipeExplorer.favorites.v1"
    static let groceryKey = "recipeExplorer.grocery.v1"
    static let profileKey = "recipeExplorer.profile.v1"
    static let checkedIngredientsKey = "recipeExplorer.checkedIngredients.v1"

    @Published private(set) var recipes: [Recipe] = []
    @Published private(set) var favorites: Set<UUID> = []
    @Published private(set) var groceryList: [GroceryItem] = []
    @Published private(set) var userProfile: UserProfile = UserProfile()
    @Published private(set) var checkedIngredients: [UUID: Set<UUID>] = [:]
    
    // If this is set, ContentView shows an alert with the message.
    @Published var storageError: String? = nil

    private let defaults: UserDefaults

    // The default is the real app storage. Tests pass in a temporary one instead.
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        // Load saved recipes. If the saved data is corrupted, fall back to the
        // sample recipes and tell the user instead of failing silently.
        if let data = defaults.data(forKey: Self.recipesKey) {
            do {
                recipes = try JSONDecoder().decode([Recipe].self, from: data)
            } catch {
                recipes = SampleRecipes.all
                storageError = "Your saved recipes couldn't be read, so the sample recipes were loaded instead."
            }
        } else {
            // First launch: nothing saved yet, so start with the samples.
            recipes = SampleRecipes.all
        }

        // Load saved favorites. If corrupted, reset them and tell the user
        // (unless we already have an error message from the recipes above).
        if let data = defaults.data(forKey: Self.favoritesKey) {
            do {
                favorites = try JSONDecoder().decode(Set<UUID>.self, from: data)
            } catch {
                favorites = []
                if storageError == nil {
                    storageError = "Your saved favorites couldn't be read and were reset."
                }
            }
        }

        // Load saved grocery list.
        if let data = defaults.data(forKey: Self.groceryKey) {
            do {
                groceryList = try JSONDecoder().decode([GroceryItem].self, from: data)
            } catch {
                groceryList = []
                if storageError == nil {
                    storageError = "Your saved grocery list couldn't be read and was reset."
                }
            }
        }

        // Load user profile.
        if let data = defaults.data(forKey: Self.profileKey) {
            do {
                userProfile = try JSONDecoder().decode(UserProfile.self, from: data)
            } catch {
                userProfile = UserProfile()
            }
        }

        // Load checked ingredients state per recipe.
        if let data = defaults.data(forKey: Self.checkedIngredientsKey) {
            do {
                checkedIngredients = try JSONDecoder().decode([UUID: Set<UUID>].self, from: data)
            } catch {
                checkedIngredients = [:]
            }
        }
    }

    // MARK: - Favorites Management

    func isFavorite(_ recipe: Recipe) -> Bool { favorites.contains(recipe.id) }

    // Adds the recipe to favorites, or removes it if it's already there.
    func toggleFavorite(_ recipe: Recipe) {
        if !favorites.insert(recipe.id).inserted { favorites.remove(recipe.id) }
        save()
    }

    // MARK: - Recipe CRUD

    // New recipes go to the top of the list.
    func add(_ recipe: Recipe) { recipes.insert(recipe, at: 0); save() }

    // Replaces an existing recipe (matched by id). Does nothing if it isn't found.
    func update(_ recipe: Recipe) {
        guard let index = recipes.firstIndex(where: { $0.id == recipe.id }) else { return }
        recipes[index] = recipe; save()
    }

    // Only recipes the user created can be deleted, not the built-in samples.
    func delete(_ recipe: Recipe) {
        guard recipe.isUserCreated else { return }
        recipes.removeAll { $0.id == recipe.id }
        favorites.remove(recipe.id)
        checkedIngredients.removeValue(forKey: recipe.id)
        save()
    }

    // Like/dislike toggles: tapping the same button again removes the reaction,
    // and switching from like to dislike moves the count over.
    func react(to recipe: Recipe, like: Bool) {
        guard var updated = recipes.first(where: { $0.id == recipe.id }) else { return }
        let requested = like ? "like" : "dislike"
        // First undo the previous reaction (if any)...
        if updated.userReaction == "like" { updated.likes = max(0, updated.likes - 1) }
        if updated.userReaction == "dislike" { updated.dislikes = max(0, updated.dislikes - 1) }
        // ...then either clear it (same button tapped twice) or set the new one.
        updated.userReaction = updated.userReaction == requested ? nil : requested
        if updated.userReaction == "like" { updated.likes += 1 }
        if updated.userReaction == "dislike" { updated.dislikes += 1 }
        update(updated)
    }

    // Makes a copy of a recipe in My Recipes, credited to the original author.
    // The original stays unchanged.
    func repost(_ recipe: Recipe) {
        guard recipes.contains(where: { $0.id == recipe.id }) else { return }
        var copy = recipe
        copy.id = UUID()
        copy.title = "Repost: " + recipe.title
        copy.description = "Originally shared by \(recipe.author). \(recipe.description)"
        copy.author = userProfile.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "You" : userProfile.name
        copy.isUserCreated = true
        copy.ingredients = recipe.ingredients.map { Ingredient(item: $0.item, amount: $0.amount) }
        // The copy starts fresh: no likes, dislikes, or personal rating.
        copy.likes = 0
        copy.dislikes = 0
        copy.userReaction = nil
        copy.userRating = nil
        add(copy)
    }

    // Saves the user's star rating, always kept between 1 and 5.
    func rate(_ recipe: Recipe, stars: Int) {
        guard var updated = recipes.first(where: { $0.id == recipe.id }) else { return }
        updated.userRating = min(5, max(1, stars))
        update(updated)
    }

    // MARK: - Smart Grocery List Operations

    // Appends ingredients from a recipe to the shopping list.
    func addIngredientsToGrocery(_ ingredients: [Ingredient], from recipe: Recipe?) {
        let newItems = ingredients.map { ing in
            GroceryItem(item: ing.item, amount: ing.amount, recipeTitle: recipe?.title, isPurchased: false)
        }
        groceryList.append(contentsOf: newItems)
        save()
    }

    // Adds a custom item typed in by the user. Returns false if invalid/empty.
    @discardableResult
    func addCustomGroceryItem(item: String, amount: String) -> Bool {
        let trimmedItem = item.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedItem.isEmpty else { return false }
        let trimmedAmount = amount.trimmingCharacters(in: .whitespacesAndNewlines)
        let newItem = GroceryItem(item: trimmedItem, amount: trimmedAmount.isEmpty ? "1" : trimmedAmount, recipeTitle: "Custom Item", isPurchased: false)
        groceryList.append(newItem)
        save()
        return true
    }

    // Toggles the purchased state of a grocery item.
    func toggleGroceryItemPurchased(_ item: GroceryItem) {
        guard let index = groceryList.firstIndex(where: { $0.id == item.id }) else { return }
        groceryList[index].isPurchased.toggle()
        save()
    }

    // Deletes an individual grocery item.
    func deleteGroceryItem(_ item: GroceryItem) {
        groceryList.removeAll { $0.id == item.id }
        save()
    }

    // Clears all completed/purchased items.
    func clearPurchasedGroceryItems() {
        groceryList.removeAll { $0.isPurchased }
        save()
    }

    // Clears the entire grocery list.
    func clearAllGroceryItems() {
        groceryList.removeAll()
        save()
    }

    // MARK: - Ingredient Checklist State (Detail View Persistence)

    func isIngredientChecked(recipeID: UUID, ingredientID: UUID) -> Bool {
        checkedIngredients[recipeID]?.contains(ingredientID) ?? false
    }

    func toggleIngredientChecked(recipeID: UUID, ingredientID: UUID) {
        var current = checkedIngredients[recipeID] ?? []
        if !current.insert(ingredientID).inserted {
            current.remove(ingredientID)
        }
        checkedIngredients[recipeID] = current
        save()
    }

    func clearCheckedIngredients(recipeID: UUID) {
        checkedIngredients.removeValue(forKey: recipeID)
        save()
    }

    // MARK: - User Profile Management

    func updateProfile(name: String, bio: String, dietaryPreferences: [String]) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        userProfile = UserProfile(
            name: trimmedName.isEmpty ? "Chef Ahmad" : trimmedName,
            bio: bio.trimmingCharacters(in: .whitespacesAndNewlines),
            dietaryPreferences: dietaryPreferences
        )
        save()
    }

    // MARK: - Persistence Engine

    // Writes recipes, favorites, grocery list, user profile, and checklists to storage.
    // If encoding fails, show an alert instead of silently losing the user's changes.
    private func save() {
        do {
            defaults.set(try JSONEncoder().encode(recipes), forKey: Self.recipesKey)
            defaults.set(try JSONEncoder().encode(favorites), forKey: Self.favoritesKey)
            defaults.set(try JSONEncoder().encode(groceryList), forKey: Self.groceryKey)
            defaults.set(try JSONEncoder().encode(userProfile), forKey: Self.profileKey)
            defaults.set(try JSONEncoder().encode(checkedIngredients), forKey: Self.checkedIngredientsKey)
        } catch {
            storageError = "Your changes couldn't be saved. They may be lost when the app closes."
        }
    }
}
