---
title: Milestone 1 – Spezifikation (Design-Spec)
date: 2026-11-21
tags: [planung, spezifikation, m1]
aliases: [M1-Spec]
---

# Milestone 1 – Spezifikation

Ziel: ein benutzbarer MVP auf Android und Web, der eine Woche plant, Packungen rundet, Reste einplant und eine offline nutzbare Einkaufsliste erzeugt. Dazu eine Landingpage mit Warteliste.

## Getroffene Entscheidungen (21.11.2026)

| Frage | Entscheidung | Quelle |
|---|---|---|
| Auth | Supabase Auth: E-Mail-Code (OTP) + Google | Nutzer |
| App-Form | Eigenständige App (keine Fitness-App-Einbettung) | Nutzer |
| Landingpage | Statisch, mit Warteliste in Supabase | Nutzer |
| LLM | Claude zuerst, Provider austauschbar (eigenes Modell später) | Nutzer, [ADR-005](../02-Entscheidungen/ADR-005-LLM-Provider.md) |
| Designsprache | Eigene Marke, plattformgerecht | Nutzer |
| Visuelle Welt | „Der Kassenbon“ | Nutzer, [Design-Richtung](../03-Design/Design-Richtung-Kassenbon.md) |
| Repo | `github.com/unbeqem/MealMate`, Monorepo | Nutzer, [ADR-001](../02-Entscheidungen/ADR-001-Monorepo.md) |
| Supabase | Bestehendes Projekt des Nutzers; Keys nur in `.env` | Nutzer |

## Architektur

```
MealMate/ (Repo-Root = C:\Obsidian\mealmate\app)
├─ apps/mobile      Expo + Expo Router (Android + Web)
├─ apps/landing     statische Landingpage + Warteliste
├─ packages/core    reine TS-Logik: Einheiten, Skalierung, Einkaufsliste,
│                   Reste, Auto-Fill, Filter, Seed-Daten (mit Vitest-Tests)
├─ supabase/        Migrationen, RLS, seed.sql, Edge Functions
└─ docs/            diese Doku (im Obsidian-Vault als „MealMate“ eingebunden)
```

- **Eine Logik, zwei Orte:** `packages/core` läuft im Client (offline) und in der Edge Function `build-shopping-list` (Server). Beide rechnen identisch, siehe [ADR-002](../02-Entscheidungen/ADR-002-Geteilte-Logik.md).
- **Datenzugriff über ein Repository-Interface:** `SupabaseRepo` (mit `.env`) oder `LocalRepo` (Demo-Modus ohne Keys, AsyncStorage + Seed). Siehe [ADR-003](../02-Entscheidungen/ADR-003-Demo-Modus.md).
- **Styling:** typisierte Design-Tokens + `StyleSheet`, kein NativeWind. Siehe [ADR-004](../02-Entscheidungen/ADR-004-Styling.md).

## Datenmodell

Wie im [Konzept §6](../00-Konzept/MealMate-v2-Konzept.md#6-datenbankschema-mvp--vorbereitung-für-m2m3), mit diesen Präzisierungen:

- `profiles.id uuid` = `auth.users.id` (Supabase Auth → uuid, nicht text).
- `ingredients` bekommt `allergens text[]` (14 EU-Hauptallergene) und `diet_class` (`vegan` | `vegetarian` | `pescetarian` | `meat`). **Ernährungsform und Allergien werden aus den Zutaten abgeleitet und hart gefiltert**, nie aus KI-Tags.
- `ingredients.is_staple bool`: Grundzutaten (Salz, Pfeffer, Öl …) gelten als „Vorrat vorausgesetzt“.
- `profiles` bekommt `allergens text[]`, `onboarded_at`, `household_id` (Standard-Haushalt, wird beim Signup angelegt).
- `shopping_list_items` bekommt `aisle`, `label` (Anzeigename) und `leftover_suggestion jsonb`.
- `waitlist (id, email unique, source, created_at)` mit RLS: anonym nur `insert`.
- Details: [Datenbankschema](../04-Technik/Datenbankschema.md).

## Algorithmen

Siehe [Einkaufslisten-Algorithmus](../04-Technik/Einkaufslisten-Algorithmus.md). Kurz:
1. Bedarf summieren (Basiseinheit, Portionsfaktor). Reste-Einträge (`is_leftover_of`) erzeugen **keinen** Bedarf.
2. Packungen: kleinste Gesamtmenge ≥ Bedarf aus Kombinationen der Packungsgrößen (begrenzte Suche), bei Gleichstand die wenigsten Packungen.
3. Rest = Packung − Bedarf; ab Schwelle (≥ 15 % der Packung **und** ≥ 30 g/ml bzw. ≥ 1 Stück) werden Rezepte vorgeschlagen, die den Rest am besten aufbrauchen und die Filter erfüllen.
4. Neuberechnung behält manuelle Einträge, Overrides und Häkchen (Merge über `ingredient_id` bzw. `custom_name`).

**Auto-Fill:** Für die leeren Slots wählt ein Greedy-Verfahren Rezepte (Filter: Ernährung, Allergene, Abneigungen, Kochzeit), bevorzugt Rezepte, die bereits geplante Reste verwerten (Packungs-Synergie), und Lieblingszutaten. Abendessen mit Überschuss füllt das Mittagessen am Folgetag als Rest-Eintrag.

## Screens (M1)

| Route | Inhalt |
|---|---|
| `/sign-in` | E-Mail-Code + Google; im Demo-Modus „Ohne Konto ausprobieren“ |
| `/onboarding` | 4 Schritte: Haushalt → Ernährung & Allergien → Lieblingszutaten → erste Woche |
| `/(tabs)/plan` | Wochenleiste, Tag mit 3 Slots, Rezeptauswahl im Sheet, „Woche füllen“, Reste-Markierung |
| `/(tabs)/recipes` | Suche, Filter-Chips, Liste; „Mit KI erstellen“ |
| `/recipes/[id]` | Portionen-Regler (live), Zutaten mit Packungsbezug, Schritte, „Zum Plan“ |
| `/(tabs)/shopping` | „Der Bon“: nach Abteilung, Packungszeilen, REST-Zeilen markiert, abhaken, manuell hinzufügen |
| `/(tabs)/profile` | Präferenzen bearbeiten, Abmelden, Demo-Hinweis |

Navigation: Tabs unten (< 768 px), Sidebar links (≥ 768 px, Web).

## Nicht-Ziele für M1
Vorrat/Ablaufdaten, Push, Haushalte teilen, Import, Barcode, Preise. Das Schema ist dafür vorbereitet.

## Qualität
- Unit-Tests für `packages/core` (Einheiten, Packungen, Reste, Merge, Filter, Auto-Fill).
- WCAG 2.2 AA, Touch-Ziele ≥ 48 dp, `prefers-reduced-motion` respektiert.
- Playwright-Prüfung der Web-Version und der Landingpage.

Related: [Konzept](../00-Konzept/MealMate-v2-Konzept.md) · [Implementierungsplan](2026-11-21-M1-Implementierungsplan.md) · [Design-Richtung](../03-Design/Design-Richtung-Kassenbon.md)
