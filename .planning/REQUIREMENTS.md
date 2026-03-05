# Requirements: MealMate

**Defined:** 2026-03-02
**Core Value:** Users can go from selecting ingredients to a complete weekly meal plan with an accurate shopping list in minutes — reducing food waste and unnecessary spending.

## v1 Requirements

Requirements for initial release. Each maps to roadmap phases.

### Authentication & Onboarding

- [x] **AUTH-01**: User can sign up with email and password
- [x] **AUTH-02**: User can log in and stay logged in across sessions
- [x] **AUTH-03**: User can log out from any screen
- [x] **AUTH-04**: User can reset password via email link
- [x] **AUTH-05**: User completes onboarding flow capturing household size and dietary preferences (2-3 screens)

### Ingredient Selection

- [x] **INGR-01**: User can search ingredients from external API with autocomplete
- [x] **INGR-02**: User can browse ingredients by category
- [x] **INGR-03**: User can add ingredients to favorites for quick access
- [x] **INGR-04**: User can filter ingredients by dietary restrictions (vegetarian, vegan, gluten-free, dairy-free)
- [x] **INGR-05**: User can select "I have these ingredients today" for recipe discovery

### Recipe Discovery & Generation

- [x] **RECP-01**: User can browse recipes from external API with search by name, ingredient, cuisine, and cook time
- [x] **RECP-02**: User can view recipe details including ingredients list, step-by-step instructions, cook time, and servings
- [ ] **RECP-03**: User can scale recipe serving size and see adjusted ingredient quantities
- [x] **RECP-04**: User can discover recipes based on selected available ingredients ("use what you have")
- [ ] **RECP-05**: User receives AI-generated recipes when API returns no matches for selected ingredients
- [ ] **RECP-06**: AI-generated recipes include validated quantities, proper units, and only ingredients from the user's selection

### Weekly Meal Planner

- [ ] **PLAN-01**: User can view a 7-day weekly planner with breakfast, lunch, and dinner slots
- [ ] **PLAN-02**: User can assign a recipe to any meal slot
- [ ] **PLAN-03**: User can edit or replace a recipe in any meal slot
- [ ] **PLAN-04**: User can drag and drop meals to reschedule between slots
- [ ] **PLAN-05**: User can save current week as a meal plan template
- [ ] **PLAN-06**: User can load a saved template into a future week
- [ ] **PLAN-07**: Planner suggests recipes that reuse ingredients already in the week's plan to reduce waste

### Shopping List

- [ ] **SHOP-01**: Shopping list is auto-generated from all recipes in the current meal plan
- [ ] **SHOP-02**: Duplicate ingredients across recipes are merged into single line items
- [ ] **SHOP-03**: Ingredient units are normalized (g/kg, ml/L, cups/tbsp/tsp) so quantities are summed correctly
- [ ] **SHOP-04**: User can manually add items to the shopping list (non-recipe items)
- [ ] **SHOP-05**: User can remove items from the shopping list
- [ ] **SHOP-06**: User can check off items as purchased during shopping
- [ ] **SHOP-07**: User can adjust quantities on any shopping list item

### Offline & Sync

- [ ] **SYNC-01**: User's meal plan is available offline without internet connection
- [ ] **SYNC-02**: User's shopping list is available offline and check-off state persists
- [ ] **SYNC-03**: Cached recipes are viewable offline (recipes previously browsed)
- [ ] **SYNC-04**: Changes made offline sync automatically when internet connection is restored
- [ ] **SYNC-05**: User's data syncs across multiple devices via Supabase

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Engagement & Retention

- **ENGR-01**: User can favorite/bookmark recipes for a personal cookbook
- **ENGR-02**: User receives push notification reminders for upcoming meals
- **ENGR-03**: Shopping list items are categorized by store section (produce, dairy, meat, pantry, frozen)

### Social & Sharing

- **SOCL-01**: User can share shopping list with household members in real-time
- **SOCL-02**: Multiple household members can edit the same meal plan
- **SOCL-03**: User can share a recipe via link or export

### Advanced Features

- **ADVN-01**: User can import recipes from a URL
- **ADVN-02**: User sees estimated cost for shopping list items
- **ADVN-03**: User sees basic nutrition info per recipe (if provided by API)

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Full pantry inventory tracking | Separate product complexity; decays without ongoing manual input; lightweight "I have these" selector delivers 80% of value |
| Barcode scanning | Hardware-dependent, poor accuracy on grocery items, high dev cost for low retention impact |
| Price comparison across supermarkets | Requires real-time supermarket API integrations (none free, most unofficial/fragile) |
| Calorie/macro nutrition tracking | Different problem domain (weight loss vs. waste reduction); requires verified nutrition databases |
| Social/community recipe feed | Different product thesis; balloons infrastructure and moderation costs |
| Grocery delivery integration | Requires retailer API partnerships; wrong SKU matching creates frustration |
| Gamification / streaks / badges | Meal planning is a utility; streaks create anxiety; adds significant complexity |
| Full offline recipe creation/editing | Heavy CRDT sync complexity; offline read/use/shop is sufficient for v1 |
| Mobile app store submission | v1 target is working end-to-end app on device/emulator, not app store release |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| AUTH-01 | Phase 2 | Complete |
| AUTH-02 | Phase 2 | Complete |
| AUTH-03 | Phase 2 | Complete |
| AUTH-04 | Phase 2 | Complete |
| AUTH-05 | Phase 2 | Complete |
| INGR-01 | Phase 3 | Complete |
| INGR-02 | Phase 3 | Complete |
| INGR-03 | Phase 3 | Complete |
| INGR-04 | Phase 3 | Complete |
| INGR-05 | Phase 3 | Complete |
| RECP-01 | Phase 4 | Complete |
| RECP-02 | Phase 4 | Complete |
| RECP-03 | Phase 4 | Pending |
| RECP-04 | Phase 4 | Complete |
| RECP-05 | Phase 7 | Pending |
| RECP-06 | Phase 7 | Pending |
| PLAN-01 | Phase 5 | Pending |
| PLAN-02 | Phase 5 | Pending |
| PLAN-03 | Phase 5 | Pending |
| PLAN-04 | Phase 5 | Pending |
| PLAN-05 | Phase 5 | Pending |
| PLAN-06 | Phase 5 | Pending |
| PLAN-07 | Phase 5 | Pending |
| SHOP-01 | Phase 6 | Pending |
| SHOP-02 | Phase 6 | Pending |
| SHOP-03 | Phase 6 | Pending |
| SHOP-04 | Phase 6 | Pending |
| SHOP-05 | Phase 6 | Pending |
| SHOP-06 | Phase 6 | Pending |
| SHOP-07 | Phase 6 | Pending |
| SYNC-01 | Phase 8 | Pending |
| SYNC-02 | Phase 8 | Pending |
| SYNC-03 | Phase 8 | Pending |
| SYNC-04 | Phase 8 | Pending |
| SYNC-05 | Phase 8 | Pending |

**Coverage:**
- v1 requirements: 35 total
- Mapped to phases: 35
- Unmapped: 0

---
*Requirements defined: 2026-03-02*
*Last updated: 2026-03-02 after roadmap creation — traceability complete*
