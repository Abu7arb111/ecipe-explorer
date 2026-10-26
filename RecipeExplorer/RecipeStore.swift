import Foundation
import Combine

@MainActor final class RecipeStore: ObservableObject {
    @Published private(set) var recipes: [Recipe] = []
    @Published private(set) var favorites: Set<UUID> = []
    private let recipesKey = "recipeExplorer.recipes.v1"
    private let favoritesKey = "recipeExplorer.favorites.v1"

    init() {
        if let data = UserDefaults.standard.data(forKey: recipesKey),
           let saved = try? JSONDecoder().decode([Recipe].self, from: data) {
            recipes = saved
        } else { recipes = SampleRecipes.all }
        if let data = UserDefaults.standard.data(forKey: favoritesKey),
           let saved = try? JSONDecoder().decode(Set<UUID>.self, from: data) { favorites = saved }
    }

    func isFavorite(_ recipe: Recipe) -> Bool { favorites.contains(recipe.id) }
    func toggleFavorite(_ recipe: Recipe) {
        if !favorites.insert(recipe.id).inserted { favorites.remove(recipe.id) }
        save()
    }
    func add(_ recipe: Recipe) { recipes.insert(recipe, at: 0); save() }
    func update(_ recipe: Recipe) {
        guard let index = recipes.firstIndex(where: { $0.id == recipe.id }) else { return }
        recipes[index] = recipe; save()
    }
    func delete(_ recipe: Recipe) {
        guard recipe.isUserCreated else { return }
        recipes.removeAll { $0.id == recipe.id }
        favorites.remove(recipe.id)
        save()
    }
    // A reaction can be selected, changed, or removed without inflating counts.
    func react(to recipe: Recipe, like: Bool) {
        guard var updated = recipes.first(where: { $0.id == recipe.id }) else { return }
        let requested = like ? "like" : "dislike"
        if updated.userReaction == "like" { updated.likes = max(0, updated.likes - 1) }
        if updated.userReaction == "dislike" { updated.dislikes = max(0, updated.dislikes - 1) }
        updated.userReaction = updated.userReaction == requested ? nil : requested
        if updated.userReaction == "like" { updated.likes += 1 }
        if updated.userReaction == "dislike" { updated.dislikes += 1 }
        update(updated)
    }
    // A local repost is a new user-created recipe with clear attribution.
    // The original recipe remains unchanged and can still be found in Explore.
    func repost(_ recipe: Recipe) {
        guard recipes.contains(where: { $0.id == recipe.id }) else { return }
        var copy = recipe
        copy.id = UUID()
        copy.title = "Repost: " + recipe.title
        copy.description = "Originally shared by \(recipe.author). \(recipe.description)"
        copy.author = "You"
        copy.isUserCreated = true
        copy.ingredients = recipe.ingredients.map { Ingredient(item: $0.item, amount: $0.amount) }
        copy.likes = 0
        copy.dislikes = 0
        copy.userReaction = nil
        copy.userRating = nil
        add(copy)
    }
    func rate(_ recipe: Recipe, stars: Int) {
        guard var updated = recipes.first(where: { $0.id == recipe.id }) else { return }
        updated.userRating = stars
        update(updated)
    }
    private func save() {
        if let data = try? JSONEncoder().encode(recipes) { UserDefaults.standard.set(data, forKey: recipesKey) }
        if let data = try? JSONEncoder().encode(favorites) { UserDefaults.standard.set(data, forKey: favoritesKey) }
    }
}
