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

### Sharing recipes between users (optional server)

The Community tab works out of the box with an **on-device demo feed** (a few read-only recipes from sample authors plus anything you publish). To share recipes between real users, run the included community server (Python 3.9+, standard library only):

```bash
cd community-server
python3 server.py                 # http://127.0.0.1:8080, data saved to community-data.json
python3 server.py --host 0.0.0.0  # also reachable from iPhones on the same Wi-Fi
```

Then in the app: **Community tab → gear icon → Community server**, enter `http://127.0.0.1:8080` (Simulator) or `http://<your-Mac's-IP>:8080` (physical iPhone), and tap Save. To demo two users, run the app on two different simulators pointed at the same server: each install has its own author identity.

Server tests: `cd community-server && python3 test_server.py`

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

### 8. Community Publishing & Author-Owned Editing
* **Publish to Community** from any of your recipes' detail screens; other users browse it in the new **Community** tab (search by title, author, tag, or ingredient; filter to "Published by Me"; pull to refresh).
* **Author-only controls**: only the recipe's author sees Edit, Unpublish, and Delete. Everyone else sees "Only the author can edit or delete it" and can **Save a Copy** to their own My Recipes.
* **Edits sync**: editing a published recipe updates the community copy too; deleting a published recipe removes it from the feed for everyone. **Unpublish** removes it from the feed but keeps it in My Recipes.
* **Ownership is enforced by the backend, not just the UI**: each install has a stable author ID (separate from the editable chef name) and a private token. The server and the on-device feed both reject edits/deletes whose author ID or token doesn't match the recipe's owner.
* **Privacy**: your likes, dislikes, and personal star rating are stripped before a recipe is shared.
* "Published" badges and a Published count appear in the Chef Profile; badges re-sync with the feed on every refresh.
* Existing recipes saved before this feature are automatically owned by the install that created them.

> Limitation: the author token works on a trust-on-first-use basis. It stops other users from changing your recipes, but it isn't a full account system: reinstalling the app creates a new identity, and the server should only run on a trusted network or behind HTTPS.

---

## Automated Unit Testing Suite

The project includes an automated test bundle (`RecipeExplorerTests`) with **41 unit tests** covering both ideal operations and non-ideal defensive edge cases:
* **Ideal Conditions:** Sample data loading, adding recipes to top of list, favorites toggle, persistence across launches, deletion of user recipes, attributed reposting, reversible like toggling, adding ingredients to grocery list, grocery purchased toggle, clearing purchased items, grocery persistence, ingredient checklist persistence, and user profile updates.
* **Non-Ideal Conditions:** Sample recipe deletion protection, rating clamping (1–5 stars), rejection of blank/whitespace grocery items, fallback to default chef name on blank input, corrupted recipe JSON recovery, corrupted grocery JSON recovery, rejection of invalid image URLs, and reporting malformed ingredient line numbers.
* **Community Publishing (`CommunityPublishingTests`, 17 tests):** two stores ("Alice" and "Bob") with separate storage share one community service to simulate two users. *Ideal:* published recipes are visible to other users, only the author can modify, author edits reach everyone (publish date kept), delete removes everywhere, unpublish keeps the local copy, saving someone else's recipe makes a private owned copy, ownership survives renaming and relaunch. *Non-ideal:* another user can't edit or delete, the service rejects a forged author ID, personal data is stripped, samples can't be published, double-publishing is rejected, legacy recipes are migrated, badges clear when a recipe leaves the feed, seeded community recipes are read-only, and invalid server addresses are rejected.
* **Community Server (`community-server/test_server.py`, 17 tests):** runs the real HTTP server and checks publishing, browsing, author-only PUT/DELETE (403 for others and for forged IDs), 401 without credentials, 409 duplicates, 404s, malformed-recipe rejection, persistence across restarts, and that only a hash of each token is stored.
