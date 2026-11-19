import Foundation

/// Errors that can happen while sharing recipes with other users.
enum CommunityError: LocalizedError, Equatable {
    case notOwner
    case notFound
    case alreadyPublished
    case invalidRecipe(String)
    case invalidServerURL
    case unreachable(String)
    case server(status: Int, message: String?)
    case badResponse

    var errorDescription: String? {
        switch self {
        case .notOwner:
            return "Only the recipe's author can edit or delete it."
        case .notFound:
            return "That recipe is no longer on the community feed."
        case .alreadyPublished:
            return "This recipe is already published."
        case .invalidRecipe(let reason):
            return "The recipe couldn't be shared: \(reason)"
        case .invalidServerURL:
            return "Enter a server address starting with http:// or https://."
        case .unreachable(let detail):
            return "Couldn't reach the community server. \(detail)"
        case .server(let status, let message):
            return message ?? "The community server returned an error (\(status))."
        case .badResponse:
            return "The community server sent a response the app couldn't read."
        }
    }
}

/// The shared "backend" that holds published recipes. Every implementation must
/// enforce ownership itself: only the author (matching ID *and* secret token) may
/// update or delete a published recipe. The app also hides those controls, but the
/// UI is not what keeps other users out.
protocol CommunityService: Sendable {
    func fetchRecipes() async throws -> [Recipe]
    func publish(_ recipe: Recipe, as author: AuthorIdentity) async throws -> Recipe
    func update(_ recipe: Recipe, as author: AuthorIdentity) async throws -> Recipe
    func delete(recipeID: UUID, as author: AuthorIdentity) async throws
}

/// Rules a recipe must meet before it can be shared (the server checks the same ones).
enum CommunityRules {
    static func validate(_ recipe: Recipe) throws {
        if recipe.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw CommunityError.invalidRecipe("it needs a title.")
        }
        if recipe.ingredients.isEmpty {
            throw CommunityError.invalidRecipe("add at least one ingredient.")
        }
        if recipe.instructions.isEmpty {
            throw CommunityError.invalidRecipe("add at least one instruction step.")
        }
        if !RecipeValidator.isValidImageURL(recipe.imageURL) {
            throw CommunityError.invalidRecipe("the image URL isn't valid.")
        }
    }
}

extension Recipe {
    /// The copy of a recipe that other users see: personal data (your reactions and
    /// your own star rating) is removed and ownership is stamped on.
    func publicVersion(authorID: UUID) -> Recipe {
        var copy = self
        copy.authorID = authorID
        copy.isUserCreated = true
        copy.likes = 0
        copy.dislikes = 0
        copy.userRating = nil
        copy.userReaction = nil
        return copy
    }
}

// MARK: - On-device community (offline demo + unit tests)

/// A community feed stored on this device. It behaves like the real server
/// (same ownership rules) so the feature works with no network, and so tests can
/// simulate several users sharing one backend.
actor LocalCommunityService: CommunityService {
    static let storageKey = "recipeExplorer.localCommunity.v1"

    private struct Snapshot: Codable {
        var recipes: [Recipe]
        // authorID.uuidString -> secret token, registered the first time an author publishes.
        var tokens: [String: String]
    }

    private let defaults: UserDefaults?
    private var snapshot: Snapshot

    /// Pass `defaults: nil` for a purely in-memory feed (used by the tests).
    init(defaults: UserDefaults? = nil, seed: [Recipe] = SampleRecipes.community) {
        self.defaults = defaults
        if let data = defaults?.data(forKey: Self.storageKey),
           let saved = try? JSONDecoder().decode(Snapshot.self, from: data) {
            snapshot = saved
        } else {
            // Seed authors get random secrets nobody knows, so their recipes stay read-only.
            var tokens: [String: String] = [:]
            for recipe in seed {
                if let id = recipe.authorID { tokens[id.uuidString] = AuthorIdentity.generate().token }
            }
            let seeded = Snapshot(recipes: seed, tokens: tokens)
            snapshot = seeded
            Self.write(seeded, to: defaults)
        }
    }

    func fetchRecipes() async throws -> [Recipe] {
        snapshot.recipes.sorted { ($0.publishedAt ?? .distantPast) > ($1.publishedAt ?? .distantPast) }
    }

    func publish(_ recipe: Recipe, as author: AuthorIdentity) async throws -> Recipe {
        // You can only publish under your own ID.
        if let claimed = recipe.authorID, claimed != author.id { throw CommunityError.notOwner }
        try verify(author)
        guard !snapshot.recipes.contains(where: { $0.id == recipe.id }) else {
            throw CommunityError.alreadyPublished
        }
        try CommunityRules.validate(recipe)
        var published = recipe.publicVersion(authorID: author.id)
        published.publishedAt = Date()
        snapshot.recipes.insert(published, at: 0)
        Self.write(snapshot, to: defaults)
        return published
    }

    func update(_ recipe: Recipe, as author: AuthorIdentity) async throws -> Recipe {
        guard let index = snapshot.recipes.firstIndex(where: { $0.id == recipe.id }) else {
            throw CommunityError.notFound
        }
        let existing = snapshot.recipes[index]
        guard existing.authorID == author.id else { throw CommunityError.notOwner }
        try verify(author)
        try CommunityRules.validate(recipe)
        var updated = recipe.publicVersion(authorID: author.id)
        updated.publishedAt = existing.publishedAt   // the original publish date never changes
        snapshot.recipes[index] = updated
        Self.write(snapshot, to: defaults)
        return updated
    }

    func delete(recipeID: UUID, as author: AuthorIdentity) async throws {
        guard let existing = snapshot.recipes.first(where: { $0.id == recipeID }) else {
            throw CommunityError.notFound
        }
        guard existing.authorID == author.id else { throw CommunityError.notOwner }
        try verify(author)
        snapshot.recipes.removeAll { $0.id == recipeID }
        Self.write(snapshot, to: defaults)
    }

    // The first request from an author registers their secret ("trust on first use").
    // After that, every request claiming that author ID must carry the same secret.
    private func verify(_ author: AuthorIdentity) throws {
        let key = author.id.uuidString
        if let known = snapshot.tokens[key] {
            guard known == author.token else { throw CommunityError.notOwner }
        } else {
            snapshot.tokens[key] = author.token
        }
    }

    private static func write(_ snapshot: Snapshot, to defaults: UserDefaults?) {
        guard let defaults, let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: storageKey)
    }
}

// MARK: - Remote community server (real multi-user sharing)

/// Talks to the community server in `community-server/server.py` (or any server
/// implementing the same REST contract):
///
///   GET    /recipes          -> [Recipe]
///   POST   /recipes          -> 201 Recipe     (author headers required)
///   PUT    /recipes/{id}     -> 200 Recipe     (author only, else 403)
///   DELETE /recipes/{id}     -> 204            (author only, else 403)
///
/// Author headers: `X-Author-ID` (public UUID) and `X-Author-Token` (private secret).
/// Dates are ISO 8601.
final class RemoteCommunityService: CommunityService {
    let baseURL: URL
    private let session: URLSession

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func fetchRecipes() async throws -> [Recipe] {
        let data = try await send("GET", path: ["recipes"])
        return try decode([Recipe].self, from: data)
    }

    func publish(_ recipe: Recipe, as author: AuthorIdentity) async throws -> Recipe {
        let data = try await send("POST", path: ["recipes"],
                                  body: recipe.publicVersion(authorID: author.id), author: author)
        return try decode(Recipe.self, from: data)
    }

    func update(_ recipe: Recipe, as author: AuthorIdentity) async throws -> Recipe {
        let data = try await send("PUT", path: ["recipes", recipe.id.uuidString],
                                  body: recipe.publicVersion(authorID: author.id), author: author)
        return try decode(Recipe.self, from: data)
    }

    func delete(recipeID: UUID, as author: AuthorIdentity) async throws {
        _ = try await send("DELETE", path: ["recipes", recipeID.uuidString], author: author)
    }

    // MARK: Networking helpers

    private func send(_ method: String, path: [String], body: Recipe? = nil,
                      author: AuthorIdentity? = nil) async throws -> Data {
        var url = baseURL
        for component in path { url.appendPathComponent(component) }

        var request = URLRequest(url: url, timeoutInterval: 15)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let author {
            request.setValue(author.id.uuidString, forHTTPHeaderField: "X-Author-ID")
            request.setValue(author.token, forHTTPHeaderField: "X-Author-Token")
        }
        if let body {
            request.httpBody = try Self.makeEncoder().encode(body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let result: (Data, URLResponse)
        do {
            result = try await session.data(for: request)
        } catch let error as URLError {
            throw CommunityError.unreachable(error.localizedDescription)
        }
        let (data, response) = result
        guard let http = response as? HTTPURLResponse else { throw CommunityError.badResponse }

        switch http.statusCode {
        case 200..<300: return data
        case 403: throw CommunityError.notOwner
        case 404: throw CommunityError.notFound
        case 409: throw CommunityError.alreadyPublished
        case 400, 422: throw CommunityError.invalidRecipe(Self.serverMessage(in: data) ?? "the server rejected it.")
        default: throw CommunityError.server(status: http.statusCode, message: Self.serverMessage(in: data))
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do { return try Self.makeDecoder().decode(type, from: data) }
        catch { throw CommunityError.badResponse }
    }

    // Server errors look like {"error": "message"}.
    private static func serverMessage(in data: Data) -> String? {
        struct ErrorBody: Decodable { let error: String }
        return (try? JSONDecoder().decode(ErrorBody.self, from: data))?.error
    }

    private static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
