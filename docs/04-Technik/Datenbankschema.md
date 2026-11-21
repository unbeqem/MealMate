---
title: Datenbankschema
date: 2026-11-21
tags: [technik, datenbank, supabase]
---

# Datenbankschema

Quelle der Wahrheit: [`supabase/migrations/20261121000001_init.sql`](../../supabase/migrations/20261121000001_init.sql) und [`…_rls.sql`](../../supabase/migrations/20261121000002_rls.sql).

## Tabellen

| Bereich | Tabellen | Hinweis |
|---|---|---|
| Nutzer | `profiles`, `households`, `household_members` | Trigger `handle_new_user` legt beim Signup Profil + eigenen Haushalt an |
| Zutaten | `ingredients`, `ingredient_aliases`, `package_sizes` | `id` = lesbarer Slug (`blattspinat`); `allergens text[]`, `diet_class`, `is_staple`, `unit_weights jsonb` |
| Rezepte | `recipes`, `recipe_ingredients`, `favorites`, `favorite_ingredients` | kuratiert = `is_public`, KI/eigene = privat (`created_by`) |
| Planung | `meal_plans`, `meal_plan_entries` | `is_leftover_of` verweist auf den Koch-Eintrag (Rest erzeugt keinen Bedarf) |
| Einkauf | `shopping_lists`, `shopping_list_items` | Merge-Schlüssel `key`; `manual_override`, `checked`, `orphaned` überleben Neuberechnung |
| M2 | `pantry_items` | vorbereitet |
| KI | `ai_generations` | Prompt, Rohantwort, nicht zugeordnete Zutaten → Trainingsbasis eigenes Modell |
| Landing | `waitlist` | anonym nur `insert` |

## Abweichungen vom Konzept

- `profiles.id uuid` (Supabase Auth statt Clerk).
- Zutaten und kuratierte Rezepte haben **Text-IDs** (Slugs), damit Seeds, Tests und SQL lesbar bleiben. KI-Rezepte bekommen UUID-Strings.
- Ernährungsform und Allergene werden aus den **Zutaten** abgeleitet, nicht aus Rezept-Tags.

## RLS-Kurzfassung

Stammdaten lesbar für alle. Rezepte: öffentlich oder eigene. Plan, Liste, Vorrat: nur Mitglieder des Haushalts (`is_household_member()`, security definer). Warteliste: nur Insert.

Related: [Setup Supabase](Setup-Supabase.md) · [Einkaufslisten-Algorithmus](Einkaufslisten-Algorithmus.md)
