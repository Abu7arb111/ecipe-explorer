import SwiftUI

/// The screen for creating a new recipe or editing an existing one.
struct RecipeFormView: View {
    @EnvironmentObject private var store: RecipeStore
    @Environment(\.dismiss) private var dismiss
    // nil means we're creating a new recipe; otherwise we're editing this one.
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

    // Error message for the image URL field, or nil if it's fine.
    private var imageURLError: String? {
        RecipeValidator.isValidImageURL(imageURL) ? nil : "Enter a full web address starting with http:// or https://, or leave it blank."
    }
    // Error message listing which ingredient lines are in the wrong format, or nil if fine.
    private var ingredientError: String? {
        let bad = RecipeValidator.malformedIngredientLines(ingredientsText)
        guard !bad.isEmpty else { return nil }
        let list = bad.map(String.init).joined(separator: ", ")
        return "Line \(list): use the format amount | ingredient (example: 2 cups | Flour)."
    }
    // The Save button is only enabled when the required fields are filled in
    // and there are no validation errors.
    private var valid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !ingredientsText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !instructionsText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        imageURLError == nil && ingredientError == nil
    }

    var body: some View {
        Form {
            Section {
                TextField("Recipe title", text: $title)
                TextField("Description", text: $summary, axis: .vertical).lineLimit(2...4)
                Picker("Category", selection: $category) { ForEach(categories, id: \.self) { Text($0) } }
                TextField("Cuisine", text: $cuisine)
                TextField("Image URL (optional)", text: $imageURL)
                    .keyboardType(.URL).textInputAutocapitalization(.never).autocorrectionDisabled()
            } header: { Text("Recipe information") } footer: {
                // Red error text appears under the section when the URL is invalid.
                if let imageURLError { Text(imageURLError).foregroundStyle(.red) }
            }
            // Steppers only allow numbers in a safe range, so users can't type bad values here.
            Section("Cooking details") {
                Stepper("Prep: \(prep) minutes", value: $prep, in: 0...240, step: 5)
                Stepper("Cook: \(cook) minutes", value: $cook, in: 0...600, step: 5)
                Stepper("Servings: \(servings)", value: $servings, in: 1...30)
            }
            Section {
                TextEditor(text: $ingredientsText).frame(minHeight: 110)
            } header: { Text("Ingredients, one per line") } footer: {
                // Show the error if there is one, otherwise show the example format.
                if let ingredientError { Text(ingredientError).foregroundStyle(.red) }
                else { Text("Example: 2 cups | Flour") }
            }
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

    // When editing, fill the form with the recipe's current values.
    private func populate() {
        guard let existing else { return }
        title = existing.title; summary = existing.description; category = existing.category
        cuisine = existing.cuisine; imageURL = existing.imageURL
        prep = existing.prepTime; cook = existing.cookTime; servings = existing.servings
        ingredientsText = existing.ingredients.map { "\($0.amount) | \($0.item)" }.joined(separator: "\n")
        instructionsText = existing.instructions.joined(separator: "\n")
    }

    // Builds a Recipe from the form and adds it (new) or updates it (editing).
    private func save() {
        // Safety check in case Save is triggered while the form is invalid.
        guard valid else { return }
        let ingredients = RecipeValidator.parseIngredients(ingredientsText)
        let instructions = RecipeValidator.parseInstructions(instructionsText)
        guard !ingredients.isEmpty && !instructions.isEmpty else { return }
        let newRecipe = Recipe(
            id: existing?.id ?? UUID(),
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            description: summary, category: category,
            cuisine: cuisine.isEmpty ? "Homemade" : cuisine,
            prepTime: prep, cookTime: cook, servings: servings,
            difficulty: existing?.difficulty ?? "Easy", rating: existing?.rating ?? 0,
            author: existing?.author ?? "You",
            imageURL: imageURL.trimmingCharacters(in: .whitespacesAndNewlines),
            tags: existing?.tags ?? [], ingredients: ingredients, instructions: instructions,
            isUserCreated: true, likes: existing?.likes ?? 0, dislikes: existing?.dislikes ?? 0,
            userRating: existing?.userRating, userReaction: existing?.userReaction)
        if existing == nil { store.add(newRecipe) } else { store.update(newRecipe) }
        dismiss()
    }
}
