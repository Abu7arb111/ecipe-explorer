# Recipe Explorer — Native iOS App (SwiftUI)

**Course:** CS 3714 — Mobile Application Development (iOS), Virginia Tech  
**Instructor:** Dr. Kirsten Richards  
**Team Name:** Recipe Explorer  
**GitHub Repository:** [https://github.com/Abu7arb111/ecipe-explorer](https://github.com/Abu7arb111/ecipe-explorer)  

### Team Roster & Roles
* **Ahmad Harb** (`ahmadalharb1987@vt.edu`) — Recipe Sharing & Community System Lead, REST Backend Architecture, Token-Based Ownership Security
* **Vedanth Subramanian** (`vedanths@vt.edu`) — Input Validation Engine, Automated Unit Testing Suite, Defensive Storage Error Recovery
* **Tylor Newcomb** (`tnewcomb@vt.edu`) — Data Architecture & Models, Dietary Tag Filtering, Smart Grocery List Aggregator
* **Insung** — UI/UX Lead, Hands-Free Cook Mode, Interactive Recipe Detail, Kitchen Timer & Local Notifications

---

## One-Click Execution & Setup Instructions

The project is configured for **immediate, zero-configuration one-click execution** in Xcode:

1. **Open the Project:**
   Double-click `RecipeExplorer.xcodeproj` to open it in Xcode.
2. **Select Destination:**
   In the Xcode toolbar scheme selector (top bar), choose any iOS Simulator (e.g., **iPhone 16**, **iPhone 17**, or **iPhone 15 Pro** running iOS 17.0+).
3. **Run the App (Cmd + R):**
   Click the **Play / Run** button or press **⌘R**.
   * *Zero Configuration:* No manual modifications to Development Team, Apple ID signing, or Bundle Identifiers are required for Simulator execution.
   * *Zero Dependencies:* No CocoaPods, Carthage, or third-party Swift Packages are required—the application is 100% native SwiftUI and standard Foundation/Combine frameworks.
4. **Run Unit Tests (Cmd + U):**
   Press **⌘U** to run all **41 automated unit tests** in `RecipeExplorerTests`.

---

## Community Recipe Sharing (Optional Server)

Recipe Explorer includes a complete **Community Publishing & Sharing System**:
* **Out-of-the-box (Offline Demo Feed):** Works immediately with no external setup. The Community tab displays pre-seeded community recipes and any recipes you publish locally.
* **Multi-User Real-Time Sharing (LAN / Local Server):** To share recipes between different physical devices or simulators, run the lightweight companion server included in `community-server/` (requires standard Python 3.9+, standard library only):

```bash
cd community-server
python3 server.py                 # Runs at http://127.0.0.1:8080 (Simulator)
python3 server.py --host 0.0.0.0  # Reachable from physical iPhones on the same Wi-Fi
```

In the app:
1. Navigate to the **Community** tab.
2. Tap the **Gear Icon** in the top navigation bar.
3. Enter `http://127.0.0.1:8080` (for Simulator) or `http://<your-Mac's-IP>:8080` (for physical device) and tap **Save**.
4. To test multi-user interaction, launch two different simulators: each installation generates a unique author identity and token, allowing independent publishing, editing, and copying.

To run the automated server test suite:
```bash
cd community-server
python3 test_server.py
```

---

## Feature Overview (100% Complete)

### 1. Recipe Browsing & Multi-Criteria Search
* Responsive two-column adaptive grid feed with high-resolution imagery and visual rating badges.
* Category filter chips: *All, Breakfast, Lunch, Dinner, Vegetarian, Quick & Easy*.
* **Dietary Tag Filtering**: Real-time filtering by *Vegetarian, Vegan, Gluten-Free, High Protein, Quick & Easy*.
* Deep search engine indexing recipe titles, descriptions, cuisines, dietary tags, and ingredient lists.
* Sorting selector: *Featured, Highest Rated, Quickest*.

### 2. Interactive Recipe Detail Experience
* Hero imagery with asynchronous loading and offline fallback placeholders.
* Interactive ingredient checklist with **persistent session checkmarks** saved across app restarts.
* **One-Tap Grocery List Export**: Bulk-adds all recipe ingredients directly into the Smart Grocery List.
* Interactive 1–5 star personal rating selector.
* Reversible thumbs up / thumbs down reaction counters preventing artificial count inflation.
* Social reposting: Clones recipes into "My Recipes" with credited author attribution.

### 3. Hands-Free Step-by-Step Cooking Mode ("Cook Mode")
* Full-screen, high-contrast cooking walkthrough optimized for kitchen counter use.
* Step indicator (`Step X of Y`) with animated progress bar.
* Oversized typography for easy readability from a distance.
* Built-in floating step timer with Start, Pause, and Reset controls.
* Interactive step checklist and completion celebration screen upon finishing all recipe steps.

### 4. Background Kitchen Timer & System Notifications
* Monospaced countdown timer directly embedded in the recipe detail screen.
* Integrates with Apple's `UserNotifications` framework (`UNUserNotificationCenter`) to schedule a local alert banner and chime when the countdown finishes—even if the app is backgrounded or the device is locked.

### 5. Smart Grocery Shopping Checklist
* Dedicated tab in primary navigation hierarchy.
* Filter views by *All, To Buy,* or *Purchased*.
* Interactive strike-through checkmark toggling for purchased items.
* Quick-add input bar for custom items (e.g., "Milk", "Eggs").
* Swipe-to-delete support and toolbar actions to "Clear Purchased" and "Clear All".
* Formatted text export via iOS `ShareLink` for messaging shopping lists.

### 6. Chef Profile & Stats
* Dedicated Profile section under "My Recipes" featuring customizable chef name, bio, and dietary preference badges.
* Live statistics counters: Total Recipes Created, Saved Favorites, and Grocery Items.
* Edit profile modal sheet to update personal chef identity across all future creations and reposts.

### 7. Form Input Validation & Storage Error Handling
* Form validation engine (`RecipeValidator`) verifies image URL schemes (`http://`, `https://`) and ingredient syntax (`amount | item`).
* Highlights exact offending line numbers in red and disables the Save button until all inputs are valid.
* Defensive `UserDefaults` serialization with `do-catch` recovery; corrupted files safely fall back to sample recipes and surface a modal alert explaining the recovery.

### 8. Community Publishing & Author-Owned Editing
* **Publish to Community**: Authors can publish custom recipes from the detail screen to the community feed.
* **Author-Only Permissions**: Only the recipe's original author can edit, unpublish, or delete a published recipe. Other users see an ownership notice and can "Save a Copy" to their personal collection.
* **Ownership Security**: Enforced on the backend using stable UUID author IDs and private authentication tokens. Both the server and local actor reject unauthorized modification or deletion attempts.
* **Privacy by Design**: Personal reactions (likes/dislikes) and individual star ratings are automatically stripped before recipes are published to the community.

---

## Known Issues and Limitations

In accordance with course documentation requirements, the following known limitations are noted:

1. **Local Simulator Notification Permissions:**
   * On certain fresh iOS Simulator instances, Apple's `UNUserNotificationCenter` permission prompt may occasionally appear behind active modal sheets. If background timer notifications do not sound in the Simulator, verify that notifications are enabled under Simulator *Settings → Notifications → RecipeExplorer*.
2. **Community Server Trust-On-First-Use Identity:**
   * The companion community sharing backend utilizes a lightweight, token-based trust-on-first-use authentication model rather than a heavy enterprise identity provider (like OAuth or Firebase Auth). Reinstalling the app generates a new UUID author identity.
3. **Image Loading Dependent on Remote Connectivity:**
   * Recipe images load asynchronously via Apple's `AsyncImage`. When offline or without active internet, the app gracefully falls back to themed SF Symbol category placeholders (`fork.knife`, `carrot.fill`, etc.).
4. **Interface Orientation:**
   * The application is optimized for portrait orientation on iPhone devices to maintain a clean single-hand mobile UX, though Cook Mode provides high-contrast full-screen typography adaptable to larger screens.

---

## Automated Unit Testing Suite

The project includes an automated test bundle (`RecipeExplorerTests`) with **41 unit tests** covering both ideal operations and non-ideal defensive edge cases:
* **Ideal Conditions:** Sample data loading, adding recipes to top of list, favorites toggle, persistence across launches, deletion of user recipes, attributed reposting, reversible like toggling, adding ingredients to grocery list, grocery purchased toggle, clearing purchased items, grocery persistence, ingredient checklist persistence, and user profile updates.
* **Non-Ideal Conditions:** Sample recipe deletion protection, rating clamping (1–5 stars), rejection of blank/whitespace grocery items, fallback to default chef name on blank input, corrupted recipe JSON recovery, corrupted grocery JSON recovery, rejection of invalid image URLs, and reporting malformed ingredient line numbers.
* **Community Publishing (`CommunityPublishingTests`, 17 tests):** two stores ("Alice" and "Bob") with separate storage share one community service to simulate two users. *Ideal:* published recipes are visible to other users, only the author can modify, author edits reach everyone (publish date kept), delete removes everywhere, unpublish keeps the local copy, saving someone else's recipe makes a private owned copy, ownership survives renaming and relaunch. *Non-ideal:* another user can't edit or delete, the service rejects a forged author ID, personal data is stripped, samples can't be published, double-publishing is rejected, legacy recipes are migrated, badges clear when a recipe leaves the feed, seeded community recipes are read-only, and invalid server addresses are rejected.
* **Community Server (`community-server/test_server.py`, 17 tests):** runs the real HTTP server and checks publishing, browsing, author-only PUT/DELETE (403 for others and for forged IDs), 401 without credentials, 409 duplicates, 404s, malformed-recipe rejection, persistence across restarts, and that only a hash of each token is stored.
