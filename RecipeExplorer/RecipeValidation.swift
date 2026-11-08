import Foundation

/// Small helper functions that check and parse what the user types into the recipe form.
enum RecipeValidator {
    // The image URL is optional, so empty is fine. Otherwise it must start with
    // http:// or https:// and include a website name.
    static func isValidImageURL(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return true }
        guard let url = URL(string: trimmed),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              let host = url.host, !host.isEmpty
        else { return false }
        return true
    }

    // Returns the line numbers of ingredient lines that aren't in the form
    // "amount | item" (for example "2 cups | Flour"). Blank lines are ignored.
    static func malformedIngredientLines(_ text: String) -> [Int] {
        var bad: [Int] = []
        for (index, line) in text.components(separatedBy: .newlines).enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }
            // Split on the first "|" and check both sides have text.
            let parts = trimmed.split(separator: "|", maxSplits: 1, omittingEmptySubsequences: false)
                .map { $0.trimmingCharacters(in: .whitespaces) }
            if parts.count != 2 || parts[0].isEmpty || parts[1].isEmpty { bad.append(index + 1) }
        }
        return bad
    }

    // Turns the ingredients text box into Ingredient objects, one per non-blank line.
    static func parseIngredients(_ text: String) -> [Ingredient] {
        text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .map { line in
                let parts = line.split(separator: "|", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
                return parts.count == 2 ? Ingredient(item: parts[1], amount: parts[0]) : Ingredient(item: parts[0], amount: "")
            }
    }

    // Turns the instructions text box into a list of steps, skipping blank lines.
    static func parseInstructions(_ text: String) -> [String] {
        text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
}
