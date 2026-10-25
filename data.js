/**
 * Recipe Explorer - Core Data Models and Seed Dataset
 * Team: Recipe Explorer (Ahmad Harb, Insung, Tylor, Vedanth)
 */

export const INITIAL_RECIPES = [
  {
    id: "rec-001",
    title: "Creamy Tuscan Garlic Chicken",
    description: "Tender chicken breasts smothered in a rich, velvety garlic parmesan cream sauce loaded with spinach and sun-dried tomatoes.",
    category: "Dinner",
    cuisine: "Italian",
    prepTime: 15,
    cookTime: 20,
    servings: 4,
    difficulty: "Medium",
    rating: 4.9,
    reviewsCount: 128,
    calories: 520,
    author: "Chef Ahmad",
    image: "https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?auto=format&fit=crop&w=800&q=80",
    tags: ["High Protein", "Gluten-Free", "Comfort Food"],
    ingredients: [
      { item: "Boneless skinless chicken breasts", amount: "2 large (halved horizontally)" },
      { item: "Olive oil", amount: "2 tbsp" },
      { item: "Minced garlic cloves", amount: "4 cloves" },
      { item: "Sun-dried tomatoes (drained & chopped)", amount: "1/2 cup" },
      { item: "Fresh baby spinach", amount: "2 cups" },
      { item: "Heavy whipping cream", amount: "1 cup" },
      { item: "Grated Parmesan cheese", amount: "1/2 cup" },
      { item: "Italian seasoning, salt & black pepper", amount: "To taste" }
    ],
    instructions: [
      "Season chicken breast cutlets generously with salt, pepper, and Italian herbs.",
      "Heat olive oil in a deep skillet over medium-high heat. Sear chicken 5 minutes per side until golden brown and cooked through (165°F). Remove and set aside.",
      "In the same skillet, reduce heat to medium and sauté minced garlic and sun-dried tomatoes for 1 minute until fragrant.",
      "Pour in heavy cream and chicken broth; bring to a gentle simmer. Whisk in grated Parmesan until smooth and melted.",
      "Add fresh spinach and simmer for 2 minutes until wilted and the sauce slightly thickens.",
      "Return seared chicken to the skillet, spooning sauce over top. Garnish with fresh basil and serve warm."
    ]
  },
  {
    id: "rec-002",
    title: "Artisanal Avocado & Poached Egg Toast",
    description: "Toasted sourdough bread topped with crushed seasoned avocado, perfectly runny poached eggs, crumbled feta, and chili flakes.",
    category: "Breakfast",
    cuisine: "Modern American",
    prepTime: 10,
    cookTime: 5,
    servings: 2,
    difficulty: "Easy",
    rating: 4.8,
    reviewsCount: 94,
    calories: 380,
    author: "Insung",
    image: "https://images.unsplash.com/photo-1525351484163-7529414344d8?auto=format&fit=crop&w=800&q=80",
    tags: ["Vegetarian", "Quick & Easy", "Healthy"],
    ingredients: [
      { item: "Thick sourdough bread slices", amount: "2 slices" },
      { item: "Ripe Hass avocados", amount: "2 medium" },
      { item: "Fresh pasture-raised eggs", amount: "2 eggs" },
      { item: "Lemon juice", amount: "1 tbsp" },
      { item: "Crumbled feta cheese", amount: "2 tbsp" },
      { item: "Red pepper flakes & microgreens", amount: "Pinch" },
      { item: "Flaky sea salt & olive oil", amount: "To taste" }
    ],
    instructions: [
      "Toast sourdough slices until deeply golden and crispy.",
      "In a bowl, coarsely mash avocados with lemon juice, sea salt, black pepper, and a drizzle of olive oil.",
      "Bring a pot of water to a gentle simmer with a splash of white vinegar. Create a whirlpool and gently slip in cracked eggs; poach for 3 minutes for a soft yolk.",
      "Generously spread avocado mash over toasted sourdough.",
      "Top with warm poached eggs, crumbled feta, red pepper flakes, and microgreens."
    ]
  },
  {
    id: "rec-003",
    title: "Spicy Thai Basil Beef (Pad Krapow)",
    description: "A fast, aromatic Thai street food classic featuring ground beef wok-seared with birds eye chili, garlic, sweet soy sauce, and fragrant holy basil.",
    category: "Dinner",
    cuisine: "Thai",
    prepTime: 10,
    cookTime: 10,
    servings: 3,
    difficulty: "Easy",
    rating: 4.95,
    reviewsCount: 210,
    calories: 490,
    author: "Vedanth",
    image: "https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?auto=format&fit=crop&w=800&q=80",
    tags: ["High Protein", "Spicy", "Quick & Easy"],
    ingredients: [
      { item: "Lean ground beef (or minced pork)", amount: "1 lb" },
      { item: "Fresh Thai holy basil (or sweet basil)", amount: "1 cup packed" },
      { item: "Thai bird's eye chilies", amount: "3-4 (sliced)" },
      { item: "Garlic cloves", amount: "5 cloves (crushed)" },
      { item: "Oyster sauce", amount: "2 tbsp" },
      { item: "Soy sauce & dark soy sauce", amount: "1 tbsp each" },
      { item: "Fish sauce & brown sugar", amount: "1 tsp each" },
      { item: "Crispy fried eggs & jasmine rice", amount: "For serving" }
    ],
    instructions: [
      "In a mortar and pestle, coarsely pound garlic and bird's eye chilies.",
      "Heat a wok with 2 tbsp vegetable oil on high heat. Add pounded garlic and chilies; stir-fry for 20 seconds until aromatic.",
      "Add ground beef and break apart quickly with a spatula until browned and sizzled (3-4 minutes).",
      "Stir in oyster sauce, soy sauce, dark soy sauce, fish sauce, and sugar. Toss vigorously on high heat for 1 minute.",
      "Turn off heat, immediately fold in fresh Thai basil leaves until just wilted.",
      "Serve steaming hot over fragrant jasmine rice crowned with a crispy-edged fried egg."
    ]
  },
  {
    id: "rec-004",
    title: "Mediterranean Roasted Chickpea Buddha Bowl",
    description: "Vibrant and nourishing bowl packed with crispy paprika chickpeas, quinoa, crisp cucumbers, cherry tomatoes, pickled onions, and velvety tahini sauce.",
    category: "Lunch",
    cuisine: "Mediterranean",
    prepTime: 15,
    cookTime: 25,
    servings: 2,
    difficulty: "Easy",
    rating: 4.75,
    reviewsCount: 76,
    calories: 440,
    author: "Tylor",
    image: "https://images.unsplash.com/photo-1540420773420-3366772f4999?auto=format&fit=crop&w=800&q=80",
    tags: ["Vegan", "Gluten-Free", "Meal Prep"],
    ingredients: [
      { item: "Canned chickpeas (rinsed & patted dry)", amount: "1 can (15 oz)" },
      { item: "Cooked fluffy quinoa", amount: "1.5 cups" },
      { item: "Persian cucumbers (diced)", amount: "2" },
      { item: "Cherry tomatoes (halved)", amount: "1 cup" },
      { item: "Kalamata olives", amount: "1/4 cup" },
      { item: "Smoked paprika, cumin & garlic powder", amount: "1 tsp each" },
      { item: "Tahini, lemon juice & warm water", amount: "3 tbsp tahini + 2 tbsp lemon" }
    ],
    instructions: [
      "Preheat oven to 400°F (200°C). Toss dried chickpeas with olive oil, paprika, cumin, garlic powder, and salt.",
      "Spread chickpeas on a baking sheet and roast 25 minutes until crunchy and golden.",
      "Whisk tahini with lemon juice, minced garlic, and warm water until a smooth drizzling dressing forms.",
      "Assemble bowls: Divide cooked quinoa as the base. Top with roasted chickpeas, cucumber, cherry tomatoes, and kalamata olives.",
      "Drizzle generously with tahini dressing and garnish with fresh parsley."
    ]
  },
  {
    id: "rec-005",
    title: "Classic Japanese Tonkotsu Ramen",
    description: "Deep, silky pork bone broth infused with ginger and scallions, served with springy ramen noodles, tender chashu pork, and molten soft-boiled ajitsuke tamago.",
    category: "Dinner",
    cuisine: "Japanese",
    prepTime: 30,
    cookTime: 60,
    servings: 4,
    difficulty: "Hard",
    rating: 4.98,
    reviewsCount: 340,
    calories: 680,
    author: "Chef Ahmad",
    image: "https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=800&q=80",
    tags: ["Comfort Food", "Gourmet", "Asian"],
    ingredients: [
      { item: "Fresh ramen noodles", amount: "4 portions" },
      { item: "Rich pork/chicken bone broth", amount: "6 cups" },
      { item: "Braised chashu pork belly slices", amount: "8 slices" },
      { item: "Marinated soft-boiled eggs (Ajitsuke Tamago)", amount: "4 halves" },
      { item: "Shoyu tare (soy seasoning concentrate)", amount: "4 tbsp" },
      { item: "Mayu (black garlic oil)", amount: "2 tsp" },
      { item: "Menma (bamboo shoots) & scallions", amount: "1/2 cup each" },
      { item: "Nori seaweed sheets", amount: "4 squares" }
    ],
    instructions: [
      "Simmer the enriched bone broth with crushed garlic, scallion whites, and ginger until piping hot and emulsified.",
      "In serving bowls, spoon 1 tablespoon of shoyu tare seasoning into the bottom of each bowl.",
      "Boil ramen noodles in boiling water for exactly 90 seconds for firm 'katame' texture, then drain vigorously.",
      "Ladle 1.5 cups of boiling broth into bowls, stir with the tare, then fold noodles in carefully.",
      "Top with warm chashu slices, marinated egg halves, sliced green onions, bamboo shoots, and nori.",
      "Finish with a light drizzle of black garlic oil and serve immediately."
    ]
  },
  {
    id: "rec-006",
    title: "Golden Berry Acai Smoothie Bowl",
    description: "Thick, blended acai berry smoothie topped with crunchy honey granola, fresh sliced bananas, strawberries, blueberries, chia seeds, and coconut flakes.",
    category: "Breakfast",
    cuisine: "Modern American",
    prepTime: 10,
    cookTime: 0,
    servings: 1,
    difficulty: "Easy",
    rating: 4.82,
    reviewsCount: 65,
    calories: 320,
    author: "Insung",
    image: "https://images.unsplash.com/photo-1590301157890-4810ed352733?auto=format&fit=crop&w=800&q=80",
    tags: ["Vegan", "Superfood", "Quick & Easy"],
    ingredients: [
      { item: "Frozen pure unsweetened acai packet", amount: "1 pack (100g)" },
      { item: "Frozen ripe banana", amount: "1 medium" },
      { item: "Frozen mixed berries", amount: "1/2 cup" },
      { item: "Almond milk or coconut water", amount: "1/3 cup (just enough to blend)" },
      { item: "Artisanal granola & chia seeds", amount: "2 tbsp each" },
      { item: "Fresh strawberries & coconut flakes", amount: "For topping" }
    ],
    instructions: [
      "Break the acai packet into chunks and add to high-speed blender with frozen banana, berries, and almond milk.",
      "Blend on low, using the tamper wand to push ingredients down until thick like soft-serve ice cream.",
      "Scoop into a chilled bowl and smooth the surface with a spoon.",
      "Artfully arrange sliced strawberries, banana coins, blueberries, granola clusters, chia seeds, and toasted coconut flakes.",
      "Enjoy immediately with a spoon!"
    ]
  }
];

export const CATEGORIES = ["All", "Breakfast", "Lunch", "Dinner", "Vegetarian", "Quick & Easy"];
