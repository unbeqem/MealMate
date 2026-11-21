---
title: Design-Richtung „Der Kassenbon“
date: 2026-11-21
tags: [design, impeccable, richtung]
aliases: [Kassenbon, Designrichtung]
---

# Design-Richtung „Der Kassenbon“

**These:** MealMate druckt dir den Bon, bevor du einkaufst. Jede Zeile ist eine echte Packung, jeder Rest eine markierte Zeile, die schon einem späteren Rezept gehört. Bewusst **nicht** der Kategorie-Standard aus Food-Fotos, Handy-Mockup und grünem Button.

## Wie die Wahl zustande kam

1. Impeccable-Würfel (`concept-seed`, seed:8118e4a55f00c617): Runde 1 „Die Dosenwand“, neu gewürfelt; Runde 2 „Der Marktstand“.
2. Auf Wunsch kamen echte Visuals dazu: drei HTML-Mockups (Marktstand, Kassenbon, Dosenwand), siehe [mockups](mockups/).
3. **Gewählt: Der Kassenbon** (Karte „Impeccable’s Pick“).

| Mockup | Datei |
|---|---|
| Der Kassenbon (gewählt) | [shot-kassenbon.png](mockups/shot-kassenbon.png) · [HTML](mockups/sketch-kassenbon.html) |
| Der Marktstand | [shot-marktstand.png](mockups/shot-marktstand.png) · [HTML](mockups/sketch-marktstand.html) |
| Die Dosenwand | [shot-dosenwand.png](mockups/shot-dosenwand.png) · [HTML](mockups/sketch-dosenwand.html) |

## Welt

| Rolle | Wert | Einsatz |
|---|---|---|
| Rahmen-Violett | `#6B4CF0` | Header-Bänder, Landing-Grund (weiße Schrift 5,4 : 1) |
| Indigo | `#2B1A78` | Hauptaktionen |
| Thermopapier | `#FBFBF8` | Inhalte als Bon mit Abrisskante |
| Textmarker | `#FFE45C` | **nur** Rest-Zeilen |
| Grün | `#1F9E73` | erledigt / verplant |
| Schrift | Archivo Narrow / Archivo (wdth 66–72) | Headlines |
| | Archivo | Fließtext, Labels |
| | Martian Mono | Bon-Zeilen, Mengen, Zahlen |

Dunkelmodus: eigene Rollen (Nachtviolett `#120E24`, Papier `#1E1A33`), kein Invertieren.

## Bewegung (ux-motion)

- **Signatur:** Der Bon druckt Zeile für Zeile (Stagger 40 ms, höchstens 8 Zeilen, Ease-out-Expo), danach wischt der Textmarker von links nach rechts (220 ms).
- Sheets öffnen in 260 ms (Ease-out) und schließen in 140 ms (Ease-in), schnelles Schließen.
- Häkchen und Planänderungen sind optimistisch, Rückmeldung unter 100 ms, Snackbar mit „Rückgängig“.
- `prefers-reduced-motion`: statischer Bon, keine Wege, nur Einblendungen.

## Plattform

Handy: Tabs unten (Planen · Rezepte · Einkauf · Profil), Touch-Ziele ≥ 48 dp, System-Zurück funktioniert (Predictive Back an). Ab 900 px: Sidebar links, Wochenansicht als Raster aller Tage.

Related: [M1-Spezifikation](../01-Planung/2026-11-21-M1-Spezifikation.md) · [ADR-004 Styling](../02-Entscheidungen/ADR-004-Styling.md)
