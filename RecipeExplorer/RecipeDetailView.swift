import SwiftUI
import Combine

struct RecipeDetailView: View {
    @EnvironmentObject private var store: RecipeStore
    @Environment(\.dismiss) private var dismiss
    let recipeID: UUID
    @State private var checked: Set<UUID> = []
    @State private var showingEdit = false
    @State private var showingDelete = false
    @State private var showingRepostConfirmation = false
    @State private var showingRepostSuccess = false
    @State private var secondsLeft: Int = 0
    @State private var running = false
    @State private var timerMessage = false
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private var recipe: Recipe? { store.recipes.first { $0.id == recipeID } }

    var body: some View {
        Group {
            if let recipe {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        RecipeImageView(url: recipe.imageURL).frame(height: 260).clipped()
                        VStack(alignment: .leading, spacing: 17) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(recipe.title).font(.title.bold())
                                    Text("By \(recipe.author) • \(recipe.cuisine)").foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button { store.toggleFavorite(recipe) } label: {
                                    Image(systemName: store.isFavorite(recipe) ? "heart.fill" : "heart").font(.title2)
                                        .foregroundStyle(store.isFavorite(recipe) ? .red : .orange)
                                }.accessibilityLabel("Toggle favorite")
                            }
                            Text(recipe.description).foregroundStyle(.secondary)
                            HStack(spacing: 20) {
                                stat("clock", "\(recipe.prepTime)m prep")
                                stat("flame", "\(recipe.cookTime)m cook")
                                stat("person.2", "\(recipe.servings) servings")
                                stat("star.fill", String(format: "%.1f", recipe.rating))
                            }.font(.caption)
                            Text("Ingredients").font(.title2.bold())
                            ForEach(recipe.ingredients) { ingredient in
                                Button {
                                    if !checked.insert(ingredient.id).inserted { checked.remove(ingredient.id) }
                                } label: {
                                    HStack(spacing: 11) {
                                        Image(systemName: checked.contains(ingredient.id) ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(.orange)
                                        Text("\(ingredient.amount)  \(ingredient.item)")
                                            .strikethrough(checked.contains(ingredient.id))
                                            .foregroundStyle(checked.contains(ingredient.id) ? Color.secondary : Color.primary)
                                        Spacer()
                                    }.padding(.vertical, 4)
                                }.buttonStyle(.plain)
                            }
                            Divider()
                            Text("Instructions").font(.title2.bold())
                            ForEach(Array(recipe.instructions.enumerated()), id: \.offset) { step, instruction in
                                HStack(alignment: .top, spacing: 12) {
                                    Text("\(step + 1)").font(.subheadline.bold()).foregroundStyle(.white)
                                        .frame(width: 28, height: 28).background(.orange, in: Circle())
                                    Text(instruction).fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            Divider()
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Kitchen timer").font(.title2.bold())
                                Text(timeString).font(.system(size: 36, weight: .semibold, design: .monospaced))
                                HStack {
                                    Button(running ? "Pause" : "Start") {
                                        if secondsLeft == 0 { secondsLeft = max(recipe.cookTime, 1) * 60 }
                                        running.toggle()
                                    }.buttonStyle(.borderedProminent).tint(.orange)
                                    Button("Reset") { running = false; secondsLeft = max(recipe.cookTime, 1) * 60 }
                                        .buttonStyle(.bordered)
                                }
                            }.onAppear { secondsLeft = max(recipe.cookTime, 1) * 60 }
                            Divider()
                            HStack {
                                Button { store.react(to: recipe, like: true) } label: { Label("\(recipe.likes)", systemImage: recipe.userReaction == "like" ? "hand.thumbsup.fill" : "hand.thumbsup") }
                                Spacer()
                                Button { store.react(to: recipe, like: false) } label: { Label("\(recipe.dislikes)", systemImage: recipe.userReaction == "dislike" ? "hand.thumbsdown.fill" : "hand.thumbsdown") }
                                Spacer()
                                ShareLink(item: "Try \(recipe.title) on Recipe Explorer!") { Label("Share", systemImage: "square.and.arrow.up") }
                            }.buttonStyle(.bordered)
                            Button {
                                showingRepostConfirmation = true
                            } label: { Label("Repost to My Recipes", systemImage: "arrow.2.squarepath") }
                                .buttonStyle(.bordered)
                            Text("Your rating").font(.headline)
                            HStack(spacing: 12) {
                                ForEach(1...5, id: \.self) { star in
                                    Button { store.rate(recipe, stars: star) } label: {
                                        Image(systemName: star <= (recipe.userRating ?? 0) ? "star.fill" : "star")
                                            .font(.title2).foregroundStyle(.orange)
                                    }.accessibilityLabel("Rate \(star) stars")
                                }
                            }
                            if recipe.isUserCreated {
                                HStack {
                                    Button("Edit Recipe") { showingEdit = true }
                                    Spacer()
                                    Button("Delete Recipe", role: .destructive) { showingDelete = true }
                                }.padding(.top)
                            }
                        }.padding(.horizontal).padding(.bottom, 30)
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .sheet(isPresented: $showingEdit) { NavigationStack { RecipeFormView(existing: recipe) } }
                .confirmationDialog("Delete this recipe?", isPresented: $showingDelete) {
                    Button("Delete", role: .destructive) { store.delete(recipe); dismiss() }
                }
                .confirmationDialog("Repost this recipe?", isPresented: $showingRepostConfirmation) {
                    Button("Repost") { store.repost(recipe); showingRepostSuccess = true }
                } message: { Text("A local copy will appear in My Recipes with credit to the original author.") }
                .alert("Recipe reposted", isPresented: $showingRepostSuccess) { Button("OK", role: .cancel) {} }
                .alert("Timer complete", isPresented: $timerMessage) { Button("OK", role: .cancel) {} }
                .onReceive(ticker) { _ in
                    if running && secondsLeft > 0 {
                        secondsLeft -= 1
                        if secondsLeft == 0 { running = false; timerMessage = true }
                    }
                }
            } else { ContentUnavailableView("Recipe unavailable", systemImage: "exclamationmark.triangle") }
        }
    }
    private func stat(_ symbol: String, _ label: String) -> some View {
        VStack(spacing: 6) { Image(systemName: symbol).foregroundStyle(.orange); Text(label).lineLimit(1).minimumScaleFactor(0.8) }.frame(maxWidth: .infinity)
    }
    private var timeString: String { String(format: "%02d:%02d", secondsLeft / 60, secondsLeft % 60) }
}
