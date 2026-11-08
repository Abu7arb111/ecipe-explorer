import SwiftUI
import Combine
import UserNotifications

struct RecipeDetailView: View {
    @EnvironmentObject private var store: RecipeStore
    @Environment(\.dismiss) private var dismiss
    let recipeID: UUID

    @State private var showingEdit = false
    @State private var showingDelete = false
    @State private var showingRepostConfirmation = false
    @State private var showingRepostSuccess = false
    @State private var showingGrocerySuccess = false
    @State private var showingCookingMode = false
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
                        // Hero Image
                        RecipeImageView(url: recipe.imageURL).frame(height: 260).clipped()

                        VStack(alignment: .leading, spacing: 17) {
                            // Title & Author Header
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(recipe.title).font(.title.bold())
                                    Text("By \(recipe.author) • \(recipe.cuisine)").foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button {
                                    store.toggleFavorite(recipe)
                                } label: {
                                    Image(systemName: store.isFavorite(recipe) ? "heart.fill" : "heart")
                                        .font(.title2)
                                        .foregroundStyle(store.isFavorite(recipe) ? .red : .orange)
                                }.accessibilityLabel("Toggle favorite")
                            }

                            // Tags row
                            if !recipe.tags.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 6) {
                                        ForEach(recipe.tags, id: \.self) { tag in
                                            Text(tag)
                                                .font(.caption.weight(.semibold))
                                                .padding(.horizontal, 9)
                                                .padding(.vertical, 4)
                                                .background(Color.orange.opacity(0.12), in: Capsule())
                                                .foregroundStyle(.orange)
                                        }
                                    }
                                }
                            }

                            Text(recipe.description).foregroundStyle(.secondary)

                            // Quick Stats
                            HStack(spacing: 20) {
                                stat("clock", "\(recipe.prepTime)m prep")
                                stat("flame", "\(recipe.cookTime)m cook")
                                stat("person.2", "\(recipe.servings) servings")
                                stat("star.fill", String(format: "%.1f", recipe.rating))
                            }.font(.caption)

                            // Cook Mode Banner Button
                            Button {
                                showingCookingMode = true
                            } label: {
                                HStack {
                                    Image(systemName: "flame.fill")
                                    Text("Start Hands-Free Cook Mode")
                                        .fontWeight(.semibold)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                }
                                .padding()
                                .background(Color.orange, in: RoundedRectangle(cornerRadius: 12))
                                .foregroundStyle(.white)
                            }

                            Divider()

                            // Ingredients with persistent checkmarks & grocery export
                            HStack {
                                Text("Ingredients").font(.title2.bold())
                                Spacer()
                                Button {
                                    store.addIngredientsToGrocery(recipe.ingredients, from: recipe)
                                    showingGrocerySuccess = true
                                } label: {
                                    Label("Add to Grocery", systemImage: "cart.badge.plus")
                                        .font(.caption.weight(.semibold))
                                }
                                .buttonStyle(.bordered)
                                .tint(.orange)
                            }

                            ForEach(recipe.ingredients) { ingredient in
                                Button {
                                    store.toggleIngredientChecked(recipeID: recipe.id, ingredientID: ingredient.id)
                                } label: {
                                    HStack(spacing: 11) {
                                        let isChecked = store.isIngredientChecked(recipeID: recipe.id, ingredientID: ingredient.id)
                                        Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(.orange)
                                        Text("\(ingredient.amount)  \(ingredient.item)")
                                            .strikethrough(isChecked)
                                            .foregroundStyle(isChecked ? Color.secondary : Color.primary)
                                        Spacer()
                                    }.padding(.vertical, 4)
                                }.buttonStyle(.plain)
                            }

                            Divider()

                            // Instructions List
                            Text("Instructions").font(.title2.bold())
                            ForEach(Array(recipe.instructions.enumerated()), id: \.offset) { step, instruction in
                                HStack(alignment: .top, spacing: 12) {
                                    Text("\(step + 1)").font(.subheadline.bold()).foregroundStyle(.white)
                                        .frame(width: 28, height: 28).background(.orange, in: Circle())
                                    Text(instruction).fixedSize(horizontal: false, vertical: true)
                                }
                            }

                            Divider()

                            // Kitchen Countdown Timer with Notification Support
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Kitchen timer").font(.title2.bold())
                                Text(timeString).font(.system(size: 36, weight: .semibold, design: .monospaced))
                                HStack {
                                    Button(running ? "Pause" : "Start") {
                                        if secondsLeft == 0 { secondsLeft = max(recipe.cookTime, 1) * 60 }
                                        running.toggle()
                                        if running {
                                            scheduleNotification(seconds: secondsLeft, title: recipe.title)
                                        } else {
                                            cancelNotification(title: recipe.title)
                                        }
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(.orange)

                                    Button("Reset") {
                                        running = false
                                        cancelNotification(title: recipe.title)
                                        secondsLeft = max(recipe.cookTime, 1) * 60
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                            .onAppear {
                                if secondsLeft == 0 {
                                    secondsLeft = max(recipe.cookTime, 1) * 60
                                }
                            }

                            Divider()

                            // Engagement: Likes, Dislikes, Share, Repost
                            HStack {
                                Button {
                                    store.react(to: recipe, like: true)
                                } label: {
                                    Label("\(recipe.likes)", systemImage: recipe.userReaction == "like" ? "hand.thumbsup.fill" : "hand.thumbsup")
                                }
                                Spacer()
                                Button {
                                    store.react(to: recipe, like: false)
                                } label: {
                                    Label("\(recipe.dislikes)", systemImage: recipe.userReaction == "dislike" ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                                }
                                Spacer()
                                ShareLink(item: "Try \(recipe.title) on Recipe Explorer!") {
                                    Label("Share", systemImage: "square.and.arrow.up")
                                }
                            }.buttonStyle(.bordered)

                            Button {
                                showingRepostConfirmation = true
                            } label: {
                                Label("Repost to My Recipes", systemImage: "arrow.2.squarepath")
                            }
                            .buttonStyle(.bordered)

                            // 5-Star Rating
                            Text("Your rating").font(.headline)
                            HStack(spacing: 12) {
                                ForEach(1...5, id: \.self) { star in
                                    Button {
                                        store.rate(recipe, stars: star)
                                    } label: {
                                        Image(systemName: star <= (recipe.userRating ?? 0) ? "star.fill" : "star")
                                            .font(.title2)
                                            .foregroundStyle(.orange)
                                    }.accessibilityLabel("Rate \(star) stars")
                                }
                            }

                            // Edit / Delete for user-created recipes
                            if recipe.isUserCreated {
                                HStack {
                                    Button("Edit Recipe") { showingEdit = true }
                                    Spacer()
                                    Button("Delete Recipe", role: .destructive) { showingDelete = true }
                                }.padding(.top)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 30)
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .sheet(isPresented: $showingEdit) { NavigationStack { RecipeFormView(existing: recipe) } }
                .fullScreenCover(isPresented: $showingCookingMode) {
                    NavigationStack {
                        CookingModeView(recipe: recipe)
                    }
                }
                .confirmationDialog("Delete this recipe?", isPresented: $showingDelete) {
                    Button("Delete", role: .destructive) { store.delete(recipe); dismiss() }
                }
                .confirmationDialog("Repost this recipe?", isPresented: $showingRepostConfirmation) {
                    Button("Repost") { store.repost(recipe); showingRepostSuccess = true }
                } message: {
                    Text("A local copy will appear in My Recipes with credit to the original author.")
                }
                .alert("Recipe reposted", isPresented: $showingRepostSuccess) { Button("OK", role: .cancel) {} }
                .alert("Added to Grocery List", isPresented: $showingGrocerySuccess) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("All ingredients for \(recipe.title) have been added to your shopping checklist.")
                }
                .alert("Timer complete", isPresented: $timerMessage) { Button("OK", role: .cancel) {} }
                .onReceive(ticker) { _ in
                    if running && secondsLeft > 0 {
                        secondsLeft -= 1
                        if secondsLeft == 0 {
                            running = false
                            timerMessage = true
                        }
                    }
                }
            } else {
                ContentUnavailableView("Recipe unavailable", systemImage: "exclamationmark.triangle")
            }
        }
    }

    private func stat(_ symbol: String, _ label: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: symbol).foregroundStyle(.orange)
            Text(label).lineLimit(1).minimumScaleFactor(0.8)
        }.frame(maxWidth: .infinity)
    }

    private var timeString: String {
        String(format: "%02d:%02d", secondsLeft / 60, secondsLeft % 60)
    }

    // Schedules a local system notification when countdown finishes
    private func scheduleNotification(seconds: Int, title: String) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = "Cooking Timer Complete!"
            content.body = "Your timer for \(title) has finished."
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(max(seconds, 1)), repeats: false)
            let request = UNNotificationRequest(identifier: "recipe-timer-\(title)", content: content, trigger: trigger)
            center.add(request)
        }
    }

    private func cancelNotification(title: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["recipe-timer-\(title)"])
    }
}

/// Full-screen, high-contrast, step-by-step cooking experience.
struct CookingModeView: View {
    let recipe: Recipe
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep = 0
    @State private var stepTimerSeconds = 0
    @State private var timerRunning = false
    @State private var showingFinishedAlert = false
    private let stepTicker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 20) {
            // Header with dismiss and recipe title
            HStack {
                Button("Exit") { dismiss() }
                    .font(.headline)
                    .foregroundStyle(.orange)
                Spacer()
                Text(recipe.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Spacer()
                Text("\(currentStep + 1)/\(recipe.instructions.count)")
                    .font(.subheadline.monospacedDigit().bold())
            }
            .padding(.horizontal)

            // Step Progress Bar
            ProgressView(value: Double(currentStep + 1), total: Double(recipe.instructions.count))
                .tint(.orange)
                .padding(.horizontal)

            Spacer()

            // Step Content Card
            VStack(spacing: 16) {
                Text("Step \(currentStep + 1)")
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(.orange)

                Text(recipe.instructions[currentStep])
                    .font(.title2.weight(.medium))
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding()
                    .frame(maxWidth: .infinity, minHeight: 180)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal)

            Spacer()

            // Mini Cooking Timer in Cook Mode
            VStack(spacing: 8) {
                Text(timerString)
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                HStack(spacing: 12) {
                    Button(timerRunning ? "Pause Timer" : "Start 5m Timer") {
                        if stepTimerSeconds == 0 { stepTimerSeconds = 300 }
                        timerRunning.toggle()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)

                    Button("Reset") {
                        timerRunning = false
                        stepTimerSeconds = 0
                    }
                    .buttonStyle(.bordered)
                }
            }

            Spacer()

            // Navigation Controls (Previous / Next / Finish)
            HStack(spacing: 20) {
                Button {
                    if currentStep > 0 { currentStep -= 1 }
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Previous")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(currentStep == 0 ? Color.gray.opacity(0.2) : Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(currentStep == 0 ? Color.secondary : Color.primary)
                }
                .disabled(currentStep == 0)

                Button {
                    if currentStep < recipe.instructions.count - 1 {
                        currentStep += 1
                    } else {
                        showingFinishedAlert = true
                    }
                } label: {
                    HStack {
                        Text(currentStep == recipe.instructions.count - 1 ? "Finish Cooking" : "Next Step")
                        Image(systemName: currentStep == recipe.instructions.count - 1 ? "checkmark.circle.fill" : "chevron.right")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .navigationBarHidden(true)
        .alert("Congratulations!", isPresented: $showingFinishedAlert) {
            Button("Done", role: .cancel) { dismiss() }
        } message: {
            Text("You've completed all steps for \(recipe.title)! Enjoy your meal.")
        }
        .onReceive(stepTicker) { _ in
            if timerRunning && stepTimerSeconds > 0 {
                stepTimerSeconds -= 1
                if stepTimerSeconds == 0 { timerRunning = false }
            }
        }
    }

    private var timerString: String {
        String(format: "%02d:%02d", stepTimerSeconds / 60, stepTimerSeconds % 60)
    }
}
