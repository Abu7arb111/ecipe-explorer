import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: RecipeStore
    @State private var showingNew = false
    var body: some View {
        TabView {
            NavigationStack { RecipeFeedView(favoritesOnly: false) }
                .tabItem { Label("Explore", systemImage: "square.grid.2x2") }
            NavigationStack { RecipeFeedView(favoritesOnly: true) }
                .tabItem { Label("Favorites", systemImage: "heart.fill") }
            NavigationStack {
                List(store.recipes.filter(\.isUserCreated)) { recipe in
                    NavigationLink { RecipeDetailView(recipeID: recipe.id) } label: {
                        VStack(alignment: .leading) { Text(recipe.title).font(.headline); Text(recipe.category).font(.caption).foregroundStyle(.secondary) }
                    }
                }
                .overlay { if store.recipes.filter(\.isUserCreated).isEmpty { ContentUnavailableView("No recipes yet", systemImage: "square.and.pencil", description: Text("Create a recipe using the + button.")) } }
                .navigationTitle("My Recipes")
            }.tabItem { Label("My Recipes", systemImage: "person.crop.circle") }
        }
        .tint(.orange)
        .toolbar(.visible, for: .tabBar)
        .overlay(alignment: .bottomTrailing) {
            Button { showingNew = true } label: { Image(systemName: "plus").font(.title2.bold()).foregroundStyle(.white).padding(19).background(.orange, in: Circle()).shadow(radius: 5) }
                .accessibilityLabel("Add a recipe")
                .padding(.trailing, 22).padding(.bottom, 75)
        }
        .sheet(isPresented: $showingNew) { NavigationStack { RecipeFormView(existing: nil) } }
        
        // Shows a popup whenever the store reports a storage problem
        // (corrupted saved data or a failed save). Tapping OK clears the message.
        .alert("Storage problem", isPresented: Binding(
            get: { store.storageError != nil },
            set: { if !$0 { store.storageError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(store.storageError ?? "")
        }
    }
}
