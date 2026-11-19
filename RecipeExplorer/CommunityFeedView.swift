import SwiftUI

/// Browse recipes that every user has published. Tapping one opens the normal
/// detail screen; only the author sees Edit / Delete / Unpublish there.
struct CommunityFeedView: View {
    @EnvironmentObject private var store: RecipeStore
    @State private var query = ""
    @State private var scope = Scope.everyone
    @State private var showingSettings = false

    enum Scope: String, CaseIterable, Identifiable {
        case everyone = "Everyone"
        case mine = "Published by Me"
        var id: String { rawValue }
    }

    private var filtered: [Recipe] {
        let words = query.lowercased().split(separator: " ").map(String.init)
        return store.communityRecipes.filter { recipe in
            let matchesScope = scope == .everyone || recipe.authorID == store.authorID
            let searchable = ([recipe.title, recipe.description, recipe.author, recipe.category, recipe.cuisine]
                              + recipe.tags + recipe.ingredients.map(\.item)).joined(separator: " ").lowercased()
            return matchesScope && words.allSatisfy(searchable.contains)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                // Where recipes are shared right now
                HStack(spacing: 6) {
                    Image(systemName: store.isUsingLocalCommunity ? "iphone" : "network")
                    Text(store.isUsingLocalCommunity ? "On-device demo feed" : store.communityServerURL)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                    if store.isLoadingCommunity && !store.communityRecipes.isEmpty {
                        ProgressView().controlSize(.small)
                    }
                    Button("Change") { showingSettings = true }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

                Picker("Show", selection: $scope) {
                    ForEach(Scope.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // A refresh failed but we still have the last list: keep showing it with a warning.
                if let error = store.communityLoadError, !store.communityRecipes.isEmpty {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                        .padding(.horizontal)
                }

                if filtered.isEmpty {
                    emptyState.frame(maxWidth: .infinity).padding(.top, 30)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(filtered) { recipe in
                            NavigationLink {
                                RecipeDetailView(recipeID: recipe.id)
                            } label: {
                                CommunityRecipeRow(recipe: recipe, isMine: recipe.authorID == store.authorID)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.top, 10)
            .padding(.bottom, 80)
        }
        .navigationTitle("Community")
        .searchable(text: $query, prompt: "Search recipes or authors")
        .refreshable { await store.refreshCommunity() }
        // Reload whenever the tab appears so newly published recipes show up.
        .task { await store.refreshCommunity() }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingSettings = true } label: { Image(systemName: "gearshape") }
                    .accessibilityLabel("Community sharing settings")
            }
        }
        .sheet(isPresented: $showingSettings) { CommunitySettingsView() }
    }

    @ViewBuilder
    private var emptyState: some View {
        if store.isLoadingCommunity && store.communityRecipes.isEmpty {
            ProgressView("Loading community recipes…")
        } else if let error = store.communityLoadError, store.communityRecipes.isEmpty {
            ContentUnavailableView {
                Label("Can't load the community feed", systemImage: "wifi.exclamationmark")
            } description: {
                Text(error)
            } actions: {
                Button("Try Again") { Task { await store.refreshCommunity() } }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
            }
        } else if !query.isEmpty {
            ContentUnavailableView.search(text: query)
        } else if scope == .mine {
            ContentUnavailableView("You haven't published anything yet", systemImage: "globe",
                                   description: Text("Open one of your recipes in My Recipes and tap Publish to Community."))
        } else {
            ContentUnavailableView("No community recipes yet", systemImage: "person.3",
                                   description: Text("Be the first: publish one of your recipes from My Recipes."))
        }
    }
}

private struct CommunityRecipeRow: View {
    let recipe: Recipe
    let isMine: Bool

    var body: some View {
        HStack(spacing: 12) {
            RecipeImageView(url: recipe.imageURL)
                .frame(width: 84, height: 84)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.title)
                    .font(.subheadline.bold())
                    .lineLimit(2)
                HStack(spacing: 4) {
                    Image(systemName: "person.circle.fill")
                    Text(recipe.author).lineLimit(1)
                    if isMine {
                        Text("You")
                            .font(.caption2.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.15), in: Capsule())
                            .foregroundStyle(.orange)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                Text("\(recipe.category) • \(recipe.totalMinutes) min")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let date = recipe.publishedAt {
                    Text("Published \(date.formatted(.relative(presentation: .named)))")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(10)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 13))
        .accessibilityElement(children: .combine)
    }
}

/// Choose where published recipes are shared: the on-device demo feed, or a
/// community server that several phones/simulators point at.
struct CommunitySettingsView: View {
    @EnvironmentObject private var store: RecipeStore
    @Environment(\.dismiss) private var dismiss
    @State private var useServer = false
    @State private var address = ""
    @State private var addressError: String? = nil

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Share recipes via", selection: $useServer) {
                        Text("This device only (demo)").tag(false)
                        Text("Community server").tag(true)
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                } footer: {
                    Text(useServer
                         ? "Everyone whose app points at the same server sees each other's published recipes."
                         : "Published recipes stay on this device next to a few sample community recipes. Other users won't see them.")
                }

                if useServer {
                    Section {
                        TextField("http://127.0.0.1:8080", text: $address)
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .onChange(of: address) { addressError = nil }
                    } header: {
                        Text("Server address")
                    } footer: {
                        if let addressError {
                            Text(addressError).foregroundStyle(.red)
                        } else {
                            Text("Start community-server/server.py on your Mac. Simulators can use http://127.0.0.1:8080; a physical iPhone needs your Mac's local network address.")
                        }
                    }
                }

                Section {
                    LabeledContent("Your author ID", value: String(store.authorID.uuidString.prefix(8)))
                } footer: {
                    Text("Recipes you publish are tied to this ID (not your chef name), so only this app install can edit or delete them.")
                }
            }
            .navigationTitle("Community Sharing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { apply() } }
            }
            .onAppear {
                useServer = !store.isUsingLocalCommunity
                address = store.communityServerURL
            }
        }
    }

    private func apply() {
        let target = useServer ? address.trimmingCharacters(in: .whitespacesAndNewlines) : ""
        if useServer && RecipeValidator.communityServerURL(target) == nil {
            addressError = CommunityError.invalidServerURL.errorDescription
            return
        }
        if target != store.communityServerURL {
            store.setCommunityServer(target)
            Task { await store.refreshCommunity() }
        }
        dismiss()
    }
}
