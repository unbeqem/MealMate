# Feature Research

**Domain:** Meal planning mobile app (ingredient-based recipes, weekly planner, shopping list, food waste reduction)
**Researched:** 2026-03-02
**Confidence:** MEDIUM — based on competitor analysis, multiple review sources, and market research. No direct user interviews. Core feature landscape is well-established; differentiator rankings are interpretive.

---

## Feature Landscape

### Table Stakes (Users Expect These)

Features users assume exist. Missing these = product feels incomplete or broken.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Recipe browsing with search | Users won't plan meals they can't find; expected in every food app since 2018 | LOW | Needs good search UX: by name, ingredient, cuisine, time |
| Dietary restriction / allergy filters | ~30% of users have dietary needs; apps without this feel hostile | MEDIUM | Minimum: vegetarian, vegan, gluten-free, dairy-free; per-user, not global |
| 7-day weekly meal planner | Calendar view for breakfast/lunch/dinner is the standard grid; dinners-only (Mealime v1 model) now feels incomplete | MEDIUM | Drag-and-drop or tap-to-assign slots; empty slots are fine |
| Auto-generated shopping list from meal plan | The entire point of digital meal planning; any app that requires manual list-building loses users fast | MEDIUM | Must deduplicate (e.g., 3 recipes each using onions → one line item) |
| Ingredient unit normalization | Users notice immediately when 200g + 0.5 kg is shown as two items | HIGH | Hardest table-stakes item; requires unit conversion table (g/kg/ml/L/cups/tbsp/tsp/oz/lb) |
| Recipe serving size scaling | Household sizes vary; cooking for 2 vs. 4 is fundamental | LOW | Scale ingredient quantities, propagate to shopping list |
| User account with data sync | Users expect their plan to survive a phone upgrade or app reinstall; also enables multi-device | MEDIUM | Supabase auth covers this; email/password minimum |
| Offline access | Users shop in stores; viewing shopping list and meal plan without connectivity is non-negotiable | HIGH | Flutter + local SQLite/Drift cache; sync on reconnect |
| Recipe detail view | Ingredients list, step-by-step instructions, cook time, servings | LOW | Standard layout; poor UX here tanks retention |
| Basic onboarding / preference capture | Users won't engage without at least household size + dietary preference setup | LOW | 2-3 screen flow; too long = drop-off |

### Differentiators (Competitive Advantage)

Features that set the product apart. Not required, but valued — especially for MealMate's food waste + savings angle.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Ingredient-based recipe discovery ("use what you have") | Core to food waste reduction; SuperCook, Cooklist, Remy all built around this; users searching for recipes from fridge contents is a top use case | MEDIUM | Select available ingredients → filter recipe candidates; this is MealMate's primary differentiator |
| AI recipe generation from selected ingredients | When the recipe database has no match, AI fills the gap; moves product from "catalog app" to "personal chef" | HIGH | LLM call with ingredient list + constraints → structured recipe output; cost per call is a concern |
| Smart ingredient reuse across meal plan | Ollie's standout feature: plans multiple meals to share ingredients, reducing both waste and shopping cost | HIGH | Requires planning algorithm or AI that optimizes across 7-day slot assignment |
| Shopping list categorized by store section | Saves time in-store; users who shop weekly notice immediately if list is unorganized | LOW | Map ingredients to categories: produce, dairy, meat, pantry, frozen, etc. |
| Manual shopping list editing | Users always want to add items outside the meal plan (household goods, snacks) | LOW | Add/remove/check-off; persist checked state during shopping trip |
| Recipe favorites / personal cookbook | Users revisit recipes they liked; this drives retention by building invested collections | LOW | Star/heart action; filter view; foundational engagement loop |
| Meal plan templates / saved weeks | Power users want to reuse a plan they liked; reduces weekly re-planning friction | MEDIUM | Save current week as template; load template into future week |
| Drag-and-drop meal rescheduling | Users change their minds mid-week; friction here causes abandonment of the planner | LOW | Flutter's Draggable/DragTarget widgets handle this; mostly UX design work |
| "What's expiring soon" prioritization | Surfaces ingredients near expiry and suggests recipes using them; directly addresses the waste reduction mission | HIGH | Requires knowing expiry dates — needs either manual entry or pantry tracking; consider deferring full pantry but allowing "I have these ingredients today" quick flow |
| Shareable shopping list (household sync) | Families and housemates split shopping duties; shared real-time list is expected by 35%+ of families | MEDIUM | Supabase Realtime subscriptions; household concept (user groups) |
| Push notifications for meal plan reminders | "What's for dinner tonight?" reminder drives app opens and follows through on plans | LOW | Platform push (FCM/APNs); opt-in; one evening reminder is low-friction |
| Recipe import from URL | Power users have saved recipes elsewhere; importing from web links drives library growth | MEDIUM | Recipe schema.org parsing; brittle — needs fallback to manual entry |

### Anti-Features (Commonly Requested, Often Problematic)

Features that seem good but create problems — build these and you'll regret it.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Full pantry inventory tracking | Users want "what do I have?" to avoid overbuying | Requires ongoing manual input (or barcode scanning) to stay accurate; decays quickly and becomes useless/misleading; NoWaste, FoodShiner built around this and it's their whole product | Offer a lightweight "I have these ingredients today" one-time selector for recipe filtering — no persistent inventory |
| Barcode scanning for pantry/shopping | Looks impressive; users ask for it | Hardware-dependent; poor accuracy on grocery items; requires product database (Open Food Facts has gaps); high dev cost for low retention impact | Manual ingredient entry with autocomplete is faster for most users |
| Price comparison across supermarkets | "Save money" is in the value prop, so users ask for this | Requires real-time supermarket API integrations (Woolworths, Coles, Tesco, etc.) — none are free, most are unofficial/fragile; data goes stale hourly | Show "estimated cost" as a rough band using community-sourced prices in v2+ |
| Social recipe sharing / community feed | "Share your meals" sounds engaging | Recipe social networks (Prepear, Cookpad, Yummly) exist and have years of content; competing on social is a different product; it balloons infrastructure and moderation costs | Allow sharing individual recipes via link/export; community comes after product-market fit |
| Calorie and macro nutrition tracking | Users mention it; fitness-adjacent apps include it | Separate problem domain from meal planning (weight loss vs. waste reduction); nutrition data requires verified databases (USDA, Edamam Nutrition); adds complexity without serving core value prop | Show basic nutrition info per recipe if the recipe API provides it (Spoonacular includes this); don't build a tracker |
| Grocery delivery cart fill (Instacart/Woolworths) | One-tap order looks like obvious value-add | Requires retailer API partnerships; commission-based which affects pricing model; retailers change APIs without notice; wrong SKU matching creates frustration | Export shopping list as text/share sheet; let user copy-paste into their preferred delivery app |
| Gamification / streaks / badges | Increases session metrics in pitch decks | Meal planning is a utility, not a game; streaks create anxiety when users miss a week; adds significant UI/state complexity | Use engagement notifications thoughtfully; progress visualization ("You planned X meals this month") is enough |
| Full offline recipe creation/editing | Users want to add recipes without internet | Heavy local-first CRDT sync complexity; Paprika built their whole architecture around this; it's a separate product thesis | Offline read/use/shop is non-negotiable; offline create/edit can be deferred to v2 |

---

## Feature Dependencies

```
[User Auth / Account]
    └──required by──> [Meal Plan Storage]
                          └──required by──> [Shopping List Generation]
                          └──required by──> [Meal Plan Sync / Offline Cache]
    └──required by──> [Recipe Favorites]
    └──required by──> [Household Sharing]

[Ingredient Database / Recipe API]
    └──required by──> [Recipe Browsing]
                          └──required by──> [Assign Recipe to Meal Slot]
                                                └──required by──> [Shopping List Generation]
    └──required by──> [Ingredient-Based Recipe Discovery]

[Ingredient-Based Recipe Discovery]
    └──enhances──> [AI Recipe Generation] (AI fills gaps when catalog search returns nothing)

[Unit Normalization Engine]
    └──required by──> [Shopping List Deduplication]
    └──required by──> [Recipe Serving Size Scaling]

[Serving Size Scaling]
    └──enhances──> [Shopping List Generation] (scaled quantities feed into list)

[Offline Cache (SQLite/Drift)]
    └──required by──> [Offline Shopping List Access]
    └──required by──> [Offline Meal Plan Access]
    └──required by──> [Offline Recipe Browsing (cached)]

[Recipe Favorites]
    └──enhances──> [Meal Plan Templates] (favorites become template candidates)

[Dietary Filters]
    └──enhances──> [Recipe Browsing] (narrows result set)
    └──enhances──> [Ingredient-Based Discovery] (filters apply to both)
    └──enhances──> [AI Recipe Generation] (constraints passed in prompt)

[Push Notifications]
    ──conflicts──> [Offline-First UX] (notifications require connectivity; graceful degradation needed)
```

### Dependency Notes

- **Shopping List Generation requires Unit Normalization:** Without normalization, identical ingredients from different recipes produce duplicate line items in different units. This is a day-1 engineering decision — retrofitting normalization into an existing shopping list is painful.
- **AI Recipe Generation enhances Ingredient-Based Discovery:** These are separate features that share the same entry point (ingredient selection). AI is the fallback when the recipe API returns zero results. Build them as one unified flow with an AI fallback, not two separate surfaces.
- **Household Sharing requires User Auth:** Cannot share a meal plan between users without accounts and a group concept. Do not design auth schema without leaving room for household/group foreign keys.
- **Offline Cache must be designed before, not after, the recipe/plan features:** Retrofitting offline into an online-first Flutter app is extremely painful. The cache layer must be the source of truth from day one (local DB + sync), not an afterthought.

---

## MVP Definition

### Launch With (v1)

Minimum viable product — what's needed to validate the core concept and deliver the food waste + savings value prop.

- [ ] User auth (email/password via Supabase) — required to persist any data
- [ ] Ingredient selection with search and favorites — entry point for ingredient-based flow
- [ ] Recipe browsing from external API filtered by selected ingredients — core value delivery
- [ ] Dietary restriction filters (vegetarian, vegan, gluten-free, dairy-free) — required for ~30% of users
- [ ] Recipe detail view with scaling — needed before planning
- [ ] 7-day weekly meal planner (breakfast/lunch/dinner slots) — the calendar is the product
- [ ] Shopping list auto-generated from meal plan with unit normalization and deduplication — completes the core loop
- [ ] Manual shopping list editing (add/remove/check-off items) — without this, list is not usable in-store
- [ ] Offline access (cached meal plan + shopping list) — non-negotiable for in-store use
- [ ] AI recipe generation from selected ingredients (LLM fallback) — differentiator from day 1; fills gaps

### Add After Validation (v1.x)

Features to add once core loop is working and user feedback confirms direction.

- [ ] Recipe favorites / personal cookbook — trigger: users ask "how do I save this recipe?"
- [ ] Meal plan templates / saved weeks — trigger: users replanning same meals repeatedly
- [ ] Shopping list categorized by store section — trigger: user feedback about list organization
- [ ] Push notifications for dinner reminders — trigger: 4-week retention data shows drop-off without engagement prompt
- [ ] Household / shared shopping list — trigger: significant % of users are in families or shared households

### Future Consideration (v2+)

Features to defer until product-market fit is established.

- [ ] Price tracking / cost estimation — requires supermarket data infrastructure
- [ ] Pantry inventory tracking — separate product complexity; validate demand first
- [ ] Recipe import from URL — nice to have; schema.org parsing is brittle
- [ ] Grocery delivery integrations — requires retailer partnerships or unofficial APIs
- [ ] "What's expiring soon" smart suggestions — requires pantry tracking to be useful
- [ ] Social/community features — different product thesis; compete here after PMF

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Ingredient selection + search | HIGH | LOW | P1 |
| Recipe API browsing by ingredients | HIGH | MEDIUM | P1 |
| Dietary filters | HIGH | LOW | P1 |
| 7-day meal planner | HIGH | MEDIUM | P1 |
| Shopping list with deduplication | HIGH | HIGH | P1 |
| Unit normalization engine | HIGH | HIGH | P1 |
| Offline cache (read) | HIGH | HIGH | P1 |
| User auth + data sync | HIGH | LOW (Supabase) | P1 |
| AI recipe generation from ingredients | HIGH | MEDIUM | P1 |
| Recipe detail + scaling | HIGH | LOW | P1 |
| Manual shopping list editing | HIGH | LOW | P1 |
| Recipe favorites | MEDIUM | LOW | P2 |
| Store-section shopping list categories | MEDIUM | LOW | P2 |
| Meal plan templates | MEDIUM | MEDIUM | P2 |
| Drag-and-drop meal rescheduling | MEDIUM | LOW | P2 |
| Push notifications | MEDIUM | LOW | P2 |
| Household sharing | MEDIUM | HIGH | P2 |
| Pantry inventory tracking | LOW | HIGH | P3 |
| Price comparison | LOW | HIGH | P3 |
| Grocery delivery integration | LOW | HIGH | P3 |
| Recipe import from URL | LOW | MEDIUM | P3 |
| Social/community feed | LOW | HIGH | P3 |

**Priority key:**
- P1: Must have for launch — core loop is broken without it
- P2: Should have — adds significant value, build after core is stable
- P3: Nice to have — defer until product-market fit or v2

---

## Competitor Feature Analysis

| Feature | Mealime | Paprika | Eat This Much | Whisk (Samsung Food) | Plan to Eat | MealMate Approach |
|---------|---------|---------|---------------|----------------------|-------------|-------------------|
| Recipe browsing | Yes (curated) | Yes (import/web clip) | Yes (auto-generated) | Yes (web + community) | Yes (personal import) | Yes — external API + AI |
| Ingredient-based search | Partial (preferences) | No | Yes (budget + macros) | Yes | No | Yes — primary entry point |
| Dietary filters | Yes | Yes | Yes (macro-driven) | Yes | Yes | Yes — day 1 |
| Meal planner (7-day) | Dinner only | Yes (all meals) | Yes (all meals) | Yes | Yes | Yes — all meals |
| Shopping list auto-gen | Yes | Yes | Yes | Yes | Yes | Yes — with deduplication |
| Unit normalization | Partial | Yes | Yes | Partial | Partial | Yes — explicit engineering focus |
| Offline support | Partial (caching) | Yes (full offline-first) | No (online only) | Partial | Partial | Yes — full offline required |
| AI recipe generation | No | No | Algorithmic (not LLM) | No (as of 2024) | No | Yes — LLM-based differentiator |
| Food waste focus | No | No | No | No | No | Yes — core value proposition |
| Household sharing | No | No | No | Yes | Yes | v1.x |
| Pantry tracking | No | No | Partial | Yes (lite) | No | Out of scope v1 |
| Price data | No | No | No | No | No | Out of scope v1 |
| Pricing model | Freemium | One-time purchase | Subscription | Free (Samsung-backed) | Subscription | TBD — not v1 concern |

**Key insight:** No competitor combines (a) ingredient-first discovery, (b) AI recipe generation, and (c) explicit food waste reduction framing in a single cohesive mobile experience. Paprika has the best offline story but no AI. Whisk has the best social/sharing story but no waste focus. MealMate's gap is real and uncontested.

---

## Sources

- [Beyond Mealime: 7 Smart Meal-Planning Platforms Compared (2025)](https://centenary.day/blog/article/beyond-mealime-7-smart-mealplanning-platforms-compared-2025) — MEDIUM confidence (single source, but well-structured comparison)
- [Top Meal Planning App with Grocery List for 2025 — MealFlow Blog](https://www.mealflow.ai/blog/meal-planning-app-with-grocery-list) — MEDIUM confidence (vendor blog, but corroborated by other sources)
- [6 Meal Planning & Recipes Apps to Simplify Cooking and Cut Food Waste — Center for Food Conservation and Waste Reduction](https://conservefood.org/2025/07/02/6-meal-planning-recipes-apps-to-simplify-cooking-and-cut-food-waste/) — MEDIUM confidence (non-profit source, specific to food waste angle)
- [Eat This Much App Review: Pros and Cons — Plan to Eat](https://www.plantoeat.com/blog/2023/10/eat-this-much-app-review-pros-and-cons/) — MEDIUM confidence (competitor analysis, 2023 but still current)
- [How To Make a Meal Planning App like Whisk — IdeaUsher](https://ideausher.com/blog/how-to-make-app-like-whisk/) — LOW confidence (dev agency blog, content-gated)
- [The Best Meal-Planning Apps in 2026 — Ollie](https://ollie.ai/2025/10/21/best-meal-planning-apps-in-2025/) — LOW confidence (vendor-biased, Ollie is the winner in their own ranking)
- [Best Meal Planning Apps for Families in 2026 — Ollie](https://ollie.ai/2025/10/29/best-meal-planning-apps-2025/) — LOW confidence (same source as above)
- [Top 8 Features Of Highly Profiting Meal Planning Apps — Zazz](https://www.zazz.io/blog/top-8-features-of-highly-profiting-meal-planning-apps) — LOW confidence (content inaccessible during research)
- [Recipe App Statistics 2025 — ElectroIQ](https://electroiq.com/stats/recipe-app-statistics/) — MEDIUM confidence (market data, methodology unclear)
- [Mobile App Retention Benchmarks 2025 — growth-onomics](https://growth-onomics.com/mobile-app-retention-benchmarks-by-industry-2025/) — MEDIUM confidence (retention statistics corroborated across sources)
- [Paprika Recipe Manager](https://www.paprikaapp.com/) — HIGH confidence (official product site)
- [Plan to Eat](https://www.plantoeat.com/) — HIGH confidence (official product site)
- [Mealime](https://www.mealime.com/) — HIGH confidence (official product site)

---
*Feature research for: Meal planning mobile app (food waste reduction, ingredient-based, Flutter + Supabase)*
*Researched: 2026-03-02*
