import SwiftUI

struct RecipeFeedView: View {
    @EnvironmentObject private var store: RecipeStore
    let favoritesOnly: Bool
    @State private var query = ""
    @State private var selectedCategory = "All"
    @State private var selectedDiet = "All Diets"
    @State private var sort = "Featured"

    private let categories = ["All", "Breakfast", "Lunch", "Dinner", "Vegetarian", "Quick & Easy"]
    private let dietaryOptions = ["All Diets", "Vegetarian", "Vegan", "Gluten-Free", "High Protein", "Quick & Easy"]
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    private var filtered: [Recipe] {
        var results = store.recipes.filter { recipe in
            let matchesFavorite = !favoritesOnly || store.isFavorite(recipe)
            let matchesCategory = selectedCategory == "All" || recipe.category == selectedCategory || recipe.tags.contains(selectedCategory)
            let matchesDiet = selectedDiet == "All Diets" || recipe.tags.contains(selectedDiet)
            let words = query.lowercased().split(separator: " ").map(String.init)
            let searchable = ([recipe.title, recipe.description, recipe.category, recipe.cuisine] + recipe.tags + recipe.ingredients.map(\.item)).joined(separator: " ").lowercased()
            return matchesFavorite && matchesCategory && matchesDiet && words.allSatisfy(searchable.contains)
        }
        if sort == "Highest Rated" { results.sort { $0.rating > $1.rating } }
        if sort == "Quickest" { results.sort { $0.totalMinutes < $1.totalMinutes } }
        return results
    }

    var body: some View {
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
                        }
                    }.padding(.horizontal)
                }

                // Count and Sorting selector
                HStack {
                    Text("\(filtered.count) recipes").foregroundStyle(.secondary).font(.subheadline)
                    Spacer()
                    Picker("Sort", selection: $sort) {
                        Text("Featured").tag("Featured")
                        Text("Highest Rated").tag("Highest Rated")
                        Text("Quickest").tag("Quickest")
                    }.pickerStyle(.menu)
                }.padding(.horizontal)

                // Recipe Cards Grid
                LazyVGrid(columns: columns, spacing: 15) {
                    ForEach(filtered) { recipe in
                        NavigationLink {
                            RecipeDetailView(recipeID: recipe.id)
                        } label: {
                            RecipeCardView(recipe: recipe)
                        }
                        .buttonStyle(.plain)
                    }
                }.padding(.horizontal)

                // Empty Search / Filter State
                if filtered.isEmpty {
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
        .searchable(text: $query, prompt: "Search names, tags or ingredients")
    }
}

private struct RecipeCardView: View {
    @EnvironmentObject private var store: RecipeStore
    let recipe: Recipe
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .topTrailing) {
                RecipeImageView(url: recipe.imageURL).frame(height: 135).clipped()
                Button {
                    store.toggleFavorite(recipe)
                } label: {
                    Image(systemName: store.isFavorite(recipe) ? "heart.fill" : "heart")
                        .foregroundStyle(store.isFavorite(recipe) ? Color.red : Color.primary)
                        .padding(9).background(.regularMaterial, in: Circle())
                }
                .buttonStyle(.plain)
                .padding(7)
            }
            Text(recipe.title)
                .font(.subheadline.bold())
                .lineLimit(2)
                .frame(height: 37, alignment: .topLeading)
            
            HStack(spacing: 4) {
                Text("\(recipe.category) • \(recipe.totalMinutes) min")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if let firstTag = recipe.tags.first {
                    Text(firstTag)
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.15), in: Capsule())
                        .foregroundStyle(.orange)
                }
            }
            
            Label(String(format: "%.1f", recipe.rating), systemImage: "star.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.orange)
        }
        .padding(.bottom, 9)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 13))
        .clipShape(RoundedRectangle(cornerRadius: 13))
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
