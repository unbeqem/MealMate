# Pitfalls Research

**Domain:** Meal planning mobile app (Flutter + Supabase + recipe APIs + AI generation + offline-first)
**Researched:** 2026-03-02
**Confidence:** MEDIUM (multiple sources, some claims training-data only — flagged)

---

## Critical Pitfalls

### Pitfall 1: Auto-Incremented Primary Keys Break Offline Sync

**What goes wrong:**
The app creates records on-device while offline (new meal plan entries, custom recipes, shopping list items). When using integer auto-increment IDs (Supabase `serial`/`bigserial`), two clients generate ID=1, ID=2, etc. independently. On sync, these collide — Supabase rejects inserts, merges corrupt data, or silently overwrites records.

**Why it happens:**
Developers add tables in Supabase with the default `id bigint generated always as identity` primary key and don't think about what happens when the client generates records offline without hitting the DB.

**How to avoid:**
Use UUID v4 primary keys (`gen_random_uuid()`) for all user-facing tables from day one. Generate UUIDs client-side before insert. This is non-negotiable for any offline-first design. Change this after launch requires a data migration that touches every foreign key reference.

**Warning signs:**
- Any table using `serial`, `bigserial`, or `generated always as identity` that will have records created offline
- If you catch yourself thinking "I'll add offline support later" while building with integer IDs

**Phase to address:** Foundation / Database Schema phase — this must be decided before writing a single insert

---

### Pitfall 2: Offline Sync Built From Scratch Instead of Using Proven Solutions

**What goes wrong:**
Teams build custom sync logic: a `pendingSync: true` flag, a background queue, retry logic. Initially this works. Then edge cases emerge: partial sync failures, sync during app backgrounding, conflict when the same recipe is edited on two devices, network errors mid-batch. The custom sync layer becomes the most complex and buggy part of the app.

**Why it happens:**
Supabase does not have built-in offline support. The `supabase_flutter` package is online-first. Developers underestimate how many edge cases offline sync has (conflict resolution, queue durability, app lifecycle events, schema migrations).

**How to avoid:**
Use `brick_offline_first_with_supabase` (the Brick framework) or PowerSync from the start. Both are purpose-built for Supabase + Flutter offline scenarios. Brick abstracts the local SQLite + Supabase duality behind a single repository pattern with automatic retry queuing. PowerSync provides bidirectional sync with conflict resolution built in. Choosing one of these before writing offline logic saves weeks.

**Warning signs:**
- `SharedPreferences` being used to store pending sync operations
- A bespoke `SyncService` class with more than 200 lines
- No automated test that simulates "go offline, make changes, come back online, verify consistency"

**Phase to address:** Offline Support phase — must select the sync library before writing any data persistence code

---

### Pitfall 3: Ingredient Unit Normalization Treated as a Simple Lookup Table

**What goes wrong:**
Shopping list aggregation fails or produces nonsense. "2 cups flour" + "150g flour" cannot be summed without knowing the flour density. "1 can tomatoes" + "400ml tomatoes" are incompatible because the can volume is unspecified. "1 tbsp olive oil" from Recipe A + "30ml olive oil" from Recipe B need a volume conversion. The result is a shopping list showing "2 cups + 150g flour" as separate items, confusing users.

**Why it happens:**
Developers implement unit normalization as a two-step process: (1) same unit → sum, (2) different unit → keep separate. This handles the trivial cases but not mixed volumetric/mass units for the same ingredient. Ingredient-specific density data is required to cross unit families (volume ↔ mass).

**How to avoid:**
Design the normalization pipeline upfront with these distinct layers:
1. **Lexical normalization** — "tsp" → "teaspoon", "g" → "grams", strip adjectives ("fresh", "diced")
2. **Unit family classification** — volume (ml/L/cups/tbsp/tsp), mass (g/kg/oz/lb), count (piece/can/bunch)
3. **Intra-family conversion** — standardize all volume to ml, all mass to grams
4. **Cross-family handling** — when units are incompatible (e.g., "cups flour" + "grams flour"), display both with a visual merge hint rather than silently dropping or erroneously summing
5. **Ingredient-specific density table** — for the ~20 most common baking/cooking ingredients (flour, sugar, butter, milk), store g/ml density to enable optional cross-conversion

Do NOT attempt to normalize count units ("2 cans" + "800ml") automatically — this is a product decision, not a technical one.

**Warning signs:**
- No dedicated `IngredientUnit` domain model (just raw strings)
- Unit tests for normalization only cover the happy path (same unit, same ingredient)
- "We'll sort the units out after recipes work"

**Phase to address:** Shopping List / Ingredient Logic phase — normalization logic should be isolated, unit-tested exhaustively, before the shopping list UI is built

---

### Pitfall 4: Supabase RLS Disabled or Misconfigured, Exposing All User Data

**What goes wrong:**
In January 2025, 170+ apps (many built with Lovable) exposed their Supabase databases because RLS was not enabled. Any authenticated user could read, modify, or delete other users' meal plans, recipes, and shopping lists via direct API calls.

**Why it happens:**
RLS is **disabled by default** in Supabase. Developers create tables, test with the SQL editor (which runs as the `postgres` superuser and bypasses RLS entirely), see everything works, and ship. Real users hitting the API have no policies protecting their data.

**How to avoid:**
- Enable RLS on every table immediately after creation: `ALTER TABLE [table] ENABLE ROW LEVEL SECURITY`
- Create policies immediately — RLS with no policies is "deny all", which will break the app
- Never test RLS correctness in the Supabase SQL editor; test via the client SDK with a real JWT
- Add `user_id` indexes: a policy `user_id = auth.uid()` does a full table scan without an index
- Use `WITH CHECK` on INSERT/UPDATE policies, not just USING — without it, users can insert/update rows with arbitrary `user_id` values
- Never expose the `service_role` key in Flutter app code — it bypasses all RLS

**Warning signs:**
- Tables created without an immediate `ENABLE ROW LEVEL SECURITY` migration
- "It works in the Supabase dashboard" treated as RLS validation
- Missing index on `user_id` columns in large tables

**Phase to address:** Auth / Database Schema phase — RLS policies should be written alongside table creation, not added as a "security pass" later

---

### Pitfall 5: AI Recipe Generation Produces Hallucinated Quantities and Invalid Ingredients

**What goes wrong:**
The AI generates recipes where ingredient quantities are nonsensical ("1/8 egg", "0.3 onions"), units mismatch the ingredient type ("3 cups of salt"), or ingredients outside the user's selected list are introduced. These recipes feed directly into the unit normalization and shopping list aggregation pipeline — poisoning the data.

**Why it happens:**
LLMs (including GPT-4) hallucinate in specialized domains. Recipe generation requires understanding of ingredient physics (you can't split an egg into eighths for a recipe), natural ingredient-unit pairings, and cooking conventions. General-purpose LLMs lack consistent grounding without constraints.

**How to avoid:**
- Use **structured output / JSON schema enforcement** on the AI call — define a strict schema for `{ ingredient: string, quantity: number, unit: enum }` and reject malformed responses
- Validate generated ingredients against a known ingredient list — reject or flag any ingredient not in the database
- Add sanity checks: quantity > 0, quantity < 10000, unit is in the allowed enum
- Do not allow AI-generated recipes to flow directly into shopping list aggregation without a validation layer
- Consider RAG: pass the user's selected ingredients as explicit context ("you MUST only use these ingredients") to constrain generation

**Warning signs:**
- AI recipe generation tested only with "happy path" prompts in development
- No validation between AI response parsing and database insert
- Recipes created by AI not marked with a `source: 'ai'` flag (needed for validation pass and user trust UI)

**Phase to address:** AI Recipe Generation phase — validation must be spec'd before the AI integration is written

---

## Moderate Pitfalls

### Pitfall 6: Supabase Realtime Subscriptions Leak Memory in Long-Running Sessions

**What goes wrong:**
Supabase Realtime uses WebSocket subscriptions. If Flutter widgets subscribe in `initState` without unsubscribing in `dispose`, subscriptions accumulate across navigation events. Documented behavior: after extended runtime (hours), streams stop receiving new data with no error thrown. Memory usage grows.

**How to avoid:**
- Always call `supabase.removeChannel(channel)` in `dispose()`
- Prefer `StreamBuilder` with the subscription lifecycle managed by the widget tree
- For screens that navigate away and back frequently, consider page-level providers that manage subscription lifetime rather than widget-level subscriptions
- Write a simple integration test that navigates to/from a subscribed screen 20 times and checks memory

**Phase to address:** Realtime/Sync phase

---

### Pitfall 7: Recipe API Rate Limits Exhausted in Development/Testing

**What goes wrong:**
Spoonacular's free tier is points-based (not just call-count). Complex endpoints cost more points. A day of active development, combined with a team of two developers and automated tests hitting the API, can exhaust daily quotas in hours. This blocks all further development until the next day's quota resets.

**How to avoid:**
- Cache ALL recipe API responses to a local SQLite database from the first day of integration — key: `{endpoint}:{params_hash}`; TTL: 24h for search results, indefinite for individual recipes
- Mock the API in tests — never call the live API in unit or integration tests
- Set a single API key for each environment (dev, staging, prod) with monitoring
- Edamam has a known data completeness issue: recipe ingredient lists returned by search are often incomplete compared to the actual recipe page — always fetch full recipe detail separately, not just search results

**Phase to address:** Recipe API Integration phase

---

### Pitfall 8: Offline-First Considered "Phase 2" Architecture

**What goes wrong:**
The app is built online-first (all data fetched from Supabase, no local persistence). Offline support is treated as a feature addition. Adding it later requires: replacing all `supabase.from().select()` calls with a repository layer, adding a local database, writing migration code for existing users' data, and re-thinking every loading state.

**Why it happens:**
Offline-first feels like premature optimization early on. The PROJECT.md states "full offline capability" is a v1 requirement, but under time pressure teams defer it.

**How to avoid:**
Build behind a `RecipeRepository` / `MealPlanRepository` abstraction from day one. The concrete implementation can start as "Supabase-only", but the interface must be the same interface that will later back a local SQLite cache. This costs one day of setup and saves a week of refactoring.

**Warning signs:**
- Direct `Supabase.instance.client.from('recipes').select()` calls inside widget files
- No repository or data-source abstraction layer
- "We'll add the offline layer after the MVP is working"

**Phase to address:** Architecture / Foundation phase

---

### Pitfall 9: GDPR Data Deletion Treats Account Delete as Profile Row Delete

**What goes wrong:**
A user invokes their right to erasure. The app deletes their `profiles` row in Supabase. But their data also exists in: Supabase auth records, analytics events (if any), third-party SDKs (crash reporters, analytics), AI provider logs (if prompts are logged), and potentially recipe API provider logs. The deletion is legally incomplete.

**How to avoid:**
- Map all data flows before writing a single line of GDPR-related code
- For each third-party service (AI provider, recipe API, crash reporter), check their data deletion API or DPA
- Implement a Supabase Edge Function as the "delete account" endpoint that: (1) deletes all user rows in cascade, (2) deletes the auth user, (3) queues deletion requests to third parties
- Do not pass PII in AI generation prompts (no user name, email, or identifiers in recipe generation requests)
- Store only what is needed — if recipe browsing history is only used for personalization, make it opt-in so deletion is clean

**Warning signs:**
- "Delete account" implemented as a client-side `supabase.auth.signOut()` + `profiles.delete()`
- No documented data flow map showing where user data is stored
- Third-party SDKs added without a privacy review

**Phase to address:** Auth phase (data deletion endpoint) and before any analytics/third-party SDK integration

---

### Pitfall 10: SQLite Schema Migrations Not Versioned from the Start

**What goes wrong:**
The local SQLite schema changes during development. On existing installs, the old schema remains. The app crashes on launch for users who had the previous version. On Drift (the recommended local DB), this is preventable but requires exporting schema JSON snapshots before each change.

**How to avoid:**
- Use Drift for local SQLite — it has a migration system and validates migrations against exported schema snapshots
- Treat every schema change as a migration, even in early development
- Never run `DROP TABLE; CREATE TABLE` as a migration strategy in any version that has been installed on a real device
- Test migrations explicitly: start from version N, apply migration to N+1, verify data integrity

**Warning signs:**
- Schema changes handled by deleting and reinstalling the app during development
- No `schemaVersion` increment when adding a column
- Migration code written as "TODO: handle migration"

**Phase to address:** Local Database / Foundation phase

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Direct Supabase calls in widget code | Faster early development | Cannot swap to offline cache without rewriting all widgets | Never — use a repository layer |
| Integer primary keys instead of UUIDs | Slightly simpler DB setup | Offline record creation impossible without collision | Never for offline-first tables |
| Skipping RLS "for now" | Faster iteration | Security breach, rewrite required | Never |
| Mocking AI responses always in dev | Faster dev loop | AI failures never discovered until production | Acceptable for unit tests; integration tests must use real AI |
| Single Spoonacular API key across all environments | Zero setup cost | Dev/test exhausts prod quota | Never — use separate keys per environment |
| Last-Write-Wins for all conflict resolution | Simple implementation | Silent data loss if two devices edit the same meal plan offline | Acceptable for meal plan data; NOT for shopping list edits |
| Hard-coding unit conversion factors in code | Fast initial build | International users use different conventions (e.g., Australian "cup" = 250ml vs US "cup" = 237ml) | Acceptable for MVP if documented; must be revisited for internationalization |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Spoonacular | Summing points per-call without checking endpoint cost weights | Budget by `X-API-Quota-Used` response header; log daily consumption from day 1 |
| Edamam | Trusting ingredient lists from search results | Always fetch individual recipe detail endpoint; search results truncate ingredients |
| Supabase Auth | Using `user_metadata` claims in RLS policies | Only use `auth.uid()` in policies — `user_metadata` can be modified by authenticated users |
| Supabase Realtime | Subscribing at widget level without lifecycle management | Subscribe at provider/bloc level, dispose explicitly |
| OpenAI / AI provider | Sending user PII in recipe generation prompts | Keep prompts to ingredients + preferences only; never include name, email, or user ID |
| PowerSync / Brick | Using both PowerSync and Brick for the same data | Pick one sync library; mixing creates dual-cache consistency problems |
| Supabase Flutter v2 | Using pre-v2 auth flow patterns from tutorials | `Provider` enum renamed to `OAuthProvider` in v2; check the upgrade guide for other breaking changes |

---

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| No index on `user_id` in RLS policies | Queries slow as user data grows; Supabase shows sequential scans | Add index on every `user_id` column at table creation | ~1,000 rows per user |
| Fetching full recipe list on every meal plan load | Slow meal planner screen, high API cost | Cache recipes locally; only fetch changed records (delta sync) | ~50 recipes in the plan |
| N+1 queries: loading ingredients for each recipe separately | Waterfall of Supabase requests; slow plan view | Batch ingredient fetch by recipe ID array; use Supabase `in` filter | 5+ recipes displayed simultaneously |
| Re-running unit normalization on every shopping list render | Janky scroll / UI lag | Normalize on write (when adding recipe to plan), cache normalized result | ~20 ingredients in shopping list |
| Full recipe text in Supabase Realtime payload | Large payload over WebSocket; slow sync | Use Realtime only for IDs/change signals; fetch full data from DB on change event | Recipes > 5KB |

---

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| `service_role` key in Flutter app code | Full DB bypass, any user can read/write all data | Service role key only in server-side code (Edge Functions) — never in the app bundle |
| No RLS on `meal_plans` or `shopping_lists` tables | Any authenticated user reads/modifies other users' data | Enable RLS + user_id policy on every user-data table |
| Missing `WITH CHECK` on INSERT/UPDATE policies | Users can inject rows with another user's `user_id` | Always include `WITH CHECK (auth.uid() = user_id)` on write policies |
| PII in AI prompt logs | AI provider stores personal data without DPA | Strip all PII from prompts; use only ingredients and preference labels |
| Recipe API key in mobile app bundle | Key extracted from APK/IPA, quota stolen | Proxy all recipe API calls through a Supabase Edge Function; never embed third-party API keys in the Flutter app |

---

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| No visual indicator of offline state | User edits data, app appears to save, edits silently fail or queue invisibly | Show persistent offline banner; show "pending sync" indicator on edited items |
| Shopping list shows "2 cups + 150g flour" as separate items | Users confused; can't shop effectively | Cross-family unit conflicts should show as a merged item with a "units differ" note, not two entries |
| AI recipe generation with no loading feedback (can take 3-8s) | User taps Generate multiple times; duplicate recipes created | Disable Generate button during request; show streaming progress if using streaming API |
| Meal planner populated with no recipe thumbnails | App feels empty and low-quality | Cache recipe thumbnails locally; show placeholder shimmer while loading |
| No undo for "remove recipe from plan" | Users accidentally delete a week's planning | Implement snackbar undo with 5s window for all destructive actions in the planner |
| Shopping list with 40+ items in a flat list | Users skip items, lose their place in the store | Group by store aisle/category by default; this is table-stakes in competing apps |

---

## "Looks Done But Isn't" Checklist

- [ ] **Offline support:** App loads and all screens are navigable without network — verify by toggling airplane mode on a real device, not just disabling Wi-Fi in emulator
- [ ] **Shopping list deduplication:** Same ingredient from two different recipes appears once with summed quantity — verify with two recipes sharing "olive oil" with different units
- [ ] **RLS:** A user cannot read another user's meal plan by calling the Supabase API directly with their own JWT — verify with a manual API test using two test accounts
- [ ] **Auth persistence:** App session survives app restart and device reboot without requiring re-login — verify by force-stopping the app
- [ ] **AI recipe saved to local DB:** AI-generated recipe is available offline after generation — verify by generating a recipe, toggling airplane mode, closing and reopening the app
- [ ] **Sync conflict:** If the same meal plan is edited on two devices while offline, sync resolves without data loss or crash — test with two emulators
- [ ] **Account deletion:** Deleting an account removes all personal data from Supabase auth, profiles, meal_plans, recipes, shopping_lists — verify with a DB query after deletion
- [ ] **Rate limit graceful handling:** App shows a meaningful error when recipe API quota is exceeded, not a raw 429 — verify by mocking a 429 response

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Integer PKs discovered after data exists | HIGH | Schema migration renaming all PKs and FK references; coordinate with existing users' local caches — may require full DB reset |
| RLS never enabled, breach discovered | HIGH | Enable RLS immediately; audit access logs; notify affected users per GDPR Article 33 (72h breach notification) |
| Custom sync layer too complex to maintain | HIGH | Migrate to Brick or PowerSync; requires replacing all data access code |
| AI-generated bad data in production DB | MEDIUM | Add `source = 'ai'` flag to recipes; add a bulk validation script; allow users to report AI recipes |
| Recipe API key embedded in app bundle | MEDIUM | Rotate key immediately; add Edge Function proxy; ship new app version; old versions will fail gracefully if key is revoked |
| Missing schema migration breaks existing installs | MEDIUM | Ship a patch that detects old schema version and runs a recovery migration; add rollback path |
| GDPR erasure request missed third-party data | MEDIUM | Contact third-party DPOs for deletion; document corrective action; update deletion endpoint to cover all systems |

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Auto-increment PKs break offline | Phase 1: Database Schema | All tables use UUID PKs; confirm with schema inspection |
| Custom sync layer | Phase 2: Offline Architecture | Brick or PowerSync chosen; repository layer exists before any feature code |
| Unit normalization naivety | Phase 3: Shopping List Logic | Unit tests cover: same unit, cross-volume units, mass+volume conflict, count units |
| RLS misconfiguration | Phase 1: Auth + Database | RLS enabled on all tables; manual API test with two JWT tokens confirms isolation |
| AI hallucinated data | Phase 4: AI Recipe Generation | JSON schema validation test; ingredient whitelist validation; quantity sanity checks |
| Realtime memory leaks | Phase 2: Offline/Sync | Widget test that mounts/unmounts subscribed screen 20x and checks no active channels remain |
| Recipe API rate exhaustion | Phase 3: Recipe API Integration | Mock in tests; caching layer verified; API key per environment |
| Offline treated as Phase 2 | Phase 1: Architecture | Repository abstraction in place before first Supabase call |
| GDPR incomplete deletion | Phase 1: Auth (deletion endpoint) | Deletion test deletes all rows across all tables + auth user |
| SQLite schema migrations | Phase 1: Local DB Setup | Drift schemaVersion incremented; migration test runs from V1→current |
| RLS on analytics SDK | Any third-party SDK integration | Privacy review before adding any SDK; confirm no PII in event payloads |

---

## Sources

- [Supabase offline-first Flutter with Brick — Supabase Blog](https://supabase.com/blog/offline-first-flutter-apps) (MEDIUM confidence — official Supabase blog)
- [Supabase offline support discussion — GitHub orgs/supabase](https://github.com/orgs/supabase/discussions/357) (MEDIUM confidence)
- [PowerSync: Offline-First for Supabase](https://www.powersync.com/blog/bringing-offline-first-to-supabase) (MEDIUM confidence)
- [Flutter offline-first architecture Part 1 — DEV Community](https://dev.to/anurag_dev/implementing-offline-first-architecture-in-flutter-part-1-local-storage-with-conflict-resolution-4mdl) (LOW confidence — community article)
- [Flutter offline-first architecture Part 2 — DEV Community](https://dev.to/anurag_dev/implementing-offline-first-architecture-in-flutter-part-2-building-sync-mechanisms-and-handling-4mb1) (LOW confidence)
- [Supabase RLS misconfigurations — ProsperaSoft](https://prosperasoft.com/blog/database/supabase/supabase-rls-issues/) (MEDIUM confidence)
- [170+ apps exposed by missing RLS — ByteIota](https://byteiota.com/supabase-security-flaw-170-apps-exposed-by-missing-rls/) (MEDIUM confidence — corroborated by multiple sources)
- [Supabase RLS docs — Official](https://supabase.com/docs/guides/database/postgres/row-level-security) (HIGH confidence)
- [RLS complete guide 2026](https://vibeappscanner.com/supabase-row-level-security) (MEDIUM confidence)
- [Supabase Realtime memory leak diagnosis](https://drdroid.io/stack-diagnosis/supabase-realtime-client-side-memory-leak) (LOW confidence)
- [Supabase Realtime issues #1012 — GitHub](https://github.com/supabase/supabase-flutter/issues/1012) (MEDIUM confidence — official issue tracker)
- [GDPR compliance for Flutter apps — Hasan Karli, Medium](https://hasankarli.medium.com/gdpr-compliance-in-flutter-mobile-applications-020751582e60) (LOW confidence)
- [GDPR mobile app compliance 2025 — Didomi](https://www.didomi.io/blog/mobile-app-compliance-2025) (MEDIUM confidence)
- [Best Recipe APIs 2025 — EatHealthy365](https://eathealthy365.com/best-recipe-apis-2025-a-developer-s-deep-dive/) (LOW confidence)
- [Spoonacular deep dive 2025](https://eathealthy365.com/spoonacular-api-a-deep-dive-for-developers-in-2025/) (LOW confidence)
- [AI LLM recipe generation hallucinations — DEV Community](https://dev.to/digitalcanvas-dev/aillm-recipe-generator-with-chatgpt-4dnk) (LOW confidence)
- [AI recipe generation RAG approach — Medium](https://medium.com/@honest_amaranth_pug_100/ai-recipe-generation-with-rag-build-a-smarter-recipe-bot-b8f7dadb8a95) (LOW confidence)
- [Drift local database Flutter migration](https://drift.simonbinder.eu/guides/migrating_to_drift/) (HIGH confidence — official Drift docs)
- [Improving meal plans with LLMs: compound ingredients — PMC/NIH](https://pmc.ncbi.nlm.nih.gov/articles/PMC12073434/) (MEDIUM confidence — peer-reviewed)
- [Flutter offline-first official design patterns](https://docs.flutter.dev/app-architecture/design-patterns/offline-first) (HIGH confidence — official Flutter docs)

---
*Pitfalls research for: meal planning mobile app (Flutter + Supabase + recipe APIs + AI)*
*Researched: 2026-03-02*
