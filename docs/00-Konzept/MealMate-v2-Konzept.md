---
title: MealMate v2 – Produktkonzept & technische Grundlage
date: 2026-11-21
tags: [konzept, produkt, quelle]
aliases: [Konzept, Produktkonzept]
---

# MealMate v2 – Produktkonzept & technische Grundlage

> [!NOTE]
> Originalkonzept, wie geliefert. Entscheidungen, die davon abweichen oder es präzisieren, stehen in den [Entscheidungen](../02-Entscheidungen/INDEX.md). Festgelegt am 21.11.2026: **Supabase Auth**, **eigenständige App**, **Landingpage mit Warteliste**, **Claude als erstes LLM (später eigenes Modell)**, **eigene Marke, plattformgerecht**.

> **Vision:** MealMate plant deine Woche so, dass alles, was du kaufst, auch aufgegessen wird – weil die App in **Packungsgrößen und deinem Vorrat** denkt, nicht nur in Rezepten.

## 1. Ausgangslage & Positionierung

### Problem
- Haushalte kaufen zu viel, werfen Reste weg und planen ineffizient.
- Rezepte brauchen „200 g Spinat“, die Packung hat aber 450 g → der Rest landet im Müll.
- Einkaufslisten werden jede Woche manuell zusammengesucht.

### Markt (Stand Ende 2026)
Der Markt für Meal Planner ist voll: KptnCook, Choosy (inkl. Budget-Wochenplan), Mealime, Kuri, Bring! (Einkaufsliste mit Prospekten von Kaufland, Penny, Netto). Ein „weiterer Wochenplaner mit Einkaufsliste“ hat kaum Chancen.

### Differenzierung (USP)
Andere planen ab dem **Rezept**. MealMate plant ab **Kühlschrank und Packung**:
1. **Packungsgrößen mitdenken:** Restmengen werden erkannt und automatisch in weiteren Rezepten der Woche eingeplant.
2. **Vorrat & Ablaufdaten als Ausgangspunkt:** „Das muss diese Woche weg – plan mir was drumherum.“
3. **Messbarer Effekt:** „Diesen Monat 2,1 kg / 23 € weniger weggeworfen.“

### Mögliche Nische
Meal Prep mit Makros für Leute, die trainieren → MealMate als Ernährungsmodul einer Fitness-App bzw. für Fitnessstudios.

### Zielgruppe (Start)
- **Primär:** Singles & Paare von 20 bis 35 (bei Einzelportionen fällt am meisten Verschwendung an)
- **Sekundär:** Meal-Prepper / Leute, die trainieren
- **Später:** Familien

## 2. Tech-Stack

| Bereich | Entscheidung | Begründung |
|---|---|---|
| Plattformen | Android + Web | Eine Codebasis |
| Frontend | **Expo (React Native) + TypeScript + Expo Router** | Android & Web aus einem Code; Web mit echtem DOM (besser als Flutter Web) |
| Serverdaten | **TanStack Query** | Caching, Offline-Persistenz, Refetching |
| UI-State | **Zustand** | Schlank, wenig Boilerplate |
| Styling | NativeWind oder Tamagui | Responsive, Plattform-übergreifend |
| Backend | **Supabase** | Postgres, RLS, Realtime, Storage, Edge Functions |
| Auth | **Supabase Auth** (MVP) oder **Clerk** | siehe unten |
| KI | LLM-API über Supabase Edge Function | API-Keys bleiben serverseitig |
| Produktdaten | Open Food Facts | Offen, Barcodes, Nährwerte (ODbL beachten) |

### Auth-Entscheidung: Supabase Auth vs. Clerk
- **Supabase Auth (Empfehlung für den MVP):** weniger Aufwand, ein Anbieter, Google-Login + Magic Link reichen.
- **Clerk:** sinnvoll bei Bedarf an fertiger Login-UI, Organizations (→ Haushalte) oder späterem B2B.
  - Native Third-Party-Auth-Integration in Supabase verwenden (das alte JWT-Template ist seit 04/2025 veraltet).
  - Clerk synchronisiert keine User in Supabase → Webhook (`user.created`) → Edge Function legt `profiles`-Zeile an.
  - RLS über `auth.jwt()->>'sub'`; `user_id`-Spalten sind dann `text` statt `uuid`.
- ⚠️ **Vor dem Datenmodell entscheiden**, weil sich die Typen der User-IDs unterscheiden.

### Rezeptdaten: hybrider Ansatz
1. **Eigene, kuratierte Rezeptdatenbank** (deutsch, 150–300 Rezepte zum Start)
2. **LLM-Rezeptgenerator** mit festem JSON-Schema, gemappt auf die eigene Zutatentabelle, validiert und gespeichert
3. **Open Food Facts** für Produkte, Barcodes, Nährwerte
4. Spoonacular / TheMealDB höchstens zum Experimentieren (englisch; Spoonacular verlangt, dass alle Daten gelöscht werden, wenn man die API nicht mehr nutzt)

### Layout Android vs. Web
- Geteilt: Logik, Datenzugriff, State, Validierung, die meisten Komponenten
- Pro Plattform: Navigation (Tabs unten vs. Sidebar), Seitenaufbau, einzelne Interaktionen
- Umsetzung über `useWindowDimensions` (Breakpoints), `*.web.tsx`-Dateien, `Platform.OS`, eigene `_layout`-Dateien in Expo Router
- Landingpage separat (z. B. Next.js oder statisch) für SEO und Wartelisten-Test

## 3. Funktionsumfang

### Milestone 1 – MVP

**M1.1 Onboarding & Präferenzen**
- Haushaltsgröße, Ernährungsform, Abneigungen, Unverträglichkeiten (harte Filter), Kochzeit-Limit
- Lieblingszutaten auswählen

**M1.2 Zutatenmodell (Fundament)**
- Eigene Zutatentabelle mit deutschen Namen + Synonymen
- Basiseinheit pro Zutat (g / ml / Stück) + Umrechnungswerte (Gewicht pro Stück, Dichte)
- Typische Packungsgrößen (z. B. Spinat 450 g, Sahne 200 ml, Eier 6/10 Stück)
- Supermarkt-Abteilung → nach Gängen sortierte Einkaufsliste

**M1.3 Rezepte**
- Suche & Filter: Kategorie, Zutaten, Zeit, Ernährungsform
- Detailansicht mit Portionen-Regler (rechnet live um)
- „Generiere mir ein Rezept mit …“ (KI, Ergebnis wird gespeichert)

**M1.4 Wochenplaner**
- 7 Tage × Frühstück / Mittag / Abend (Slots optional)
- Rezept zuweisen, tauschen, Portionen pro Eintrag
- **Reste einplanen:** Abendessen mit 2 Portionen → füllt das Mittagessen am nächsten Tag
- „Woche automatisch füllen“

**M1.5 Einkaufsliste**
- Zusammenfassen: normalisieren → gleiche Zutaten bündeln → summieren → **auf Packungen aufrunden**
- **Restanzeige:** „250 g Spinat übrig → Vorschlag: Rezept X“
- Manuelle Einträge & Korrekturen, die bei Neuberechnung erhalten bleiben
- Abhaken, offline nutzbar, Sortierung nach Abteilung

### Milestone 2 – Vorrat & Verschwendung
- Vorrat mit Ablaufdaten; Abgehaktes landet automatisch im Vorrat
- Planung ab dem Vorrat: „Nutze zuerst, was bald abläuft“
- Push-Benachrichtigung: „Die Sahne läuft morgen ab – heute Abend Rezept Y?“
- Statistik zur Verschwendung (Gramm / Euro pro Monat)

### Milestone 3 – Gemeinsam nutzen & Komfort
- **Haushalte:** gemeinsamer Plan + Einkaufsliste in Echtzeit (Supabase Realtime)
- **Rezept-Import per KI:** URL oder Foto → strukturiertes Rezept
- Barcode-Scan (Open Food Facts) zum Befüllen des Vorrats
- Nährwerte & Makros (optional mit Fitness-App-Anbindung)

### Milestone 4 – Preise (realistisch)
- **Stufe 1:** Nutzer pflegen selbst Preise ein → persönliche Preishistorie & Budget-Modus
- **Stufe 2:** Angebotsbasierte Rezeptvorschläge nur über offizielle Partner oder Lizenzdaten (kein Scraping)
- **Stufe 3:** Affiliate-Partnerschaften mit Lieferdiensten oder Händlern

## 4. Monetarisierung
- **Free:** Planer, Einkaufsliste, kuratierte Rezepte
- **Premium (ca. 3–5 €/Monat):** unbegrenzte KI-Rezepte, Vorratslogik, Haushalte, Statistik
- **Später B2B:** Ernährungsmodul für Fitnessstudios bzw. eine Fitness-App

## 5. Architektur

```
┌──────────────────────────────┐
│  Expo App (Android + Web)    │
│  TanStack Query · Zustand    │
│  lokaler Cache (offline)     │
└──────────┬───────────────────┘
           │ supabase-js (RLS-geschützt)
┌──────────▼───────────────────┐
│  Supabase                    │
│  Postgres + RLS + Realtime   │
│  Storage (Rezeptbilder)      │
│  Edge Functions:             │
│   • generate-recipe (LLM)    │
│   • import-recipe (URL/Foto) │
│   • build-shopping-list      │
│   • clerk-webhook (optional) │
└──────────┬───────────────────┘
           │
   LLM-API · Open Food Facts
```

- Kein eigener Node-Server im MVP nötig.
- Die Einkaufslisten-Logik läuft **serverseitig** (Postgres-Funktion oder Edge Function), damit Web und Android identisch rechnen und die Logik testbar ist.

## 6. Datenbankschema (MVP + Vorbereitung für M2/M3)

```sql
profiles            (id text PK /*Clerk sub o. auth.uid*/, display_name, household_size,
                     diet text[], dislikes uuid[], max_cook_minutes, created_at)
households          (id uuid PK, name, created_by)
household_members   (household_id, user_id, role)
ingredients         (id uuid PK, name_de, base_unit, grams_per_piece, density_g_per_ml,
                     aisle, shelf_life_days, off_barcode)
ingredient_aliases  (ingredient_id, alias)
package_sizes       (ingredient_id, amount, unit, label)
recipes             (id uuid PK, title, description, servings, prep_minutes, category,
                     diet_tags text[], instructions jsonb, image_url, source, created_by, is_public)
recipe_ingredients  (recipe_id, ingredient_id, amount_base, display_amount, display_unit, optional)
favorites           (user_id, recipe_id)
favorite_ingredients(user_id, ingredient_id)
meal_plans          (id uuid PK, household_id, week_start date)
meal_plan_entries   (id, meal_plan_id, date, slot, recipe_id, servings, is_leftover_of uuid NULL)
shopping_lists      (id, household_id, meal_plan_id, generated_at)
shopping_list_items (id, list_id, ingredient_id NULL, custom_name NULL, required_base,
                     packages, package_size_id, leftover_base, source, manual_override,
                     checked, checked_at)
pantry_items        (id, household_id, ingredient_id, amount_base, expires_at, added_from)  -- M2
```

**Grundsatz:** Intern alles in **Basiseinheiten** speichern. Die angezeigte Einheit („2 EL“, „1 Bund“) ist nur für die Darstellung da.

## 7. Logik der Einkaufsliste

```
für jeden Planeintrag:
    faktor = entry.servings / recipe.servings
    für jede Rezeptzutat: bedarf[ingredient] += amount_base * faktor
bedarf -= vorrat (M2)
für jede Zutat:
    packung = kleinste Kombination aus package_sizes ≥ bedarf
    rest    = packung - bedarf
    wenn rest > schwelle: rest_vorschlag = rezepte, die diese Zutat ≥ rest nutzen
manuelle Overrides der alten Liste übernehmen
```

### Sonderfälle
- „Eine Prise Salz“ / „nach Geschmack“ → Grundzutaten (Salz, Pfeffer, Öl) als „Vorrat vorausgesetzt“ markieren
- Zutaten ohne Umrechnungswert (1 Bund Petersilie) → als Stück behandeln, nicht in Gramm rechnen
- Verschiedene Formen derselben Zutat (Dosentomaten vs. frische Tomaten) → getrennte Zutaten
- Neuberechnung nach dem Abhaken → abgehakte Einträge bleiben erhalten
- Die KI erfindet eine Zutat → auf vorhandene Zutaten / Synonyme abbilden, sonst zur Prüfung markieren
- Allergien → nie allein der KI überlassen, immer zusätzlich hart gegen die Datenbank filtern

## 8. Screens (Wireframe-Struktur)

**Navigation:** Planen · Rezepte · Einkauf · Vorrat (M2) · Profil (Handy: Tabs unten · Web/Desktop: Sidebar links)

- **Planen:** Wochenleiste oben, Tageskarten mit 3 Slots, „+“ öffnet Rezeptauswahl (Bottom Sheet), Button „Woche automatisch füllen“
- **Rezepte:** Suche, Filter-Chips, Karten-Grid; Detail mit Portionen-Regler, Zutaten, Schritten, „Zum Plan hinzufügen“
- **Einkauf:** nach Abteilung gruppiert, Checkboxen, Hinweis-Banner zu Resten, manuelles Hinzufügen
- **Onboarding (4 Schritte):** Haushalt → Ernährung → Lieblingszutaten → erster Vorschlag für die Woche

## 9. Roadmap (Sprints à 2 Wochen)

| Sprint | Inhalt |
|---|---|
| 0 | Expo-Projekt, Supabase-Projekt, Auth-Entscheidung, CI, Grundschema + RLS |
| 1 | Zutatenmodell + Seed-Daten (~300 Zutaten mit Packungsgrößen), Zutatensuche |
| 2 | Rezepte: Datenmodell, ~100 kuratierte Rezepte, Liste + Detail, Portionen-Regler |
| 3 | Wochenplaner mit Zuweisen, Tauschen, Reste-Logik |
| 4 | Einkaufslisten-Funktion inkl. Packungen & Rest-Vorschlägen, mit Unit-Tests |
| 5 | KI-Rezeptgenerator (Edge Function, JSON-Schema, Validierung) + Onboarding |
| 6 | Offline-Cache, Feinschliff, Datenschutzerklärung, Closed Testing im Play Store + Web-Deploy |

Danach: 10–20 Testnutzer und messen, ob sie nach 4 Wochen noch planen. Davon hängt ab, ob Milestone 2 gebaut wird.

## 10. Kennzahlen
- **Aktivierung:** Plan → Einkaufsliste erzeugt
- **Retention nach 4 Wochen** (wichtigste Zahl)
- **Rest-Vorschläge angenommen in %** (beweist den USP)
- **Gerechnete Gramm / Euro weniger weggeworfen** pro Nutzer

Related: [M1-Spezifikation](../01-Planung/2026-11-21-M1-Spezifikation.md) · [M1-Implementierungsplan](../01-Planung/2026-11-21-M1-Implementierungsplan.md)
