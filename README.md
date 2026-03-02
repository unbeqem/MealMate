# MealMate – Product Concept & Technical Foundation (Milestone 1)

## 1. Vision

MealMate is a mobile application (iOS & Android) that helps users reduce food waste and overbuying by intelligently planning weekly meals and generating optimized shopping lists with price transparency.

The core idea:
Users select their favorite ingredients → receive recipe recommendations → plan their weekly meals → automatically generate a precise shopping list → reduce waste and save money.

---

# 2. Problem Statement

Many households:
- Buy too many ingredients.
- Throw away unused food.
- Plan meals inefficiently.
- Lack price transparency across supermarkets.
- Adjust shopping lists week-by-week manually.

This leads to:
- Food waste
- Unnecessary spending
- Poor meal planning habits
- Time lost in grocery stores

---

# 3. Goal

Build an intuitive mobile app that:

1. Personalizes ingredient preferences.
2. Recommends recipes based on selected ingredients.
3. Allows structured weekly meal planning (Breakfast / Lunch / Dinner).
4. Automatically calculates ingredient quantities.
5. Generates an optimized shopping list.
6. (Future milestone) Compares prices across supermarkets.

---

# 4. Target Audience

- Young professionals
- Families
- Students
- Sustainability-conscious users
- Budget-oriented shoppers

---

# 5. Milestone 1 Scope (MVP)

Focus on:

### 5.1 Ingredient Selection
- Fetch ingredients from an external API.
- Search & filter ingredients.
- Add ingredients to favorites.
- Adjust quantity manually.
- Save user preferences.

### 5.2 Recipe Recommendation & Generator
- Generate recipes based on:
  - Selected ingredients
  - User preferences
- Categorize recipes into:
  - Breakfast
  - Lunch
  - Dinner
- Allow user to:
  - Browse recipes
  - View details (ingredients + instructions)
  - Select recipes for the week

### 5.3 Weekly Meal Planner
- 7-day planner layout
- Categories per day:
  - Breakfast
  - Lunch
  - Dinner
- Assign selected recipes to each slot
- Edit/replace meals

### 5.4 Shopping List Generator
- Aggregate ingredients from all selected recipes
- Combine duplicate ingredients
- Calculate total quantities
- Allow manual adjustment
- Mark items as purchased

---

# 6. Future Milestones (Not in MVP)

- Price comparison between supermarkets
- Real-time supermarket APIs
- AI-based waste reduction optimization
- Pantry inventory tracking
- Barcode scanning
- Nutrition tracking
- Budget limit mode
- Auto-adjust meals based on discounts

---

# 7. Functional Requirements (Milestone 1)

### FR1: Ingredient API Integration
- Fetch ingredient list from external API
- Search endpoint
- Paginated results

### FR2: Recipe Engine
- Generate recipes via:
  - External recipe API OR
  - AI-based recipe generator
- Filter by:
  - Ingredients
  - Category
- Display:
  - Title
  - Image
  - Ingredients
  - Instructions

### FR3: Weekly Planner
- Store week plan locally or backend
- CRUD operations for meals
- Persist state between sessions

### FR4: Shopping List Aggregator
- Deduplicate ingredients
- Normalize units
- Sum quantities
- Manual override possible

---

# 8. Non-Functional Requirements

- Cross-platform (iOS + Android)
- Responsive & smooth UX
- Offline-first capability (basic mode)
- Scalable backend
- GDPR compliant (EU users)
- Secure authentication (future phase)

---

# 9. Suggested Tech Stack

## 9.1 Mobile App (Frontend)

### Option A (Recommended): Flutter
- Single codebase for iOS + Android
- Strong UI performance
- Fast development
- Good state management options (Riverpod / Bloc)

OR

### Option B: React Native
- Large ecosystem
- TypeScript support
- Expo for faster MVP development

Recommendation: Flutter for clean UI and performance.

---

## 9.2 Backend

### Option A: Supabase (Recommended for MVP)
- PostgreSQL database
- Auth
- Realtime
- Row-level security
- Fast setup

OR

### Option B: Node.js + Express
- Full control
- Custom API logic
- Hosted on:
  - Railway
  - Render
  - AWS

---

## 9.3 Database Schema (High-Level)

### Users
- id
- email
- preferences

### Ingredients
- id
- name
- default_unit

### Recipes
- id
- title
- category (breakfast/lunch/dinner)
- instructions
- image_url

### Recipe_Ingredients
- recipe_id
- ingredient_id
- quantity
- unit

### Weekly_Plan
- id
- user_id
- week_start_date

### Planned_Meals
- weekly_plan_id
- day_of_week
- category
- recipe_id

---

# 10. External APIs (Research Required)

Claude should research:

- Spoonacular API
- Edamam API
- TheMealDB
- OpenFoodFacts (for ingredient data)
- Supermarket APIs (future milestone)

---

# 11. System Architecture (MVP)

Mobile App  
↕ REST API  
Backend (Supabase or Node)  
↕  
PostgreSQL Database  

Optional:
AI Recipe Generator (LLM API)

---

# 12. Core User Flow (MVP)

1. User installs app
2. Selects favorite ingredients
3. Receives recipe recommendations
4. Chooses weekly meals
5. Reviews auto-generated shopping list
6. Adjusts quantities if needed

---

# 13. Key Technical Challenges

- Ingredient unit normalization (g, kg, ml, etc.)
- Deduplication of ingredients across recipes
- Efficient recipe filtering
- Clean weekly planner UX
- Future price integration

---

# 14. Monetization (Future)

- Freemium model
- Premium: price comparison + AI optimization
- Affiliate links to supermarkets
- Sponsored recipes

---

# 15. Success Metrics

- Reduced reported food waste
- Weekly active users
- Recipe-to-shopping-list conversion rate
- User retention after 4 weeks

---

# 16. Deliverables for Claude Planning Phase

Claude should:

1. Research best ingredient & recipe APIs.
2. Propose final architecture decision.
3. Design database schema in detail.
4. Define API routes.
5. Define state management strategy.
6. Create development roadmap (Sprint plan).
7. Identify potential edge cases.
8. Provide UI wireframe structure.
9. Propose scalable path to price comparison.

---

Supabase pwd: Raibsm41uQnzyBnX

END OF CONCEPT
