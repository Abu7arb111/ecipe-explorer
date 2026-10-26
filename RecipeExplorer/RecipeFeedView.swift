import SwiftUI

struct RecipeFeedView: View {
    @EnvironmentObject private var store: RecipeStore
    let favoritesOnly: Bool
    @State private var query = ""
    @State private var selectedCategory = "All"
    @State private var sort = "Featured"
    private let categories = ["All", "Breakfast", "Lunch", "Dinner", "Vegetarian", "Quick & Easy"]
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    private var filtered: [Recipe] {
        var results = store.recipes.filter { recipe in
            let matchesFavorite = !favoritesOnly || store.isFavorite(recipe)
            let matchesCategory = selectedCategory == "All" || recipe.category == selectedCategory || recipe.tags.contains(selectedCategory)
            let words = query.lowercased().split(separator: " ").map(String.init)
            let searchable = ([recipe.title, recipe.description, recipe.category, recipe.cuisine] + recipe.ingredients.map(\.item)).joined(separator: " ").lowercased()
            return matchesFavorite && matchesCategory && words.allSatisfy(searchable.contains)
        }
        if sort == "Highest Rated" { results.sort { $0.rating > $1.rating } }
        if sort == "Quickest" { results.sort { $0.totalMinutes < $1.totalMinutes } }
        return results
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if !favoritesOnly {
                    Text("What are we cooking today?").font(.title2.bold()).padding(.horizontal)
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(categories, id: \.self) { category in
                            Button(category) { selectedCategory = category }
                                .font(.subheadline.weight(.medium)).padding(.horizontal, 14).padding(.vertical, 9)
                                .background(selectedCategory == category ? Color.orange : Color(.secondarySystemBackground), in: Capsule())
                                .foregroundStyle(selectedCategory == category ? Color.white : Color.primary)
                        }
                    }.padding(.horizontal)
                }
                HStack {
                    Text("\(filtered.count) recipes").foregroundStyle(.secondary)
                    Spacer()
                    Picker("Sort", selection: $sort) {
                        Text("Featured").tag("Featured")
                        Text("Highest Rated").tag("Highest Rated")
                        Text("Quickest").tag("Quickest")
                    }.pickerStyle(.menu)
                }.padding(.horizontal)
                LazyVGrid(columns: columns, spacing: 15) {
                    ForEach(filtered) { recipe in
                        NavigationLink { RecipeDetailView(recipeID: recipe.id) } label: { RecipeCardView(recipe: recipe) }
                            .buttonStyle(.plain)
                    }
                }.padding(.horizontal)
                if filtered.isEmpty {
                    ContentUnavailableView("No matching recipes", systemImage: "magnifyingglass", description: Text("Try another search or category."))
                }
            }.padding(.top, 10).padding(.bottom, 80)
        }
        .navigationTitle(favoritesOnly ? "Favorites" : "Recipe Explorer")
        .searchable(text: $query, prompt: "Search names or ingredients")
    }
}

private struct RecipeCardView: View {
    @EnvironmentObject private var store: RecipeStore
    let recipe: Recipe
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .topTrailing) {
                RecipeImageView(url: recipe.imageURL).frame(height: 135).clipped()
                Button { store.toggleFavorite(recipe) } label: {
                    Image(systemName: store.isFavorite(recipe) ? "heart.fill" : "heart")
                        .foregroundStyle(store.isFavorite(recipe) ? Color.red : Color.primary)
                        .padding(9).background(.regularMaterial, in: Circle())
                }.buttonStyle(.plain).padding(7)
            }
            Text(recipe.title).font(.subheadline.bold()).lineLimit(2).frame(height: 37, alignment: .topLeading)
            Text("\(recipe.category) • \(recipe.totalMinutes) min").font(.caption).foregroundStyle(.secondary)
            Label(String(format: "%.1f", recipe.rating), systemImage: "star.fill").font(.caption.weight(.semibold)).foregroundStyle(.orange)
        }.padding(.bottom, 9).background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 13))
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
