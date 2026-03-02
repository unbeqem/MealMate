# MealMate

## What This Is

MealMate is a cross-platform mobile app (iOS & Android) built with Flutter that helps users reduce food waste and save money by intelligently planning weekly meals and generating optimized shopping lists. Users select favorite ingredients, receive recipe recommendations (from external APIs and AI generation), plan meals across a 7-day calendar, and get an automatically aggregated shopping list.

## Core Value

Users can go from selecting ingredients to a complete weekly meal plan with an accurate shopping list in minutes — reducing food waste and unnecessary spending.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] Ingredient selection with search, filtering, and favorites
- [ ] Recipe recommendations from external API + AI-based generation from selected ingredients
- [ ] Weekly meal planner (7 days x breakfast/lunch/dinner)
- [ ] Shopping list auto-generated from meal plan with deduplication and unit normalization
- [ ] Basic auth (email/password via Supabase) with data sync
- [ ] Full offline support — cached recipes, meal plan, and shopping list sync when back online

### Out of Scope

- Price comparison across supermarkets — future milestone, requires supermarket API integrations
- Barcode scanning — hardware-dependent, defer to v2+
- Nutrition tracking — not core to waste reduction value prop
- Pantry inventory tracking — adds complexity, defer to v2
- Budget limit mode — depends on price data not available in v1
- AI-based waste reduction optimization — future milestone
- Auto-adjust meals based on discounts — requires price comparison infrastructure
- Monetization features — premature for MVP

## Context

- **Target audience:** Young professionals, families, students, sustainability-conscious and budget-oriented shoppers
- **Core user flow:** Install app → sign up → select favorite ingredients → browse/generate recipes → assign to weekly planner → review auto-generated shopping list → adjust quantities → shop
- **Recipe sources:** External API (Spoonacular/Edamam/TheMealDB — research to determine best option) for browsing, plus LLM-based generation for custom recipes from selected ingredients
- **Ingredient data:** External API for ingredient database (research to determine best free/affordable option)
- **Unit normalization challenge:** Ingredients come in varied units (g, kg, ml, L, cups, tbsp) — deduplication and aggregation across recipes requires normalization logic
- **Success metrics:** Reduced food waste, weekly active users, recipe-to-shopping-list conversion rate, 4-week retention

## Constraints

- **Tech stack:** Flutter (frontend), Supabase (backend/auth/database), PostgreSQL
- **Cross-platform:** Must work on both iOS and Android from single codebase
- **Offline-first:** Full offline capability — cache recipes, meal plans, shopping lists; sync when online
- **GDPR:** Must be compliant for EU users
- **APIs:** Need free/affordable ingredient and recipe API — research required to select best option
- **Done criteria:** Working end-to-end app on real device/emulator (not app store submission)

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Flutter over React Native | Clean UI, strong performance, single codebase | — Pending |
| Supabase over custom Node.js backend | Fast MVP setup, built-in auth/realtime/RLS | — Pending |
| Both API + AI for recipes | API for browsing existing recipes, AI for custom generation from ingredients | — Pending |
| Basic auth in v1 | Data sync across devices needed, Supabase auth is low-effort | — Pending |
| Full offline support in v1 | Core UX requirement — users shop in stores with poor connectivity | — Pending |
| External API for ingredients | Research needed to pick best option (Spoonacular/Edamam/TheMealDB/OpenFoodFacts) | — Pending |

---
*Last updated: 2026-03-02 after initialization*
