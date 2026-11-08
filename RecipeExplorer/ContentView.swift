import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: RecipeStore
    @State private var showingNew = false

    var body: some View {
        TabView {
            // 1. Explore Tab
            NavigationStack {
                RecipeFeedView(favoritesOnly: false)
            }
            .tabItem { Label("Explore", systemImage: "square.grid.2x2") }

            // 2. Favorites Tab
            NavigationStack {
                RecipeFeedView(favoritesOnly: true)
            }
            .tabItem { Label("Favorites", systemImage: "heart.fill") }

            // 3. Smart Grocery List Tab
            NavigationStack {
                GroceryListView()
            }
            .tabItem { Label("Grocery", systemImage: "cart.fill") }

            // 4. Chef Profile & My Recipes Tab
            NavigationStack {
                MyRecipesProfileView()
            }
            .tabItem { Label("My Recipes", systemImage: "person.crop.circle") }
        }
        .tint(.orange)
        .toolbar(.visible, for: .tabBar)
        // Floating action button to quickly add a recipe from any screen
        .overlay(alignment: .bottomTrailing) {
            Button {
                showingNew = true
            } label: {
                Image(systemName: "plus")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .padding(18)
                    .background(Color.orange, in: Circle())
                    .shadow(radius: 4)
            }
            .accessibilityLabel("Add a recipe")
            .padding(.trailing, 22)
            .padding(.bottom, 75)
        }
        .sheet(isPresented: $showingNew) {
            NavigationStack { RecipeFormView(existing: nil) }
        }
        // Centralized storage error alert
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

// MARK: - Smart Grocery List View

struct GroceryListView: View {
    @EnvironmentObject private var store: RecipeStore
    @State private var newItemText = ""
    @State private var newAmountText = "1"
    @State private var filterSelection = "All"
    private let filters = ["All", "To Buy", "Purchased"]

    private var filteredItems: [GroceryItem] {
        switch filterSelection {
        case "To Buy":
            return store.groceryList.filter { !$0.isPurchased }
        case "Purchased":
            return store.groceryList.filter { $0.isPurchased }
        default:
            return store.groceryList
        }
    }

    private var shoppingListExportText: String {
        var lines = ["🛒 Recipe Explorer — Grocery List", ""]
        let remaining = store.groceryList.filter { !$0.isPurchased }
        let completed = store.groceryList.filter { $0.isPurchased }

        if !remaining.isEmpty {
            lines.append("Items to buy:")
            for item in remaining {
                lines.append("• [ ] \(item.amount) \(item.item)")
            }
            lines.append("")
        }

        if !completed.isEmpty {
            lines.append("Completed:")
            for item in completed {
                lines.append("• [x] \(item.amount) \(item.item)")
            }
        }
        return lines.joined(separator: "\n")
    }

    var body: some View {
        VStack(spacing: 0) {
            // Quick Add Bar
            HStack(spacing: 8) {
                TextField("Add custom item (e.g. Milk)", text: $newItemText)
                    .textFieldStyle(.roundedBorder)
                TextField("Qty", text: $newAmountText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 65)

                Button("Add") {
                    if store.addCustomGroceryItem(item: newItemText, amount: newAmountText) {
                        newItemText = ""
                        newAmountText = "1"
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .disabled(newItemText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(Color(.secondarySystemBackground))

            // Filter Selector
            Picker("Filter", selection: $filterSelection) {
                ForEach(filters, id: \.self) { filter in
                    Text(filter).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)

            // Items List
            List {
                ForEach(filteredItems) { item in
                    HStack(spacing: 12) {
                        Button {
                            store.toggleGroceryItemPurchased(item)
                        } label: {
                            Image(systemName: item.isPurchased ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(item.isPurchased ? .green : .orange)
                                .font(.title3)
                        }
                        .buttonStyle(.plain)

                        VStack(alignment: .leading, spacing: 3) {
                            Text("\(item.amount)  \(item.item)")
                                .strikethrough(item.isPurchased)
                                .foregroundStyle(item.isPurchased ? .secondary : .primary)
                                .font(.body.weight(item.isPurchased ? .regular : .medium))

                            if let title = item.recipeTitle {
                                Text("For: \(title)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()
                    }
                    .padding(.vertical, 2)
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        let item = filteredItems[index]
                        store.deleteGroceryItem(item)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .overlay {
                if filteredItems.isEmpty {
                    ContentUnavailableView(
                        store.groceryList.isEmpty ? "Grocery List Empty" : "No Matching Items",
                        systemImage: "cart",
                        description: Text(store.groceryList.isEmpty ? "Tap 'Add to Grocery' in any recipe detail view or add custom items above." : "Change your filter selection to view items.")
                    )
                }
            }
        }
        .navigationTitle("Grocery List")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if !store.groceryList.isEmpty {
                    ShareLink(item: shoppingListExportText) {
                        Label("Share List", systemImage: "square.and.arrow.up")
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(role: .destructive) {
                        store.clearPurchasedGroceryItems()
                    } label: {
                        Label("Clear Purchased", systemImage: "checkmark.circle")
                    }
                    Button(role: .destructive) {
                        store.clearAllGroceryItems()
                    } label: {
                        Label("Clear All Items", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .disabled(store.groceryList.isEmpty)
            }
        }
    }
}

// MARK: - Chef Profile & My Recipes View

struct MyRecipesProfileView: View {
    @EnvironmentObject private var store: RecipeStore
    @State private var showingEditProfile = false

    var body: some View {
        List {
            // Chef Profile Header Card
            Section {
                VStack(spacing: 12) {
                    HStack(spacing: 16) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.orange)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(store.userProfile.name)
                                .font(.title3.bold())
                            Text(store.userProfile.bio)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                        Spacer()
                    }

                    // Dietary Badges
                    if !store.userProfile.dietaryPreferences.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(store.userProfile.dietaryPreferences, id: \.self) { pref in
                                    Text(pref)
                                        .font(.caption2.bold())
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Color.green.opacity(0.15), in: Capsule())
                                        .foregroundStyle(.green)
                                }
                            }
                        }
                    }

                    Divider()

                    // Project Statistics
                    HStack {
                        statPill(label: "Recipes", value: "\(store.recipes.filter(\.isUserCreated).count)")
                        Spacer()
                        statPill(label: "Favorites", value: "\(store.favorites.count)")
                        Spacer()
                        statPill(label: "Grocery Items", value: "\(store.groceryList.count)")
                    }
                    .padding(.top, 2)

                    Button("Edit Chef Profile") {
                        showingEditProfile = true
                    }
                    .font(.footnote.weight(.semibold))
                    .buttonStyle(.bordered)
                    .tint(.orange)
                    .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 6)
            }

            // User's Created Recipes List
            Section("My Created & Reposted Recipes") {
                let userRecipes = store.recipes.filter(\.isUserCreated)
                if userRecipes.isEmpty {
                    ContentUnavailableView(
                        "No recipes yet",
                        systemImage: "square.and.pencil",
                        description: Text("Create a recipe using the + button or repost an existing one.")
                    )
                    .padding(.vertical, 20)
                } else {
                    ForEach(userRecipes) { recipe in
                        NavigationLink {
                            RecipeDetailView(recipeID: recipe.id)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(recipe.title)
                                    .font(.headline)
                                HStack {
                                    Text(recipe.category)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Label("\(recipe.likes)", systemImage: "hand.thumbsup.fill")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
        }
        .navigationTitle("Chef Profile")
        .sheet(isPresented: $showingEditProfile) {
            ProfileEditSheet()
        }
    }

    private func statPill(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline.bold())
                .foregroundStyle(.orange)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Profile Edit Sheet

struct ProfileEditSheet: View {
    @EnvironmentObject private var store: RecipeStore
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var bio: String = ""
    @State private var selectedPreferences: Set<String> = []

    private let availablePreferences = ["Vegetarian", "Vegan", "Gluten-Free", "High Protein", "Quick & Easy", "Keto"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Personal Info") {
                    TextField("Chef Name", text: $name)
                    TextField("Short Bio", text: $bio, axis: .vertical)
                        .lineLimit(2...3)
                }

                Section("Dietary Focus") {
                    ForEach(availablePreferences, id: \.self) { pref in
                        Button {
                            if selectedPreferences.contains(pref) {
                                selectedPreferences.remove(pref)
                            } else {
                                selectedPreferences.insert(pref)
                            }
                        } label: {
                            HStack {
                                Text(pref)
                                    .foregroundStyle(Color.primary)
                                Spacer()
                                if selectedPreferences.contains(pref) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.orange)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.updateProfile(
                            name: name,
                            bio: bio,
                            dietaryPreferences: Array(selectedPreferences)
                        )
                        dismiss()
                    }
                }
            }
            .onAppear {
                name = store.userProfile.name
                bio = store.userProfile.bio
                selectedPreferences = Set(store.userProfile.dietaryPreferences)
            }
        }
    }
}
