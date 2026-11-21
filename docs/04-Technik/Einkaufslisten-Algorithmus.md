---
title: Einkaufslisten-Algorithmus
date: 2026-11-21
tags: [technik, logik, einkaufsliste]
---

# Einkaufslisten-Algorithmus

Code: [`packages/core/src/shopping.ts`](../../packages/core/src/shopping.ts), [`packages.ts`](../../packages/core/src/packages.ts), Tests: [`core.test.ts`](../../packages/core/src/core.test.ts) (27 Tests).

## Ablauf `buildShoppingList`

1. **Bedarf** (`computeDemand`): pro Eintrag `faktor = servings / recipe.servings`, Basiseinheiten summieren. Einträge mit `leftoverOf` und optionale Zutaten erzeugen keinen Bedarf.
2. **Packungen** (`choosePackages`): dynamische Programmierung über alle Kombinationen der Packungsgrößen, also kleinste Gesamtmenge ≥ Bedarf, bei Gleichstand die wenigsten Packungen. Beispiel Eier: 11 → 2 × 6 (12), nicht 10 + 6.
3. **Grundzutaten** (`is_staple`: Salz, Öl, Gewürze, Brühe …) → „Vorrat vorausgesetzt“, nichts zu kaufen.
4. **Rest** = Kauf − Bedarf. **Relevant** (Vorschläge) nur, wenn:
   - Haltbarkeit < 21 Tage (Knoblauch, Reis, Zwiebeln halten, also keine Verschwendung),
   - Rest ≥ 15 % der Kaufmenge **und** ≥ 30 g/ml bzw. ≥ 1 Stück.
5. **Vorschläge** (`suggestForLeftover`): erlaubte Rezepte (harte Filter), noch nicht im Plan, deren Bedarf dem Rest am nächsten kommt (höchstens 25 % darüber). Top 3.
6. **Merge** mit der vorigen Liste: Häkchen und `manualOverride` bleiben, manuelle Einträge bleiben, abgehakte und nicht mehr benötigte Einträge bleiben als `orphaned`.

## Auto-Fill `autofillWeek`

Greedy pro Tag: harte Filter, dann Score = Reste-Synergie (verbraucht offene Reste der bisherigen Woche) + Lieblingszutaten − Wiederholung + kleiner Zufall. Abendessen mit `cookForLeftovers` → Folgetag Mittag als Rest-Eintrag. Bestehende Einträge werden nie überschrieben.

## Ergebnis im Test

Spinat-Feta-Pasta (200 g) + Gnocchi mit Rahmspinat (250 g) → 1 Beutel 450 g, Rest 0. Nur die Pasta → Rest 250 g, Top-Vorschlag „Gnocchi mit Rahmspinat“.

Related: [ADR-002](../02-Entscheidungen/ADR-002-Geteilte-Logik.md) · [Datenbankschema](Datenbankschema.md)
