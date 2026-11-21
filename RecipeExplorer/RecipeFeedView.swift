import SwiftUI

struct RecipeFeedView: View {
    @EnvironmentObject private var store: RecipeStore
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let favoritesOnly: Bool
    @State private var query = ""
    @State private var selectedCategory = "All"
    @State private var selectedDiet = "All Diets"
    @State private var sort = "Featured"

    private let categories = ["All", "Breakfast", "Lunch", "Dinner", "Vegetarian", "Quick & Easy"]
    private let dietaryOptions = ["All Diets", "Vegetarian", "Vegan", "Gluten-Free", "High Protein", "Quick & Easy"]
    private var columns: [GridItem] {
        [GridItem(dynamicTypeSize.isAccessibilitySize ? .flexible() : .adaptive(minimum: 155), spacing: 12)]
    }

    private var filtered: [Recipe] {
        let words = query.lowercased().split(whereSeparator: \.isWhitespace).map(String.init)
        var results = store.recipes.filter { recipe in
            let matchesFavorite = !favoritesOnly || store.isFavorite(recipe)
            let matchesCategory = selectedCategory == "All" || recipe.category == selectedCategory || recipe.tags.contains(selectedCategory)
            let matchesDiet = selectedDiet == "All Diets" || recipe.tags.contains(selectedDiet)
            let searchable = ([recipe.title, recipe.description, recipe.category, recipe.cuisine] + recipe.tags + recipe.ingredients.map(\.item)).joined(separator: " ").lowercased()
            return matchesFavorite && matchesCategory && matchesDiet && words.allSatisfy(searchable.contains)
        }
        if sort == "Highest Rated" { results.sort { $0.rating > $1.rating } }
        if sort == "Quickest" { results.sort { $0.totalMinutes < $1.totalMinutes } }
        return results
    }

    var body: some View {
        let results = filtered
        let filterLayout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 6))
            : AnyLayout(HStackLayout(spacing: 8))
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if !favoritesOnly {
                    Text("What are we cooking today?")
                        .font(.title2.bold())
                        .padding(.horizontal)
                }

                // Category chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(categories, id: \.self) { category in
                            Button(category) { selectedCategory = category }
                                .font(.subheadline.weight(.medium))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(selectedCategory == category ? Color.orange : Color(.secondarySystemBackground), in: Capsule())
                                .foregroundStyle(selectedCategory == category ? Color.white : Color.primary)
                                .accessibilityAddTraits(selectedCategory == category ? .isSelected : [])
                        }
                    }.padding(.horizontal)
                }

                // Dietary tag filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 7) {
                        ForEach(dietaryOptions, id: \.self) { diet in
                            Button {
                                selectedDiet = diet
                            } label: {
                                HStack(spacing: 4) {
                                    if diet != "All Diets" {
                                        Image(systemName: "leaf.fill")
                                            .font(.caption2)
                                    }
                                    Text(diet)
                                        .font(.caption.weight(.medium))
                                }
                                .padding(.horizontal, 11)
                                .padding(.vertical, 6)
                                .background(selectedDiet == diet ? Color.green.opacity(0.2) : Color(.tertiarySystemBackground), in: Capsule())
                                .overlay(Capsule().stroke(selectedDiet == diet ? Color.green : Color.clear, lineWidth: 1.2))
                                .foregroundStyle(selectedDiet == diet ? Color.green : Color.secondary)
                            }
                            .accessibilityAddTraits(selectedDiet == diet ? .isSelected : [])
                        }
                    }.padding(.horizontal)
                }

                // Count and Sorting selector
                filterLayout {
                    Text("\(results.count) recipes")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Picker("Sort", selection: $sort) {
                        Text("Featured").tag("Featured")
                        Text("Highest Rated").tag("Highest Rated")
                        Text("Quickest").tag("Quickest")
                    }
                    .pickerStyle(.menu)
                }.padding(.horizontal)

                // Recipe Cards Grid
                LazyVGrid(columns: columns, spacing: 15) {
                    ForEach(results) { recipe in
                        RecipeCardView(recipe: recipe)
                    }
                }.padding(.horizontal)

                // Empty Search / Filter State
                if results.isEmpty {
                    VStack(spacing: 12) {
                        ContentUnavailableView("No matching recipes", systemImage: "magnifyingglass", description: Text("Try another search query or clear your dietary filter."))
                        if selectedCategory != "All" || selectedDiet != "All Diets" || !query.isEmpty {
                            Button("Reset Filters") {
                                selectedCategory = "All"
                                selectedDiet = "All Diets"
                                query = ""
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.orange)
                        }
                    }
                    .padding(.top, 20)
                }
            }
            .padding(.top, 10)
            .padding(.bottom, 80)
        }
        .navigationTitle(favoritesOnly ? "Favorites" : "Recipe Explorer")
        .navigationBarTitleDisplayMode(dynamicTypeSize.isAccessibilitySize ? .inline : .automatic)
        .searchable(text: $query, prompt: "Search names, tags or ingredients")
    }
}

private struct RecipeCardView: View {
    @EnvironmentObject private var store: RecipeStore
    let recipe: Recipe
    var body: some View {
        let isFavorite = store.isFavorite(recipe)
        NavigationLink {
            RecipeDetailView(recipeID: recipe.id)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                RecipeImageView(url: recipe.imageURL)
                    .frame(height: 135)
                    .clipped()
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 6) {
                    Text(recipe.title)
                        .font(.subheadline.bold())
                        .fixedSize(horizontal: false, vertical: true)

                    Text("\(recipe.category) • \(recipe.totalMinutes) min")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let firstTag = recipe.tags.first {
                        Text(firstTag)
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.15), in: Capsule())
                            .foregroundStyle(.orange)
                    }

                    Label(String(format: "%.1f", recipe.rating), systemImage: "star.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.orange)
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 9)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 13))
            .clipShape(RoundedRectangle(cornerRadius: 13))
        }
        .buttonStyle(.plain)
        .overlay(alignment: .topTrailing) {
            Button {
                store.toggleFavorite(recipe)
            } label: {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .foregroundStyle(isFavorite ? Color.red : Color.primary)
                    .padding(8)
                    .frame(minWidth: 44, minHeight: 44)
                    .background(.regularMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isFavorite ? "Remove from favorites" : "Add to favorites")
            .accessibilityHint(recipe.title)
            .padding(7)
        }
    }
}

struct RecipeImageView: View {
    let url: String
    var body: some View {
        AsyncImage(url: URL(string: url)) { phase in
            switch phase {
            case .success(let image): image.resizable().scaledToFill()
            case .failure: placeholder
            case .empty: placeholder
            @unknown default: placeholder
            }
        }.frame(maxWidth: .infinity).clipped()
    }
    private var placeholder: some View {
        Rectangle().fill(Color.orange.opacity(0.12)).overlay(Image(systemName: "fork.knife").font(.largeTitle).foregroundStyle(.orange))
    }
}
