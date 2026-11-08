# CS 374 — Sprint 4 Check-In / Deliverable 4
**Project Name:** Recipe Explorer  
**Repository:** [https://github.com/Abu7arb111/ecipe-explorer](https://github.com/Abu7arb111/ecipe-explorer)  
**Date:** November 8, 2026  
**Target Completion Status:** ~75% Complete (3/4 Finished)

---

## 1. Team Information & Roles

* **Team Name:** Recipe Explorer
* **Course:** CS 374
* **Team Members:**
  * **Ahmad Harb** (Developer / Scrum Master in Sprint 3)
  * **Vedanth Subramanian** (**Current Scrum Master for Sprint 4** / Testing & Validation Lead)
  * **Tylor Newcomb** (Data Architecture & Model Lead / Upcoming Scrum Master for Sprint 5)
  * **Insung** (UI/UX & Interactive Design Lead / Sprint 1–2 Lead)

### Scrum Master Rotation Schedule
To ensure every student serves as Scrum Master exactly once during the project lifecycle, our team rotates leadership each sprint:
1. **Sprints 1 & 2:** Insung (Initial product scoping, wireframing, and web prototype foundations)
2. **Sprint 3:** Ahmad Harb (SwiftUI architectural transition, repository coordination, core store setup)
3. **Sprint 4 (Current Check-In): Vedanth Subramanian** (Quality assurance, automated unit test framework, error handling, and input validation)
4. **Sprint 5 (Final Deliverable): Tylor Newcomb** (Final integration, end-to-end testing, feature freeze, and presentation)

---

## 2. Sprint Backlog (Scrum.org Format)

### Sprint 4 Goal
> *"Achieve approximately 75% project completion by hardening the application against invalid inputs and data corruption, implementing automated unit testing in Xcode, delivering complete recipe CRUD operations (create, edit, delete), and providing interactive user engagement features (reactions, ratings, reposts)."*

### Backlog Task Status Board

| Status | User Story / Task Item | Assigned Lead | Verification / Acceptance Criteria |
| :--- | :--- | :--- | :--- |
| **Done** | **Form Input Validation Engine** (`RecipeValidation.swift`) | Vedanth | Validate HTTP/HTTPS image URLs, enforce `amount \| item` format on ingredient lines, flag exact line errors, block Save button until valid. |
| **Done** | **Automated Unit Test Target** (`RecipeExplorerTests`) | Vedanth | 15 passing XCTest unit tests covering ideal conditions (add, favorite, persist, repost, likes) and non-ideal conditions (bad URLs, malformed ingredients, clamped ratings, corrupted data). |
| **Done** | **Storage Error Handling & Fallbacks** (`RecipeStore.swift`) | Vedanth | Catch JSON decode/encode errors; fall back gracefully to `SampleRecipes`; surface user-facing alert via `@Published var storageError` in `ContentView`. |
| **Done** | **Recipe Creation & Editing Interface** (`RecipeFormView.swift`) | Ahmad / Vedanth | Multi-section form supporting title, summary, cuisine, category picker, bounded steppers for prep/cook/servings, and multi-line ingredient/instruction parsing. |
| **Done** | **Local Recipe Deletion & Re-editing** | Ahmad | Prevent deletion of built-in sample recipes; allow full edit/delete lifecycle for user-created recipes with instant UI updates. |
| **Done** | **Interactive User Reactions (Likes/Dislikes)** | Insung / Tylor | Reversible toggle logic for thumbs up/down; prevents artificial counter inflation; state persists locally per recipe. |
| **Done** | **Personal Star Rating System (1–5 Stars)** | Insung / Vedanth | Interactive 5-star rating selector on detail view; bound and clamped between 1 and 5 stars. |
| **Done** | **Attributed Recipe Reposting** (`RecipeStore.repost`) | Ahmad / Tylor | Duplicate any recipe into "My Recipes" with credited "Repost: [Title]" heading, "You" as author, and reset reactions. |
| **Done** | **Native SwiftUI Migration & Navigation** | Team | Converted project from web prototype into a multi-tab iOS 17 native application (Explore, Favorites, My Recipes). |
| **In Progress** | **Ingredient Checklist Session Caching** | Insung | Persisting tapped ingredient checklist checkmarks in `RecipeDetailView` across screen transitions. |
| **In Progress** | **Smart Grocery List Aggregator** | Tylor / Ahmad | Compiling checked ingredients from multiple recipes into a unified shopping checklist. |
| **In Progress** | **Dietary Tag Filtering Presets** | Tylor | Expanding category chips to filter by dietary tags (e.g., Vegan, Vegetarian, Gluten-Free, Keto). |
| **In Progress** | **Background Kitchen Timer Notifications** | Insung | Supporting system-level audio/banners when the cooking countdown completes while the app is in the background. |
| **To Do** | **Cloud Backend / Remote Syncing** | Team | Transitioning from local-only `UserDefaults` storage to a shared cloud database / REST API for multi-user feed sharing. |
| **To Do** | **User Profile & Authentication Modal** | Vedanth / Ahmad | Login, sign-up, and avatar customization for public author profiles. |
| **To Do** | **Hands-Free Cooking Mode** | Insung | Full-screen landscape step-by-step cooking guide with high-contrast text and oversized step buttons. |
| **To Do** | **End-to-End Regression & Accessibility Audit** | Team | Dynamic Type sizing verification, VoiceOver label audits, and final submission packaging for Deliverable 5. |

---

## 3. Goals for the Next Backlog (Sprint 5 / Final Deliverable)

For our upcoming sprint leading into the final deliverable, our primary goals focus on completing the final 25% of the project and hardening it for production:
1. **Smart Grocery Checklist Export:** Build a dedicated Grocery tab or export sheet that aggregates checked ingredients from favorited or planned recipes, grouping like items together.
2. **Dietary Tag & Multi-Pantry Search:** Enhance the search engine in `RecipeFeedView` so users can filter by multiple simultaneous criteria (e.g., "Dinner" + "Gluten-Free" + contains "Garlic").
3. **Background Cooking Timer Alerts:** Integrate `UserNotifications` framework so the kitchen timer alerts the user even if they switch apps or lock their device.
4. **Cloud / API Integration Architecture:** Formalize the remote data contract for cross-device recipe sharing and sync.
5. **Final UI/UX Polish & Accessibility:** Ensure all buttons have explicit `.accessibilityLabel` modifiers, high-contrast support, and seamless responsiveness across all iPhone screen sizes and iPad multitasking.

---

## 4. Code Progress Summary (Sprint 3 vs. Sprint 4)

### Quantitative & Qualitative Code Growth
Since Sprint 3, our codebase has advanced from early architectural groundwork to a feature-complete native SwiftUI iOS app:
* **Repository:** [https://github.com/Abu7arb111/ecipe-explorer](https://github.com/Abu7arb111/ecipe-explorer)
* **Recent Commits:**
  * `1f0b460` — *Add input validation, storage error handling, and unit tests* (Vedanth)
  * `309026b` — *updated project to swift ui* (Tylor)
  * `b457256` — *feat: initial commit for Recipe Explorer sprint check-in* (Ahmad)
* **Lines of Swift Code Added:** Over **1,500 lines** of production Swift code across 11 files, plus an Xcode test target with 15 automated test cases.
* **Key Components Implemented:**
  1. `RecipeValidation.swift`: Dedicated validation enum with pure functions (`isValidImageURL`, `malformedIngredientLines`, `parseIngredients`, `parseInstructions`).
  2. `RecipeStore.swift`: Complete reactive data store using Combine (`ObservableObject`, `@Published`), handling CRUD operations, favorites, likes/dislikes toggling, star rating clamping, recipe duplication/reposting, and safe `UserDefaults` serialization.
  3. `RecipeFormView.swift`: Creation and edit screen featuring real-time input validation, inline error messaging, and defensive UI state (`.disabled(!valid)`).
  4. `RecipeDetailView.swift`: Interactive detail view with kitchen countdown timer (`Combine.Timer`), interactive ingredient strike-through checklist, rating selector, and repost actions.
  5. `RecipeFeedView.swift`: Real-time multi-term search query parser, category capsule filters, and sort options ("Featured", "Highest Rated", "Quickest").
  6. `ContentView.swift`: Tab navigation hierarchy and centralized storage alert presentation.
  7. `RecipeExplorerTests.swift`: Comprehensive XCTest test suite.

---

## 5. Testing Plan

### 5.1 How We Test
Our testing approach follows a multi-tiered quality assurance strategy:
1. **Automated Unit Testing (XCTest):** We utilize an independent test bundle (`RecipeExplorerTests`) integrated with `RecipeExplorer.xctestplan`. Tests run against an isolated in-memory `UserDefaults` suite (`RecipeExplorerTests-[UUID]`) instantiated in `setUp()` and torn down in `tearDown()` to guarantee zero side effects on production data.
2. **Interactive UI / Component Testing:** Exercised through SwiftUI Previews in Xcode for rapid layout and responsive verification across light and dark modes.
3. **Manual Scenario Testing:** Executed against physical devices and iOS Simulators (iPhone 16 / iPhone 17) following an 8-point manual test protocol (testing CRUD, navigation, timers, and storage persistence).

---

### 5.2 What We Test: Ideal vs. Non-Ideal Conditions

Our test suite explicitly validates both expected user behavior and defensive failure modes:

| Test Category | Target / Condition | Expected Behavior under Test | Automated Test Case / Verification |
| :--- | :--- | :--- | :--- |
| **Ideal** | First app launch | Automatically loads default catalog (`SampleRecipes.all`) with no errors. | `testFirstLaunchLoadsSampleRecipes` |
| **Ideal** | Adding a recipe | Newly created recipe is inserted at the front of the feed and displays in "My Recipes". | `testAddInsertsRecipeAtFront` |
| **Ideal** | Toggling favorites | First tap adds recipe UUID to `favorites` set; second tap removes it cleanly. | `testToggleFavoriteOnAndOff` |
| **Ideal** | Data persistence | Relaunching the app with existing storage reloads all custom recipes and favorite IDs. | `testDataPersistsAcrossLaunches` |
| **Ideal** | Recipe deletion | User-created recipes are cleanly removed from both the feed and favorites. | `testDeleteRemovesUserRecipe` |
| **Ideal** | Reposting recipe | Clones recipe into "My Recipes" attributed to "You" with "Repost: " prefix and fresh reactions. | `testRepostCreatesAttributedCopy` |
| **Ideal** | Reaction toggle | Tapping "Like" increments count; tapping again removes like without inflating counts. | `testLikeTogglesInsteadOfInflating` |
| **Ideal** | Valid Image URL | Accepts well-formed `https://` or `http://` URLs with valid domains. | `testValidImageURL` |
| **Ideal** | Optional Image URL | Blank / empty image URL string is accepted without error. | `testEmptyImageURLIsAllowed` |
| **Ideal** | Well-formed ingredients | Text formatted as `amount \| item` (e.g., `2 cups \| Flour`) parses with zero errors. | `testWellFormedIngredientsHaveNoBadLines` |
| **Non-Ideal** | Invalid Image URLs | Reject strings without protocol, non-HTTP schemes (e.g., `ftp://`), or missing domains (e.g., `http://`). | `testInvalidImageURLs` |
| **Non-Ideal** | Malformed ingredients | Flags exact line numbers lacking the `\|` delimiter, missing quantities, or missing ingredient names. | `testMalformedIngredientLinesAreReported` |
| **Non-Ideal** | Rating out of bounds | Any rating $< 1$ or $> 5$ (e.g., $99$ or $-3$) is safely clamped between 1 and 5 stars. | `testRatingIsClampedToOneThroughFive` |
| **Non-Ideal** | Sample recipe protection | Attempting to delete built-in system sample recipes is rejected; store remains intact. | `testSampleRecipesCannotBeDeleted` |
| **Non-Ideal** | Corrupted stored data | If `UserDefaults` contains unparseable binary/JSON, app catches error, loads sample data, and triggers alert. | `testCorruptedSavedRecipesFallBackToSamplesAndReportError` |

---

### 5.3 Handling Edge Cases & System Failures

#### 1. Incorrect / Bad User Input
* **Bad Image URLs:** Validated by `RecipeValidator.isValidImageURL`. If invalid, an inline red warning is displayed in `RecipeFormView`, and the **Save** button is disabled (`.disabled(!valid)`).
* **Malformed Ingredient Lines:** Validated by `RecipeValidator.malformedIngredientLines`. The UI displays specific line-level errors (e.g., *"Line 2, 4: use the format amount | ingredient (example: 2 cups | Flour)"*) and blocks form submission until corrected.
* **Invalid Numeric Inputs (Prep/Cook Time, Servings):** Handled defensively by using bounded SwiftUI `Stepper` components (Prep: 0–240 min, Cook: 0–600 min, Servings: 1–30), completely eliminating crashes from non-numeric strings or negative integers.
* **Empty Form Fields:** Title, ingredients, and instructions are trimmed of whitespace and required before `valid` returns true.

#### 2. Unreachable API / Network Failures
* **Image Loading:** Recipes use `RecipeImageView`, wrapping SwiftUI's `AsyncImage`. If an image URL is broken, times out, or the device is offline, it gracefully falls back to a custom tinted placeholder icon (`fork.knife`) rather than leaving a blank gap or crashing.
* **Local-First Architecture:** The core app relies on local `UserDefaults` persistence with `Codable` structs, ensuring complete offline usability without requiring an active network connection for browsing, editing, or favoriting.

#### 3. Storage Corruption / Save Failures
* In `RecipeStore.init`, JSON decoding is wrapped in defensive `do-catch` blocks.
* If saved data cannot be decoded (e.g., corrupted storage or schema mismatch), the app safely resets to `SampleRecipes.all`, resets favorites, and populates `@Published var storageError`.
* `ContentView` binds directly to `storageError` using `.alert("Storage problem", isPresented: ...)`, presenting an immediate, human-readable alert explaining that sample recipes were loaded and preventing silent data loss.

---

## 6. Team Work Statement & Contributions

### Contribution Percentage Breakdown (Total: 100%)

| Team Member | Contribution % | Primary Responsibilities & Sprint 4 Deliverables |
| :--- | :---: | :--- |
| **Vedanth Subramanian** | **25%** | **Current Scrum Master & Testing Lead:** Implemented input validation engine (`RecipeValidation.swift`), built comprehensive 15-test automated unit test suite (`RecipeExplorerTests.swift`), added error handling for corrupted storage with SwiftUI alert alerts in `RecipeStore`, and led quality assurance for Sprint 4. |
| **Ahmad Harb** | **25%** | **Full-Stack & Architecture Lead (Sprint 3 Scrum Master):** Coordinated repository integration, managed GitHub version control, refined recipe creation/editing workflows (`RecipeFormView`), implemented recipe feed search/sorting filters, and authored sprint documentation. |
| **Tylor Newcomb** | **25%** | **Data Architecture & Model Lead:** Led the native SwiftUI data modeling (`Recipe.swift`, `Ingredient`), engineered backward-compatible `Codable` serialization/deserialization keys, expanded the sample recipe catalog (`SampleRecipes.swift`), and drafted Sprint 5 grocery export architecture. |
| **Insung** | **25%** | **UI/UX & Interactive Design Lead:** Polished the mobile user experience, implemented the interactive kitchen countdown timer component in `RecipeDetailView`, styled category pills and grid layouts, designed star rating UI, and crafted visual state styling. |

### Team Dynamics & Coordination
* **Even Distribution of Work:** Each team member contributed exactly 25% of the overall effort, balancing backend logic, UI design, validation, and testing.
* **Coordination & Communication:** Team communication took place actively via group messaging and GitHub pull requests. When team members encountered busy schedules (such as Vedanth having limited availability during the final write-up window), the workload was proactively divided: Vedanth implemented and committed the complete code enhancements and 15 passing tests ahead of time, allowing Ahmad and the team to complete the documentation synthesis, verify repository integrity, and finalize the submission report.
* **Team Issues:** There are no team issues, blockers, or interpersonal conflicts. All four members are fully engaged, aligned with their assigned tasks, and on track to deliver the final product for Sprint 5.

---

## 7. Current Project Completion Status
* **Estimated Completion:** **~75% finished** (Right on target for the Sprint 4 milestone).
* **Completed Milestones:** Core navigation, recipe browsing, search, favorites persistence, full local CRUD pipeline, input validation, defensive storage error recovery, reversible reactions, 1–5 star ratings, attributed reposting, kitchen countdown timer, and automated unit test suite.
* **Remaining Milestones (Sprint 5):** Smart grocery checklist export, dietary preset filters, background timer notifications, and final deployment polish.

