# 🍳 Recipe Explorer

A modern, responsive web application designed for food lovers to discover, search, and cook gourmet dishes. Built collaboratively by Team Recipe Explorer as part of our Software Engineering Semester Project.

---

## 👥 Team Information
* **Team Name:** Recipe Explorer
* **Current Scrum Master:** **Ahmad Harb**
* **Team Members & Core Responsibilities:**
  * **Ahmad Harb** (25%) – Scrum Master, Architecture Lead, Application Logic & Component Integration
  * **Insung** (25%) – UI/UX Design System, Recipe Browsing Card Layouts, Detail View Wireframes
  * **Tylor** (25%) – Recipe Data Models, Seed Datasets, Search & Filter Specifications
  * **Vedanth** (25%) – User Personas, App Navigation Routing, Authentication Form Layouts

---

## 🚀 Key Features Implemented (Current Sprint Check-In)

1. **Recipe Catalog & Browsing Feed:**
   * Dynamic rendering of recipe cards with high-resolution imagery, prep/cook times, difficulty ratings, and cuisine tags.
   * Responsive layout optimized for mobile, tablet, and desktop viewports.

2. **Real-time Search & Multi-Criteria Filtering:**
   * Instant search by recipe title, cuisine, description, and individual ingredients.
   * Quick-tap trending ingredient chips (Garlic, Chicken, Avocado, Basil, Eggs) for pantry-based discovery.
   * Category tabs: All, Breakfast, Lunch, Dinner, Vegetarian, Quick & Easy.
   * Sorting by Featured, Highest Rated, and Quickest Cook Time.

3. **Dynamic Recipe Detail View (Modal):**
   * High-definition recipe hero banner with author attribution and dietary tags.
   * Detailed nutritional stats: Prep time, cook time, servings, and calories.
   * **Interactive Ingredients Checklist:** Real-time strikethrough checkboxes as users prep ingredients.
   * Step-by-step instructions.
   * **Interactive Kitchen Cook Timer:** In-app countdown timer to keep track of cooking steps with pause/resume and alerts.

4. **Favorites / Bookmarking System:**
   * One-click save to favorites with persistence across sessions via `localStorage`.
   * Real-time favorites counter in the navigation bar and dedicated filter tab.

5. **User Recipe Posting:**
   * Functional modal form to submit new recipes with ingredient lists, custom cooking steps, prep times, and image URLs.
   * Instantly prepends new recipes to the feed and persists in local storage.

---

## 🛠️ Tech Stack & Architecture
* **Frontend:** HTML5 (Semantic), Vanilla CSS3 (Custom Design System with CSS variables, modern typography via Google Fonts Outfit & Plus Jakarta Sans), Modern JavaScript (ES Modules).
* **Storage:** Client-side persistence using `localStorage`.
* **Zero Dependencies:** Runs natively in any modern web browser without build configurations or external bundling.

---

## 💻 How to Run Locally

You can run this project with any local HTTP server:

```bash
# Clone the repository
git clone <repository-url>
cd recipe-explorer

# Option 1: Python HTTP server
python3 -m http.server 8000

# Option 2: Node npx serve
npx serve .
```

Open your browser and navigate to `http://localhost:8000`.

---

## 📋 Scrum Backlog Summary (Scrum.org Standards)

| Status | Items |
| :--- | :--- |
| **Done** (Working Code) | Project charter, User personas, Wireframes, Recipe data model, Seed dataset, Browsing grid, Detail modal view, Client-side search, Favorites persistence, Kitchen timer |
| **In Progress** | Advanced multi-ingredient pantry query, User registration/auth backend mock, Edit/delete submitted recipes |
| **To Do (Next Sprint)** | Meal planner & shopping list generator, User review/rating submission system, Backend database integration |

© 2026 Team Recipe Explorer. All rights reserved.
