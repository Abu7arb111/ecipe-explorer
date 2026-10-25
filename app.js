/**
 * Recipe Explorer - Application Logic
 * Authors: Ahmad Harb, Insung, Tylor, Vedanth
 */

import { INITIAL_RECIPES, CATEGORIES } from './data.js';

class RecipeApp {
  constructor() {
    this.recipes = this.loadRecipes();
    this.favorites = this.loadFavorites();
    this.activeCategory = 'All';
    this.searchQuery = '';
    this.sortBy = 'featured';
    this.activeTimer = null;
    this.timerSeconds = 0;

    this.initDOM();
    this.bindEvents();
    this.renderCategoryTabs();
    this.render();
    this.updateFavBadge();
  }

  loadRecipes() {
    const saved = localStorage.getItem('recipe_explorer_custom_recipes');
    if (saved) {
      try {
        const custom = JSON.parse(saved);
        return [...INITIAL_RECIPES, ...custom];
      } catch (e) {
        return [...INITIAL_RECIPES];
      }
    }
    return [...INITIAL_RECIPES];
  }

  loadFavorites() {
    const saved = localStorage.getItem('recipe_explorer_favorites');
    return saved ? JSON.parse(saved) : [];
  }

  saveFavorites() {
    localStorage.setItem('recipe_explorer_favorites', JSON.stringify(this.favorites));
    this.updateFavBadge();
  }

  initDOM() {
    this.grid = document.getElementById('recipeGrid');
    this.categoryTabs = document.getElementById('categoryTabs');
    this.searchInput = document.getElementById('recipeSearchInput');
    this.clearSearchBtn = document.getElementById('clearSearchBtn');
    this.resultsCount = document.getElementById('resultsCount');
    this.sortSelect = document.getElementById('sortSelect');
    this.emptyState = document.getElementById('emptyState');
    this.resetFiltersBtn = document.getElementById('resetFiltersBtn');
    this.favCountBadge = document.getElementById('favCountBadge');
    this.favoritesNavBtn = document.getElementById('favoritesNavBtn');

    // Modals
    this.detailModal = document.getElementById('detailModalOverlay');
    this.detailModalContent = document.getElementById('detailModalContent');
    this.closeDetailModalBtn = document.getElementById('closeDetailModalBtn');

    this.postModal = document.getElementById('postModalOverlay');
    this.openPostModalBtn = document.getElementById('openPostModalBtn');
    this.closePostModalBtn = document.getElementById('closePostModalBtn');
    this.cancelPostBtn = document.getElementById('cancelPostBtn');
    this.postForm = document.getElementById('postRecipeForm');
    this.toast = document.getElementById('toastNotification');
  }

  bindEvents() {
    // Search input
    this.searchInput.addEventListener('input', (e) => {
      this.searchQuery = e.target.value.trim().toLowerCase();
      this.clearSearchBtn.style.display = this.searchQuery ? 'block' : 'none';
      this.render();
    });

    this.clearSearchBtn.addEventListener('click', () => {
      this.searchInput.value = '';
      this.searchQuery = '';
      this.clearSearchBtn.style.display = 'none';
      this.render();
    });

    // Quick ingredient chips
    document.querySelectorAll('.chip[data-ingredient]').forEach(chip => {
      chip.addEventListener('click', () => {
        const ingredient = chip.dataset.ingredient;
        this.searchInput.value = ingredient;
        this.searchQuery = ingredient.toLowerCase();
        this.clearSearchBtn.style.display = 'block';
        this.render();
      });
    });

    // Sorting
    this.sortSelect.addEventListener('change', (e) => {
      this.sortBy = e.target.value;
      this.render();
    });

    // Reset Filters
    this.resetFiltersBtn.addEventListener('click', () => {
      this.activeCategory = 'All';
      this.searchQuery = '';
      this.searchInput.value = '';
      this.clearSearchBtn.style.display = 'none';
      this.renderCategoryTabs();
      this.render();
    });

    // Favorites Nav Filter
    this.favoritesNavBtn.addEventListener('click', (e) => {
      e.preventDefault();
      this.activeCategory = 'Favorites';
      this.renderCategoryTabs();
      this.render();
    });

    // Detail Modal Close
    this.closeDetailModalBtn.addEventListener('click', () => this.closeDetailModal());
    this.detailModal.addEventListener('click', (e) => {
      if (e.target === this.detailModal) this.closeDetailModal();
    });

    // Post Modal Open/Close
    this.openPostModalBtn.addEventListener('click', () => this.openPostModal());
    this.closePostModalBtn.addEventListener('click', () => this.closePostModal());
    this.cancelPostBtn.addEventListener('click', () => this.closePostModal());
    this.postModal.addEventListener('click', (e) => {
      if (e.target === this.postModal) this.closePostModal();
    });

    // Post Recipe Submit
    this.postForm.addEventListener('submit', (e) => this.handleRecipeSubmit(e));

    // Keyboard ESC
    document.addEventListener('keydown', (e) => {
      if (e.key === 'Escape') {
        this.closeDetailModal();
        this.closePostModal();
      }
    });
  }

  renderCategoryTabs() {
    this.categoryTabs.innerHTML = '';
    const categoriesWithFavs = [...CATEGORIES, 'Favorites'];

    categoriesWithFavs.forEach(cat => {
      const btn = document.createElement('button');
      btn.className = `tab-btn ${this.activeCategory === cat ? 'active' : ''}`;
      btn.textContent = cat;
      btn.addEventListener('click', () => {
        this.activeCategory = cat;
        this.renderCategoryTabs();
        this.render();
      });
      this.categoryTabs.appendChild(btn);
    });
  }

  getFilteredRecipes() {
    return this.recipes.filter(rec => {
      // Category filter
      if (this.activeCategory === 'Favorites') {
        if (!this.favorites.includes(rec.id)) return false;
      } else if (this.activeCategory !== 'All') {
        const matchesCategory = rec.category.toLowerCase() === this.activeCategory.toLowerCase();
        const matchesTag = rec.tags && rec.tags.some(t => t.toLowerCase() === this.activeCategory.toLowerCase());
        if (!matchesCategory && !matchesTag) return false;
      }

      // Search query filter
      if (this.searchQuery) {
        const titleMatch = rec.title.toLowerCase().includes(this.searchQuery);
        const descMatch = rec.description.toLowerCase().includes(this.searchQuery);
        const cuisineMatch = rec.cuisine && rec.cuisine.toLowerCase().includes(this.searchQuery);
        const ingredientMatch = rec.ingredients.some(ing =>
          (typeof ing === 'string' ? ing : ing.item).toLowerCase().includes(this.searchQuery)
        );
        return titleMatch || descMatch || cuisineMatch || ingredientMatch;
      }

      return true;
    }).sort((a, b) => {
      if (this.sortBy === 'rating') {
        return (b.rating || 0) - (a.rating || 0);
      }
      if (this.sortBy === 'quickest') {
        const totalA = (a.prepTime || 0) + (a.cookTime || 0);
        const totalB = (b.prepTime || 0) + (b.cookTime || 0);
        return totalA - totalB;
      }
      return 0; // Default order
    });
  }

  render() {
    const list = this.getFilteredRecipes();
    this.resultsCount.textContent = `Showing ${list.length} recipe${list.length === 1 ? '' : 's'}`;

    if (list.length === 0) {
      this.grid.innerHTML = '';
      this.emptyState.style.display = 'block';
      return;
    }

    this.emptyState.style.display = 'none';
    this.grid.innerHTML = list.map(rec => this.createCardHTML(rec)).join('');

    // Attach card event listeners
    this.grid.querySelectorAll('.recipe-card').forEach(card => {
      const id = card.dataset.id;
      card.addEventListener('click', (e) => {
        if (e.target.closest('.card-bookmark-btn')) return;
        this.openDetailModal(id);
      });
    });

    // Bookmark buttons
    this.grid.querySelectorAll('.card-bookmark-btn').forEach(btn => {
      btn.addEventListener('click', (e) => {
        e.stopPropagation();
        const id = btn.dataset.id;
        this.toggleFavorite(id);
      });
    });
  }

  createCardHTML(rec) {
    const isFav = this.favorites.includes(rec.id);
    const totalTime = (rec.prepTime || 0) + (rec.cookTime || 0);

    return `
      <div class="recipe-card" data-id="${rec.id}">
        <div class="card-img-wrapper">
          <img class="card-img" src="${rec.image || 'https://images.unsplash.com/photo-1495521821757-a1efb6729352?auto=format&fit=crop&w=800&q=80'}" alt="${rec.title}" loading="lazy">
          <button class="card-bookmark-btn ${isFav ? 'active' : ''}" data-id="${rec.id}" aria-label="Favorite recipe" title="${isFav ? 'Remove Favorite' : 'Save Favorite'}">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="${isFav ? 'currentColor' : 'none'}" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
              <path d="M19 21l-7-5-7 5V5a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2z"></path>
            </svg>
          </button>
          <div class="card-badge">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><circle cx="12" cy="12" r="10"></circle><polyline points="12 6 12 12 16 14"></polyline></svg>
            ${totalTime} mins • ${rec.difficulty}
          </div>
        </div>

        <div class="card-body">
          <div class="card-header-meta">
            <span class="card-cuisine">${rec.cuisine || rec.category}</span>
            <div class="card-rating">
              <span class="star-icon">★</span>
              <span>${rec.rating.toFixed(1)}</span>
              <span style="color:var(--gray-500); font-size:0.75rem;">(${rec.reviewsCount})</span>
            </div>
          </div>

          <h3 class="card-title">${rec.title}</h3>
          <p class="card-desc">${rec.description}</p>

          <div class="card-tags">
            ${(rec.tags || []).slice(0, 3).map(tag => `<span class="tag-pill">${tag}</span>`).join('')}
          </div>

          <div class="card-footer">
            <div class="author-info">
              <span class="author-avatar">${(rec.author || 'C')[0]}</span>
              <span>By ${rec.author || 'Community'}</span>
            </div>
            <span>${rec.calories} kcal</span>
          </div>
        </div>
      </div>
    `;
  }

  toggleFavorite(id) {
    if (this.favorites.includes(id)) {
      this.favorites = this.favorites.filter(favId => favId !== id);
      this.showToast('Removed from favorites');
    } else {
      this.favorites.push(id);
      this.showToast('Saved to favorites! ❤️');
    }
    this.saveFavorites();
    this.render();
  }

  updateFavBadge() {
    this.favCountBadge.textContent = this.favorites.length;
  }

  openDetailModal(id) {
    const rec = this.recipes.find(r => r.id === id);
    if (!rec) return;

    const totalTime = (rec.prepTime || 0) + (rec.cookTime || 0);

    this.detailModalContent.innerHTML = `
      <div class="modal-hero">
        <img class="modal-hero-img" src="${rec.image}" alt="${rec.title}">
        <div class="modal-hero-overlay">
          <span style="font-weight:700; color:var(--accent); text-transform:uppercase; font-size:0.85rem; letter-spacing:1px;">${rec.cuisine} Cuisine</span>
          <h2 class="modal-hero-title">${rec.title}</h2>
          <p style="opacity:0.9; max-width:650px; font-size:0.95rem;">${rec.description}</p>
        </div>
      </div>

      <div class="modal-stats-bar">
        <div class="stat-item">
          <span class="stat-value">${rec.prepTime} min</span>
          <span class="stat-label">Prep Time</span>
        </div>
        <div class="stat-item">
          <span class="stat-value">${rec.cookTime} min</span>
          <span class="stat-label">Cook Time</span>
        </div>
        <div class="stat-item">
          <span class="stat-value">${rec.servings}</span>
          <span class="stat-label">Servings</span>
        </div>
        <div class="stat-item">
          <span class="stat-value">${rec.calories}</span>
          <span class="stat-label">Calories</span>
        </div>
      </div>

      <div class="modal-content-sections">
        <!-- Interactive Kitchen Timer -->
        <div class="timer-widget">
          <div class="timer-info">
            <span style="font-size:1.6rem;">⏱️</span>
            <div>
              <div style="font-weight:700; font-size:0.95rem; color:var(--dark);">Kitchen Cook Timer</div>
              <div style="font-size:0.8rem; color:var(--gray-500);">Pre-set for ${rec.cookTime} minutes cooking step</div>
            </div>
          </div>
          <div style="display:flex; align-items:center; gap:0.8rem;">
            <div class="timer-clock" id="modalTimerDisplay">${String(rec.cookTime).padStart(2, '0')}:00</div>
            <button class="btn btn-primary" id="startTimerBtn" style="padding:0.4rem 0.9rem; font-size:0.85rem;">Start Timer</button>
          </div>
        </div>

        <!-- Ingredients Section with checklist -->
        <div class="detail-section">
          <h3 class="detail-section-title">
            <span>🥗</span> Ingredients & Measurements
            <span style="font-size:0.75rem; font-weight:normal; color:var(--gray-500);">(Check off items as you prep)</span>
          </h3>
          <ul class="ingredients-list">
            ${rec.ingredients.map(ing => {
              const text = typeof ing === 'string' ? ing : `<strong>${ing.amount}</strong> — ${ing.item}`;
              return `
                <li class="ingredient-item">
                  <input type="checkbox">
                  <span>${text}</span>
                </li>
              `;
            }).join('')}
          </ul>
        </div>

        <!-- Step by Step Instructions -->
        <div class="detail-section">
          <h3 class="detail-section-title">
            <span>🍳</span> Cooking Instructions
          </h3>
          <ol class="instructions-list">
            ${rec.instructions.map((step, idx) => `
              <li class="instruction-step">
                <span class="step-number">${idx + 1}</span>
                <p class="step-text">${step}</p>
              </li>
            `).join('')}
          </ol>
        </div>
      </div>
    `;

    // Bind checklist toggling
    this.detailModalContent.querySelectorAll('.ingredient-item').forEach(item => {
      const checkbox = item.querySelector('input[type="checkbox"]');
      item.addEventListener('click', (e) => {
        if (e.target !== checkbox) checkbox.checked = !checkbox.checked;
        item.classList.toggle('checked', checkbox.checked);
      });
    });

    // Kitchen Timer logic
    const timerDisplay = document.getElementById('modalTimerDisplay');
    const startTimerBtn = document.getElementById('startTimerBtn');
    let timerRunning = false;
    let secondsLeft = (rec.cookTime || 15) * 60;

    startTimerBtn.addEventListener('click', () => {
      if (!timerRunning) {
        timerRunning = true;
        startTimerBtn.textContent = 'Pause';
        startTimerBtn.style.background = '#e9c46a';
        this.activeTimer = setInterval(() => {
          if (secondsLeft <= 0) {
            clearInterval(this.activeTimer);
            timerDisplay.textContent = '00:00';
            this.showToast('Ding! Cook time completed! 🔔');
            startTimerBtn.textContent = 'Done!';
            return;
          }
          secondsLeft--;
          const m = String(Math.floor(secondsLeft / 60)).padStart(2, '0');
          const s = String(secondsLeft % 60).padStart(2, '0');
          timerDisplay.textContent = `${m}:${s}`;
        }, 1000);
      } else {
        timerRunning = false;
        clearInterval(this.activeTimer);
        startTimerBtn.textContent = 'Resume';
        startTimerBtn.style.background = 'var(--primary)';
      }
    });

    this.detailModal.classList.add('open');
    document.body.style.overflow = 'hidden';
  }

  closeDetailModal() {
    if (this.activeTimer) clearInterval(this.activeTimer);
    this.detailModal.classList.remove('open');
    document.body.style.overflow = '';
  }

  openPostModal() {
    this.postModal.classList.add('open');
    document.body.style.overflow = 'hidden';
  }

  closePostModal() {
    this.postModal.classList.remove('open');
    document.body.style.overflow = '';
  }

  handleRecipeSubmit(e) {
    e.preventDefault();

    const title = document.getElementById('recipeTitle').value.trim();
    const category = document.getElementById('recipeCategory').value;
    const description = document.getElementById('recipeDescription').value.trim();
    const prepTime = parseInt(document.getElementById('recipePrepTime').value) || 15;
    const cookTime = parseInt(document.getElementById('recipeCookTime').value) || 20;
    const servings = parseInt(document.getElementById('recipeServings').value) || 4;
    const author = document.getElementById('recipeAuthor').value.trim() || 'Ahmad Harb';
    const imageUrl = document.getElementById('recipeImageUrl').value.trim() || 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=800&q=80';

    const rawIngredients = document.getElementById('recipeIngredients').value.trim().split('\n').filter(Boolean);
    const rawInstructions = document.getElementById('recipeInstructions').value.trim().split('\n').filter(Boolean);

    const newRecipe = {
      id: `custom-${Date.now()}`,
      title,
      category,
      cuisine: category,
      description,
      prepTime,
      cookTime,
      servings,
      calories: Math.floor(Math.random() * 300) + 350,
      difficulty: cookTime > 30 ? 'Medium' : 'Easy',
      rating: 5.0,
      reviewsCount: 1,
      author,
      image: imageUrl,
      tags: [category, 'User Submitted'],
      ingredients: rawIngredients.map(item => ({ item, amount: '' })),
      instructions: rawInstructions
    };

    // Save custom recipes to localStorage
    const saved = localStorage.getItem('recipe_explorer_custom_recipes');
    const customList = saved ? JSON.parse(saved) : [];
    customList.unshift(newRecipe);
    localStorage.setItem('recipe_explorer_custom_recipes', JSON.stringify(customList));

    this.recipes.unshift(newRecipe);
    this.postForm.reset();
    this.closePostModal();
    this.render();
    this.showToast('Recipe published successfully! 🎉');
  }

  showToast(message) {
    this.toast.textContent = message;
    this.toast.style.display = 'block';
    setTimeout(() => {
      this.toast.style.display = 'none';
    }, 3200);
  }
}

document.addEventListener('DOMContentLoaded', () => {
  new RecipeApp();
});
