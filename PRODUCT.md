# Product

<!-- impeccable:product-schema 1 -->

## Platform

android

## Stack

Expo (React Native) + TypeScript + Expo Router, one codebase for Android and Web (react-native-web, real DOM). TanStack Query for server data and offline persistence, Zustand for UI state. Supabase (Postgres, RLS, Realtime, Storage, Edge Functions) with Supabase Auth (Google + Magic Link). AI recipe generation through a Supabase Edge Function behind a provider interface: Claude first, a self-trained model later. Product data from Open Food Facts (ODbL). Separate static landing page with waitlist (SEO, demand test). The user owns an existing Supabase project; keys live in `.env`, never in code.

## Users

Primary: singles and couples aged 20–35 in Germany who cook for one or two, buy in supermarket pack sizes, and throw away the rest. Secondary: meal preppers who train and track macros. Later: families. The job: plan the week once, shop once, and actually use up what they bought.

## Product Purpose

MealMate plans the week so that everything you buy gets eaten, because it thinks in **package sizes and your pantry**, not only in recipes. Success: users still plan after 4 weeks (retention), and leftover suggestions get accepted.

## Positioning

Other planners start from the recipe. MealMate starts from fridge and package: it rounds the shopping list up to real package sizes, sees the leftover ("250 g Spinat übrig"), and plans it into another meal that week. Later it plans around what expires first and shows the measurable effect (grams/euros not wasted). Competitors: KptnCook, Choosy, Mealime, Kuri, Bring!.

## Operating Context

Planning happens on the couch on a Sunday (phone or laptop); shopping happens in the supermarket, one-handed, often with bad reception (offline list, sorted by aisle, check-off). Cooking happens in the kitchen with a recipe detail open (servings slider). German language, metric units, German supermarket aisles.

## Capabilities and Constraints

Milestone 1 (MVP): onboarding & preferences (household size, diet, dislikes, allergies as hard filters, cook-time limit, favourite ingredients); ingredient model with base units (g/ml/pcs), conversions, package sizes, aisles; recipes with search/filter, detail with live servings scaling, AI generation saved to DB; week planner 7 days × 3 slots with assign/swap/servings, leftover-of planning, auto-fill; shopping list that sums, rounds to packages, shows leftovers with recipe suggestions, keeps manual overrides across recalculation, offline check-off sorted by aisle.
Later: pantry & expiry (M2), households realtime, import, barcode (M3), prices (M4).
Constraints: all quantities stored in base units; allergies are always filtered hard against the database, never left to the AI; shopping list logic runs server-side (Postgres function) and identically client-side for offline, with unit tests; no scraping of retailer prices.
Monetisation (undecided pricing): Free planner/list/curated recipes; Premium ~3–5 €/month.

## Brand Commitments

Name: MealMate. Language: German, informal "du". The user asked for a look that is modern, professional, yet playful and exciting.

## Evidence on Hand

No users, testimonials, press, savings data or partner logos exist yet. Landing page must not fabricate any numbers, quotes or retailer partnerships; savings figures shown are illustrative examples and labelled as such.

## Product Principles

1. Think in packages, not portions: every quantity ends up as something you can buy.
2. Nothing left behind: a leftover is a prompt for the next meal, never a silent loss.
3. Plan once, shop once: the week takes minutes, the list builds itself.
4. Safety is not a suggestion: allergies and intolerances are hard filters.
5. Works in the aisle: offline, one-handed, fast.

## Accessibility & Inclusion

WCAG 2.2 AA contrast, touch targets ≥ 48 dp, full screen-reader labels, reduced-motion respected, no meaning conveyed by colour alone.
