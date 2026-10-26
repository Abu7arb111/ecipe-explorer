import SwiftUI

struct RecipeFormView: View {
    @EnvironmentObject private var store: RecipeStore
    @Environment(\.dismiss) private var dismiss
    let existing: Recipe?
    @State private var title = ""
    @State private var summary = ""
    @State private var category = "Dinner"
    @State private var cuisine = ""
    @State private var imageURL = ""
    @State private var ingredientsText = ""
    @State private var instructionsText = ""
    @State private var prep = 10
    @State private var cook = 20
    @State private var servings = 2
    private let categories = ["Breakfast", "Lunch", "Dinner", "Vegetarian", "Quick & Easy"]
    private var valid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !ingredientsText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !instructionsText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    var body: some View {
        Form {
            Section("Recipe information") {
                TextField("Recipe title", text: $title)
                TextField("Description", text: $summary, axis: .vertical).lineLimit(2...4)
                Picker("Category", selection: $category) { ForEach(categories, id: \.self) { Text($0) } }
                TextField("Cuisine", text: $cuisine)
                TextField("Image URL (optional)", text: $imageURL).keyboardType(.URL).textInputAutocapitalization(.never)
            }
            Section("Cooking details") {
                Stepper("Prep: \(prep) minutes", value: $prep, in: 0...240, step: 5)
                Stepper("Cook: \(cook) minutes", value: $cook, in: 0...600, step: 5)
                Stepper("Servings: \(servings)", value: $servings, in: 1...30)
            }
            Section {
                TextEditor(text: $ingredientsText).frame(minHeight: 110)
            } header: { Text("Ingredients, one per line") } footer: { Text("Example: 2 cups | Flour") }
            Section {
                TextEditor(text: $instructionsText).frame(minHeight: 140)
            } header: { Text("Instructions, one step per line") }
        }
        .navigationTitle(existing == nil ? "New Recipe" : "Edit Recipe")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }.disabled(!valid)
            }
        }
        .onAppear(perform: populate)
    }
    private func populate() {
        guard let existing else { return }
        title = existing.title; summary = existing.description; category = existing.category
        cuisine = existing.cuisine; imageURL = existing.imageURL
        prep = existing.prepTime; cook = existing.cookTime; servings = existing.servings
        ingredientsText = existing.ingredients.map { "\($0.amount) | \($0.item)" }.joined(separator: "\n")
        instructionsText = existing.instructions.joined(separator: "\n")
    }
    private func save() {
        let ingredients = ingredientsText.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.map { line -> Ingredient in
            let parts = line.split(separator: "|", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
            return parts.count == 2 ? Ingredient(item: parts[1], amount: parts[0]) : Ingredient(item: parts[0], amount: "")
        }
        let instructions = instructionsText.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        guard !ingredients.isEmpty && !instructions.isEmpty else { return }
        let newRecipe = Recipe(id: existing?.id ?? UUID(), title: title.trimmingCharacters(in: .whitespacesAndNewlines), description: summary, category: category, cuisine: cuisine.isEmpty ? "Homemade" : cuisine, prepTime: prep, cookTime: cook, servings: servings, difficulty: existing?.difficulty ?? "Easy", rating: existing?.rating ?? 0, author: existing?.author ?? "You", imageURL: imageURL, tags: existing?.tags ?? [], ingredients: ingredients, instructions: instructions, isUserCreated: true, likes: existing?.likes ?? 0, dislikes: existing?.dislikes ?? 0, userRating: existing?.userRating, userReaction: existing?.userReaction)
        if existing == nil { store.add(newRecipe) } else { store.update(newRecipe) }
        dismiss()
    }
}
