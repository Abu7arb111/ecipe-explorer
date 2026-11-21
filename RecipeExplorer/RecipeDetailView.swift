import SwiftUI
import Combine
import UserNotifications

struct RecipeDetailView: View {
    @EnvironmentObject private var store: RecipeStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    let recipeID: UUID

    @State private var showingEdit = false
    @State private var showingDelete = false
    @State private var showingRepostConfirmation = false
    @State private var showingRepostSuccess = false
    @State private var showingGrocerySuccess = false
    @State private var showingCookingMode = false
    @State private var secondsLeft: Int = 0
    @State private var timerDeadline: Date?
    @State private var notificationTask: Task<Void, Never>?
    @State private var notificationID: String?
    @State private var timerMessage = false
    @State private var showingPublishConfirmation = false
    @State private var showingUnpublishConfirmation = false
    @State private var communityBusy = false
    @State private var communityError: String? = nil

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private var running: Bool { timerDeadline != nil }
    // Works for recipes in My Recipes and for recipes from the community feed.
    private var recipe: Recipe? { store.recipe(withID: recipeID) }
    // Someone else's (or your) published recipe that isn't stored in My Recipes on this device.
    // Personal features that only apply to local recipes (favorite, reactions, rating) are hidden.
    private var isCommunityOnly: Bool { !store.recipes.contains { $0.id == recipeID } }

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
                                if !isCommunityOnly {
                                    Button {
                                        store.toggleFavorite(recipe)
                                    } label: {
                                        Image(systemName: store.isFavorite(recipe) ? "heart.fill" : "heart")
                                            .font(.title2)
                                            .foregroundStyle(store.isFavorite(recipe) ? .red : .orange)
                                    }.accessibilityLabel("Toggle favorite")
                                }
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
                                        if running {
                                            refreshTimer()
                                            timerDeadline = nil
                                            cancelNotification()
                                        } else {
                                            if secondsLeft == 0 { secondsLeft = max(recipe.cookTime, 1) * 60 }
                                            let deadline = Date().addingTimeInterval(TimeInterval(secondsLeft))
                                            timerDeadline = deadline
                                            scheduleNotification(for: recipe, deadline: deadline)
                                        }
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(.orange)

                                    Button("Reset") {
                                        timerDeadline = nil
                                        cancelNotification()
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
                                if !isCommunityOnly {
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
                                }
                                ShareLink(item: "Try \(recipe.title) on Recipe Explorer!") {
                                    Label("Share", systemImage: "square.and.arrow.up")
                                }
                            }.buttonStyle(.bordered)

                            Button {
                                showingRepostConfirmation = true
                            } label: {
                                Label(isCommunityOnly ? "Save a Copy to My Recipes" : "Repost to My Recipes",
                                      systemImage: "arrow.2.squarepath")
                            }
                            .buttonStyle(.bordered)

                            // 5-Star Rating (personal, so only for recipes stored on this device)
                            if !isCommunityOnly {
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
                            }

                            // Publish / unpublish / edit / delete, or who owns it
                            communityControls(for: recipe)
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
                .onReceive(ticker) { _ in refreshTimer() }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active { refreshTimer() }
                }
            } else {
                ContentUnavailableView("Recipe unavailable", systemImage: "exclamationmark.triangle")
            }
        }
    }

    // Everything about sharing and ownership. Kept out of `body` so the compiler
    // doesn't have to type-check one enormous expression.
    private func communityControls(for recipe: Recipe) -> some View {
        VStack(alignment: .leading, spacing: 17) {
            communitySection(for: recipe)

            // Edit / Delete: only the recipe's author sees these
            if store.canModify(recipe) {
                HStack {
                    Button("Edit Recipe") { showingEdit = true }
                    Spacer()
                    Button(isCommunityOnly ? "Delete from Community" : "Delete Recipe", role: .destructive) {
                        showingDelete = true
                    }
                }
                .padding(.top)
                .disabled(communityBusy)
            }
        }
        .confirmationDialog("Delete this recipe?", isPresented: $showingDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                runCommunityAction(dismissOnSuccess: true) { try await store.deleteEverywhere(recipe) }
            }
        } message: {
            if store.isPublished(recipe) {
                Text("It will also be removed from the community feed for everyone.")
            }
        }
        .confirmationDialog("Publish this recipe?", isPresented: $showingPublishConfirmation, titleVisibility: .visible) {
            Button("Publish") {
                runCommunityAction { try await store.publish(recipe) }
            }
        } message: {
            Text("Other users will be able to browse it in the Community tab. Only you can edit, unpublish, or delete it.")
        }
        .confirmationDialog("Unpublish this recipe?", isPresented: $showingUnpublishConfirmation, titleVisibility: .visible) {
            Button("Unpublish", role: .destructive) {
                runCommunityAction { try await store.unpublish(recipe) }
            }
        } message: {
            Text("It will be removed from the community feed but stay in My Recipes.")
        }
        .alert("Community", isPresented: Binding(
            get: { communityError != nil },
            set: { if !$0 { communityError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(communityError ?? "")
        }
    }

    // Publishing controls for the author; an ownership note for everyone else.
    @ViewBuilder
    private func communitySection(for recipe: Recipe) -> some View {
        let isOwner = store.canModify(recipe)
        let isPublished = store.isPublished(recipe)
        if isOwner || isPublished {
            Divider()
            VStack(alignment: .leading, spacing: 10) {
                Text("Community").font(.title2.bold())
                if isPublished {
                    Label(publishedDescription(for: recipe), systemImage: "globe")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.green)
                }
                if isOwner {
                    if !isPublished {
                        Text("Only you can see this recipe. Publish it so other users can browse it.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Button {
                            showingPublishConfirmation = true
                        } label: {
                            Label("Publish to Community", systemImage: "globe")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                    } else if !isCommunityOnly {
                        Button {
                            showingUnpublishConfirmation = true
                        } label: {
                            Label("Unpublish", systemImage: "eye.slash")
                        }
                        .buttonStyle(.bordered)
                    }
                    if communityBusy {
                        ProgressView("Updating community feed…").font(.footnote)
                    }
                } else {
                    Label("Shared by \(recipe.author). Only the author can edit or delete it.", systemImage: "lock")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .disabled(communityBusy)
        }
    }

    private func publishedDescription(for recipe: Recipe) -> String {
        guard let date = recipe.publishedAt else { return "Published to the community" }
        return "Published \(date.formatted(date: .abbreviated, time: .omitted))"
    }

    // Runs a publish/unpublish/delete call, showing progress and any error.
    @MainActor
    private func runCommunityAction(dismissOnSuccess: Bool = false,
                                    _ action: @escaping @MainActor () async throws -> Void) {
        guard !communityBusy else { return }
        communityBusy = true
        Task { @MainActor in
            defer { communityBusy = false }
            do {
                try await action()
                if dismissOnSuccess { dismiss() }
            } catch {
                communityError = error.localizedDescription
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

    private func refreshTimer() {
        guard let deadline = timerDeadline else { return }
        secondsLeft = max(0, Int(ceil(deadline.timeIntervalSinceNow)))
        if secondsLeft == 0 {
            timerDeadline = nil
            timerMessage = true
        }
    }

    private func scheduleNotification(for recipe: Recipe, deadline: Date) {
        let center = UNUserNotificationCenter.current()
        cancelNotification()
        let identifier = "recipe-timer-\(recipe.id)-\(UUID())"
        notificationID = identifier
        notificationTask = Task { @MainActor in
            guard (try? await center.requestAuthorization(options: [.alert, .sound])) == true,
                  !Task.isCancelled, timerDeadline == deadline,
                  deadline > Date() else { return }
            let content = UNMutableNotificationContent()
            content.title = "Cooking Timer Complete!"
            content.body = "Your timer for \(recipe.title) has finished."
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: max(1, deadline.timeIntervalSinceNow), repeats: false
            )
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            try? await center.add(request)
            if Task.isCancelled {
                center.removePendingNotificationRequests(withIdentifiers: [identifier])
            }
        }
    }

    private func cancelNotification() {
        notificationTask?.cancel()
        notificationTask = nil
        if let notificationID {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationID])
            self.notificationID = nil
        }
    }
}

/// Full-screen, high-contrast, step-by-step cooking experience.
struct CookingModeView: View {
    let recipe: Recipe
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep = 0
    @State private var stepTimerSeconds = 0
    @State private var timerRunning = false
    @State private var showingFinishedAlert = false
    private let stepTicker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 20) {
                    header
                    if recipe.instructions.isEmpty {
                        ContentUnavailableView("No cooking steps", systemImage: "fork.knife")
                    } else {
                        ProgressView(value: Double(currentStep + 1), total: Double(recipe.instructions.count))
                            .tint(.orange)

                        if geometry.size.width >= 700 && !dynamicTypeSize.isAccessibilitySize {
                            HStack(alignment: .top, spacing: 24) {
                                stepContent
                                VStack(spacing: 20) {
                                    timerControls
                                    navigationControls
                                }
                                .frame(width: 300)
                            }
                        } else {
                            compactCookingLayout
                        }
                    }
                }
                .padding()
            }
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

    private var header: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 8))
            : AnyLayout(HStackLayout(spacing: 12))
        return layout {
            Button("Exit") { dismiss() }
                .font(.headline)
                .foregroundStyle(.orange)
                .frame(minHeight: 44)
            Text(recipe.title)
                .font(.subheadline.weight(.semibold))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            if !recipe.instructions.isEmpty {
                Text("\(currentStep + 1)/\(recipe.instructions.count)")
                    .font(.subheadline.monospacedDigit().bold())
                    .accessibilityLabel("Step \(currentStep + 1) of \(recipe.instructions.count)")
            }
        }
    }

    private var compactCookingLayout: some View {
        VStack(spacing: 20) {
            stepContent
            timerControls
            navigationControls
        }
    }

    private var stepContent: some View {
        VStack(spacing: 16) {
            Text("Step \(currentStep + 1)")
                .font(.title3.weight(.heavy))
                .foregroundStyle(.orange)
                .accessibilityAddTraits(.isHeader)

            Text(recipe.instructions[currentStep])
                .font(.title2.weight(.medium))
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 180)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private var timerControls: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 12))
            : AnyLayout(HStackLayout(spacing: 12))
        return VStack(spacing: 8) {
            Text(timerString)
                .font(.title.monospacedDigit().bold())
            layout {
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
    }

    private var navigationControls: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 12))
            : AnyLayout(HStackLayout(spacing: 12))
        return layout {
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
    }

    private var timerString: String {
        String(format: "%02d:%02d", stepTimerSeconds / 60, stepTimerSeconds % 60)
    }
}
