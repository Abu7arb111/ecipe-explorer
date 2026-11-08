import Foundation

struct Ingredient: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    var item: String
    var amount: String
}

struct GroceryItem: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var item: String
    var amount: String
    var recipeTitle: String? = nil
    var isPurchased: Bool = false
}

struct UserProfile: Codable, Hashable {
    var name: String = "Chef Ahmad"
    var bio: String = "Passionate home cook exploring new culinary horizons."
    var dietaryPreferences: [String] = []
}

struct Recipe: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var description: String
    var category: String
    var cuisine: String
    var prepTime: Int
    var cookTime: Int
    var servings: Int
    var difficulty: String
    var rating: Double
    var author: String
    var imageURL: String
    var tags: [String]
    var ingredients: [Ingredient]
    var instructions: [String]
    var isUserCreated: Bool = false
    var likes: Int = 0
    var dislikes: Int = 0
    var userRating: Int? = nil
    // Optional for compatibility with recipes saved before reactions were tracked.
    var userReaction: String? = nil
    // Explicit initializer keeps recipe creation simple in the views and sample data.
    init(id: UUID = UUID(), title: String, description: String, category: String,
         cuisine: String, prepTime: Int, cookTime: Int, servings: Int,
         difficulty: String, rating: Double, author: String, imageURL: String,
         tags: [String], ingredients: [Ingredient], instructions: [String],
         isUserCreated: Bool = false, likes: Int = 0, dislikes: Int = 0,
         userRating: Int? = nil, userReaction: String? = nil) {
        self.id = id; self.title = title; self.description = description
        self.category = category; self.cuisine = cuisine
        self.prepTime = prepTime; self.cookTime = cookTime; self.servings = servings
        self.difficulty = difficulty; self.rating = rating; self.author = author
        self.imageURL = imageURL; self.tags = tags; self.ingredients = ingredients
        self.instructions = instructions; self.isUserCreated = isUserCreated
        self.likes = likes; self.dislikes = dislikes
        self.userRating = userRating; self.userReaction = userReaction
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, description, category, cuisine, prepTime, cookTime
        case servings, difficulty, rating, author, imageURL, tags, ingredients
        case instructions, isUserCreated, likes, dislikes, userRating, userReaction
    }

    // Older locally saved recipes may not have newer reaction fields.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        description = try c.decode(String.self, forKey: .description)
        category = try c.decode(String.self, forKey: .category)
        cuisine = try c.decode(String.self, forKey: .cuisine)
        prepTime = try c.decode(Int.self, forKey: .prepTime)
        cookTime = try c.decode(Int.self, forKey: .cookTime)
        servings = try c.decode(Int.self, forKey: .servings)
        difficulty = try c.decode(String.self, forKey: .difficulty)
        rating = try c.decode(Double.self, forKey: .rating)
        author = try c.decode(String.self, forKey: .author)
        imageURL = try c.decode(String.self, forKey: .imageURL)
        tags = try c.decode([String].self, forKey: .tags)
        ingredients = try c.decode([Ingredient].self, forKey: .ingredients)
        instructions = try c.decode([String].self, forKey: .instructions)
        isUserCreated = try c.decodeIfPresent(Bool.self, forKey: .isUserCreated) ?? false
        likes = try c.decodeIfPresent(Int.self, forKey: .likes) ?? 0
        dislikes = try c.decodeIfPresent(Int.self, forKey: .dislikes) ?? 0
        userRating = try c.decodeIfPresent(Int.self, forKey: .userRating)
        userReaction = try c.decodeIfPresent(String.self, forKey: .userReaction)
    }
    var totalMinutes: Int { prepTime + cookTime }
}
