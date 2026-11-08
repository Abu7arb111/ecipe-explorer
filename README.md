# Recipe Explorer — Native iOS App (SwiftUI)

This is a **native SwiftUI implementation** for iOS 17.0+, built for CS 374. It is an offline-first, feature-complete recipe exploration, creation, and cooking companion app.

* **GitHub Repository:** [https://github.com/Abu7arb111/ecipe-explorer](https://github.com/Abu7arb111/ecipe-explorer)
* **Team Members:** Ahmad Harb, Vedanth Subramanian, Tylor Newcomb, Insung

---

## How to Run in Xcode

1. Open `RecipeExplorer.xcodeproj` in Xcode on macOS.
2. Select the `RecipeExplorer` target. Under **Signing & Capabilities**, select your Personal Team if prompted.
3. Choose an iPhone Simulator (e.g. iPhone 16 or 17) or physical iOS device.
4. Press **Cmd + R** to run the app, or **Cmd + U** to run all automated unit tests.
5. Deployment target: **iOS 17.0+** (no third-party pods, packages, or API keys required).

---

## Implemented Features (100% Complete)

### 1. Recipe Browsing & Multi-Criteria Search
* Two-column adaptive recipe card feed with visual ratings and prep time badges.
* Category filter chips: *All, Breakfast, Lunch, Dinner, Vegetarian, Quick & Easy*.
* **Dietary Tag Filtering**: Instant filtering by *Vegetarian, Vegan, Gluten-Free, High Protein, Quick & Easy*.
* Real-time search across titles, descriptions, cuisines, dietary tags, and ingredient names.
* Sorting selector: *Featured, Highest Rated, Quickest*.

### 2. Interactive Recipe Detail Experience
* Hero recipe image with offline fallback placeholder.
* Ingredient checklist with **persistent session checkmarks** saved across app restarts.
* **One-Tap Grocery List Export**: Adds recipe ingredients directly into the Smart Grocery List.
* Interactive 1–5 star personal rating selector.
* Reversible like and dislike reaction counters that prevent count inflation.
* Social reposting: Clones recipes into "My Recipes" with credited author attribution.

### 3. Hands-Free Step-by-Step Cooking Mode ("Cook Mode")
* Full-screen, high-contrast cooking walkthrough designed for kitchen counters.
* Step counter (`Step X of Y`) with animated progress bar.
* Oversized text and bold typography for readability from a distance.
* Built-in floating step timer with Start/Pause/Reset controls.
* Completion celebration screen upon finishing all recipe steps.

### 4. Background Kitchen Timer & System Notifications
* Monospaced countdown timer directly inside the recipe detail screen.
* Integrates with Apple's `UserNotifications` framework (`UNUserNotificationCenter`) to schedule a local alert banner and chime when the countdown finishes—even if the app is backgrounded or the screen is locked.

### 5. Smart Grocery Shopping Checklist
* Dedicated 3rd tab in the primary navigation bar.
* Filter by *All, To Buy,* or *Purchased*.
* Strike-through checkmark toggling for purchased groceries.
* Quick-add bar for custom items (e.g., "Milk", "Eggs").
* Swipe-to-delete support.
* Toolbar options to "Clear Purchased" and "Clear All".
* Formatted text export via iOS `ShareLink` for messaging shopping lists.

### 6. Chef Profile & Stats
* Dedicated Profile section under "My Recipes" featuring customizable chef name, bio, and dietary preference badges.
* Live statistics counters: Total Recipes Created, Saved Favorites, and Grocery Items.
* Edit profile modal sheet to update personal chef identity across all future creations and reposts.

### 7. Form Input Validation & Storage Error Handling
* Form validation engine (`RecipeValidator`) verifies image URL schemes (`http://`, `https://`) and ingredient syntax (`amount | item`).
* Highlights exact offending line numbers in red and disables the Save button until all inputs are valid.
* Defensive `UserDefaults` serialization with `do-catch` recovery; corrupted files safely fall back to sample recipes and surface a modal alert explaining the recovery.

---

## Automated Unit Testing Suite

The project includes an automated test bundle (`RecipeExplorerTests`) with **24 unit tests** covering both ideal operations and non-ideal defensive edge cases:
* **Ideal Conditions:** Sample data loading, adding recipes to top of list, favorites toggle, persistence across launches, deletion of user recipes, attributed reposting, reversible like toggling, adding ingredients to grocery list, grocery purchased toggle, clearing purchased items, grocery persistence, ingredient checklist persistence, and user profile updates.
* **Non-Ideal Conditions:** Sample recipe deletion protection, rating clamping (1–5 stars), rejection of blank/whitespace grocery items, fallback to default chef name on blank input, corrupted recipe JSON recovery, corrupted grocery JSON recovery, rejection of invalid image URLs, and reporting malformed ingredient line numbers.
