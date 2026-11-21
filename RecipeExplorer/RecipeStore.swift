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
    static let identityKey = "recipeExplorer.authorIdentity.v1"
    static let communityServerKey = "recipeExplorer.communityServer.v1"

    @Published private(set) var recipes: [Recipe] = []
    @Published private(set) var favorites: Set<UUID> = []
    @Published private(set) var groceryList: [GroceryItem] = []
    @Published private(set) var userProfile: UserProfile = UserProfile()
    @Published private(set) var checkedIngredients: [UUID: Set<UUID>] = [:]

    // Community feed: recipes published by every user (including you).
    @Published private(set) var communityRecipes: [Recipe] = []
    @Published private(set) var isLoadingCommunity = false
    @Published private(set) var communityLoadError: String? = nil
    // Empty means the on-device demo feed; otherwise the server address.
    @Published private(set) var communityServerURL: String = ""

    // If this is set, ContentView shows an alert with the message.
    @Published var storageError: String? = nil

    private let defaults: UserDefaults
    // This install's publishing identity. It's kept separate from the editable
    // profile so renaming yourself never changes who owns your recipes.
    let identity: AuthorIdentity
    var authorID: UUID { identity.id }
    private var community: any CommunityService
    // Bumped when the server changes so late responses from the old one are ignored.
    private var communityGeneration = 0

    // The default is the real app storage. Tests pass in a temporary one instead,
    // and can pass a shared community service to simulate several users.
    init(defaults: UserDefaults = .standard, community: (any CommunityService)? = nil) {
        self.defaults = defaults
        self.identity = Self.loadOrCreateIdentity(in: defaults)
        let savedServer = defaults.string(forKey: Self.communityServerKey) ?? ""
        self.community = community ?? Self.makeCommunityService(server: savedServer, defaults: defaults)
        self.communityServerURL = community == nil ? savedServer : ""

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

        // Recipes created before publishing existed have no owner yet; they were
        // made on this device, so they belong to this install's identity.
        var migrated = false
        for index in recipes.indices where recipes[index].isUserCreated && recipes[index].authorID == nil {
            recipes[index].authorID = identity.id
            migrated = true
        }
        if migrated { save() }
    }

    private static func loadOrCreateIdentity(in defaults: UserDefaults) -> AuthorIdentity {
        if let data = defaults.data(forKey: identityKey),
           let saved = try? JSONDecoder().decode(AuthorIdentity.self, from: data) {
            return saved
        }
        let fresh = AuthorIdentity.generate()
        if let data = try? JSONEncoder().encode(fresh) { defaults.set(data, forKey: identityKey) }
        return fresh
    }

    private static func makeCommunityService(server: String, defaults: UserDefaults) -> any CommunityService {
        if let url = RecipeValidator.communityServerURL(server) {
            return RemoteCommunityService(baseURL: url)
        }
        return LocalCommunityService(defaults: defaults)
    }

    // MARK: - Favorites Management

    func isFavorite(_ recipe: Recipe) -> Bool { favorites.contains(recipe.id) }

    // Adds the recipe to favorites, or removes it if it's already there.
    func toggleFavorite(_ recipe: Recipe) {
        if !favorites.insert(recipe.id).inserted { favorites.remove(recipe.id) }
        save()
    }

    // MARK: - Recipe CRUD

    // New recipes go to the top of the list. Recipes you create are owned by you.
    func add(_ recipe: Recipe) {
        var recipe = recipe
        if recipe.isUserCreated && recipe.authorID == nil { recipe.authorID = identity.id }
        recipes.insert(recipe, at: 0)
        save()
    }

    // Replaces an existing recipe (matched by id). Does nothing if it isn't found.
    func update(_ recipe: Recipe) {
        guard let index = recipes.firstIndex(where: { $0.id == recipe.id }) else { return }
        recipes[index] = recipe; save()
    }

    // Only recipes you own can be deleted, not the built-in samples. Checks the
    // stored copy, so a caller can't get around this by passing an edited value.
    // (Published recipes should go through deleteEverywhere so the feed is updated too.)
    func delete(_ recipe: Recipe) {
        guard let stored = recipes.first(where: { $0.id == recipe.id }), canModify(stored) else { return }
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

    // Makes a copy of a recipe (yours, a sample, or one from the community feed) in
    // My Recipes, credited to the original author. The original stays unchanged.
    func repost(_ recipe: Recipe) {
        guard let source = recipes.first(where: { $0.id == recipe.id })
                ?? communityRecipes.first(where: { $0.id == recipe.id }) else { return }
        var copy = source
        copy.id = UUID()
        copy.title = "Repost: " + source.title
        copy.description = "Originally shared by \(source.author). \(source.description)"
        copy.author = userProfile.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "You" : userProfile.name
        copy.isUserCreated = true
        copy.ingredients = source.ingredients.map { Ingredient(item: $0.item, amount: $0.amount) }
        // The copy starts fresh: no likes, dislikes, or personal rating.
        copy.likes = 0
        copy.dislikes = 0
        copy.userReaction = nil
        copy.userRating = nil
        // The copy is yours and starts private, even if the original was published.
        copy.authorID = identity.id
        copy.publishedAt = nil
        add(copy)
    }

    // Saves the user's star rating, always kept between 1 and 5.
    func rate(_ recipe: Recipe, stars: Int) {
        guard var updated = recipes.first(where: { $0.id == recipe.id }) else { return }
        updated.userRating = min(5, max(1, stars))
        update(updated)
    }

    // MARK: - Community Publishing & Ownership

    /// True when you are the author of this recipe and may edit or delete it.
    /// Local copies are checked first; anything else must be on the community feed
    /// with your author ID. (The community service enforces the same rule.)
    func canModify(_ recipe: Recipe) -> Bool {
        if let local = recipes.first(where: { $0.id == recipe.id }) {
            return local.isUserCreated && local.authorID == identity.id
        }
        if let shared = communityRecipes.first(where: { $0.id == recipe.id }) {
            return shared.authorID == identity.id
        }
        return false
    }

    /// True when the recipe is currently shared on the community feed.
    func isPublished(_ recipe: Recipe) -> Bool {
        if let local = recipes.first(where: { $0.id == recipe.id }) { return local.isPublished }
        return communityRecipes.contains { $0.id == recipe.id }
    }

    /// Looks a recipe up in My Recipes first, then on the community feed.
    func recipe(withID id: UUID) -> Recipe? {
        recipes.first { $0.id == id } ?? communityRecipes.first { $0.id == id }
    }

    var isUsingLocalCommunity: Bool { communityServerURL.isEmpty }

    var publishedCount: Int { recipes.filter { $0.isUserCreated && $0.isPublished }.count }

    /// Reloads the community feed from the current service.
    func refreshCommunity() async {
        let generation = communityGeneration
        let service = community
        isLoadingCommunity = true
        defer { if generation == communityGeneration { isLoadingCommunity = false } }
        do {
            let fetched = try await service.fetchRecipes()
            guard generation == communityGeneration else { return }   // server changed meanwhile
            communityRecipes = fetched
            communityLoadError = nil
            reconcilePublishedState(with: fetched)
        } catch {
            guard generation == communityGeneration else { return }
            communityLoadError = error.localizedDescription
        }
    }

    /// Shares one of your recipes so other users can browse it.
    func publish(_ recipe: Recipe) async throws {
        guard let local = recipes.first(where: { $0.id == recipe.id }) else { throw CommunityError.notFound }
        guard canModify(local) else { throw CommunityError.notOwner }
        guard !local.isPublished else { throw CommunityError.alreadyPublished }
        try CommunityRules.validate(local)

        let published = try await community.publish(local.publicVersion(authorID: identity.id), as: identity)
        upsertCommunity(published)
        if let index = recipes.firstIndex(where: { $0.id == local.id }) {
            recipes[index].authorID = identity.id
            recipes[index].publishedAt = published.publishedAt ?? Date()
            save()
        }
    }

    /// Saves edits from the recipe form. Only the author may do this. If the recipe
    /// is published, the community copy is updated first; if that fails, nothing
    /// is changed and the error is thrown so the form can show it.
    func saveEdits(_ recipe: Recipe) async throws {
        let local = recipes.first { $0.id == recipe.id }
        guard local != nil || communityRecipes.contains(where: { $0.id == recipe.id }) else {
            throw CommunityError.notFound
        }
        guard canModify(recipe) else { throw CommunityError.notOwner }

        var edited = recipe
        edited.authorID = identity.id
        // A recipe that exists only on the feed (not in My Recipes) is published by definition.
        let shared = local?.isPublished ?? true
        if shared {
            try CommunityRules.validate(edited)
            do {
                let pushed = try await community.update(edited.publicVersion(authorID: identity.id), as: identity)
                upsertCommunity(pushed)
                edited.publishedAt = pushed.publishedAt ?? edited.publishedAt
            } catch CommunityError.notFound where local != nil {
                // It disappeared from the feed (e.g. the server was reset). Keep the
                // edit on this device and show the recipe as unpublished again.
                communityRecipes.removeAll { $0.id == recipe.id }
                edited.publishedAt = nil
            }
        }
        if let checked = checkedIngredients[edited.id] {
            let retained = checked.intersection(edited.ingredients.map(\.id))
            if retained != checked {
                checkedIngredients[edited.id] = retained.isEmpty ? nil : retained
                if local == nil { save() }
            }
        }
        if local != nil { update(edited) }
    }

    /// Removes your recipe from the community feed but keeps it in My Recipes.
    func unpublish(_ recipe: Recipe) async throws {
        guard isPublished(recipe) else { return }
        guard canModify(recipe) else { throw CommunityError.notOwner }
        do {
            try await community.delete(recipeID: recipe.id, as: identity)
        } catch CommunityError.notFound {
            // Already gone from the feed; just update local state below.
        }
        communityRecipes.removeAll { $0.id == recipe.id }
        if let index = recipes.firstIndex(where: { $0.id == recipe.id }) {
            recipes[index].publishedAt = nil
            save()
        }
    }

    /// Deletes your recipe from this device and, if published, from the community feed.
    /// If the feed can't be updated, nothing is deleted.
    func deleteEverywhere(_ recipe: Recipe) async throws {
        guard canModify(recipe) else { throw CommunityError.notOwner }
        if isPublished(recipe) { try await unpublish(recipe) }
        delete(recipe)
    }

    /// Switches where recipes are shared. Empty text = the on-device demo feed.
    /// Returns false (and changes nothing) if the address isn't a valid http(s) URL.
    @discardableResult
    func setCommunityServer(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            community = LocalCommunityService(defaults: defaults)
        } else {
            guard let url = RecipeValidator.communityServerURL(trimmed) else { return false }
            community = RemoteCommunityService(baseURL: url)
        }
        communityServerURL = trimmed
        defaults.set(trimmed, forKey: Self.communityServerKey)
        communityGeneration += 1
        communityRecipes = []
        communityLoadError = nil
        isLoadingCommunity = false
        return true
    }

    private func upsertCommunity(_ recipe: Recipe) {
        if let index = communityRecipes.firstIndex(where: { $0.id == recipe.id }) {
            communityRecipes[index] = recipe
        } else {
            communityRecipes.insert(recipe, at: 0)
        }
    }

    // Keeps the "Published" badges in My Recipes in sync with what the feed actually holds.
    private func reconcilePublishedState(with feed: [Recipe]) {
        var mine: [UUID: Recipe] = [:]
        for recipe in feed where recipe.authorID == identity.id { mine[recipe.id] = recipe }
        var changed = false
        for index in recipes.indices where recipes[index].isUserCreated && recipes[index].authorID == identity.id {
            if let shared = mine[recipes[index].id] {
                if recipes[index].publishedAt == nil {
                    recipes[index].publishedAt = shared.publishedAt ?? Date()
                    changed = true
                }
            } else if recipes[index].publishedAt != nil {
                recipes[index].publishedAt = nil
                changed = true
            }
        }
        if changed { save() }
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
