# Recipe Explorer — native iOS app (SwiftUI)

This is a **native SwiftUI implementation**, not a web view or wrapper, based on Recipe Explorer Deliverables 1/2 and the public team's web prototype (https://github.com/Abu7arb111/ecipe-explorer).

## Run on a Mac with Xcode

1. Open `RecipeExplorer.xcodeproj` from this archive using Xcode.
2. Under the `RecipeExplorer` target's **Signing & Capabilities**, select your Personal Team if Xcode asks for one.
3. Pick an installed iPhone simulator (e.g. iPhone 17), and press **Run** (Cmd+R).
4. Deployment target: **iOS 17.0+**. No packages, API keys, or back-end required.

If Xcode cannot open the included project for any reason, create a new **iOS App** project named RecipeExplorer, choose **SwiftUI / Swift**, and drag the nine files in the `RecipeExplorer/` folder into the app target, replacing its generated App and ContentView files.

## Features implemented in source

- Native two-column recipe feed, category chips, ratings, sort, search by recipe name and ingredients
- Detail screens with ingredients checklist, instructions, countdown timer, bookmark button, share sheet
- Favorites and added recipes persisted across launches using UserDefaults + Codable
- Add recipe form; locally submitted recipes appear in feed and My Recipes
- Edit/delete locally created recipes; reversible like/dislike reactions and personal 1–5-star ratings
- Repost a recipe into My Recipes with attribution to its original creator (local-only)
- Six starter recipes adapted from the team's web prototype

## Important scope notes

- **No user accounts, remote database, or cross-device syncing**; the identity is a local placeholder (`You`).
- Ratings and reactions are local-only; they are not shared with other users.
- Recipe images load over the network from the web prototype's Unsplash URLs; placeholder is shown offline.
- Timer counts down only while the detail view is actively in use; it does not schedule system notifications.
- Created recipes are stored locally, not published to other users.
- The source has **not been compiled in Xcode in this environment**. Run and test on a Mac before claiming it is working in a graded sprint backlog.

## Quick manual test checklist

1. Explore shows six recipes and cards navigate to details.
2. Searching `garlic` finds recipes with garlic in the title/ingredients.
3. Category `Breakfast` narrows results; sort changes order.
4. Tap a heart, restart app, find recipe under Favorites.
5. In detail, tap ingredients; start, pause, reset cooking timer.
6. Add a recipe, confirm it appears in Explore and My Recipes, then edit and delete it.
7. Rate recipe, tap like/dislike twice and confirm the reaction toggles instead of repeatedly increasing the count.
8. Repost a sample recipe, confirm an attributed copy appears in My Recipes, then delete the copy.

Project members: Ahmad Harb, Insung, Tylor, Vedanth. Scrum Master for current check-in: Ahmad Harb. Contributions reported as 25% each; verify with the team.

## Deliverable 2 alignment

The existing Recipe.swift, SampleRecipes.swift, RecipeFeedView.swift, RecipeDetailView.swift and ContentView.swift roles remain intact. The new RecipeStore centralizes local data changes; RecipeFormView supports creation and editing. This is an expanded SwiftUI implementation aligned with the Deliverable 1/2 user stories, not a claim of line-for-line reuse of the earlier code.

Original goals covered: browsing, categories, search, details, creation, favorites, ratings, likes/dislikes, editing/deleting and reposting. Account authentication, comments/reviews, and a shared online feed are still future scope.
