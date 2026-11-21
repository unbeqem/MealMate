---
title: Milestone 1 – Implementierungsplan
date: 2026-11-21
tags: [planung, plan, m1]
aliases: [M1-Plan]
---

# Milestone 1 – Implementierungsplan

Abarbeitung von oben nach unten. Jede Aufgabe endet mit einem Check (Test, Build oder Screenshot). Der Status wird im [Sprint-Log](../05-Fortschritt/Sprint-Log.md) festgehalten.

## Sprint 0 – Fundament
- [x] Monorepo (npm workspaces): `apps/mobile`, `apps/landing`, `packages/core`, `supabase/`
- [x] Expo-App mit Expo Router, TypeScript strict, Web + Android
- [x] `packages/core` mit Vitest
- [x] Supabase-Migrationen: Schema, RLS, Trigger (Profil + Haushalt beim Signup), Warteliste
- [x] `.env.example`, Setup-Anleitung, CI (GitHub Actions: Typecheck + Tests)

## Sprint 1 – Zutatenmodell
- [x] Typen `Ingredient`, `PackageSize`, `Unit`, Einheiten-Umrechnung (g/ml/Stk, EL/TL/Prise/Bund → Basis)
- [x] Seed: 107 Zutaten mit Aliasen, Packungsgrößen, Abteilung, Allergenen, Diät-Klasse
- [x] Generator `seed.sql` aus den TS-Seeds
- [x] Zutatensuche (Name + Aliase, umlauttolerant)

## Sprint 2 – Rezepte
- [~] Kuratierte Rezepte (deutsch, 39 von ~100), Validierung gegen die Zutatentabelle (Test)
- [x] Rezeptliste mit Suche und Filter-Chips (Kategorie, Zeit, Ernährung)
- [x] Detail mit Portionen-Regler (live), „Zum Plan hinzufügen“

## Sprint 3 – Wochenplaner
- [x] Woche (Mo–So) × Frühstück/Mittag/Abend, Rezept zuweisen/tauschen/entfernen, Portionen
- [x] Reste: „Rest morgen Mittag“ erzeugt `is_leftover_of`-Eintrag
- [x] „Woche automatisch füllen“ (Filter + Packungs-Synergie)

## Sprint 4 – Einkaufsliste
- [x] `buildShoppingList` (Bedarf → Packungen → Reste → Vorschläge → Merge) mit Unit-Tests
- [x] Edge Function `build-shopping-list` nutzt dieselbe Logik
- [x] Screen „Der Bon“: Abteilungen, abhaken, manuelle Einträge, Rest-Banner „Einplanen“

## Sprint 5 – KI & Onboarding
- [x] Edge Function `generate-recipe`: Provider-Interface, Claude-Adapter, JSON-Schema, Zutaten-Mapping, Allergie-Prüfung, Speichern
- [x] Client: „Mit KI erstellen“ (Prompt + Ergebnis + Speichern); im Demo-Modus deaktiviert mit Erklärung
- [x] Onboarding in 4 Schritten, danach erste Woche automatisch gefüllt

## Sprint 6 – Offline, Feinschliff, Launch-Vorbereitung
- [x] TanStack-Query-Persistenz (AsyncStorage), optimistische Häkchen
- [x] Landingpage mit Warteliste (Supabase-Insert), Datenschutz-Platzhalter
- [x] Barrierefreiheit, reduzierte Bewegung, Fokus-Ringe, Dark Mode (Android-Gerätetest offen)
- [x] Playwright-Prüfung von Web-App und Landing, Impeccable-Finish-Review
- [x] DESIGN.md, Doku aktualisieren, Commit und Push

Related: [M1-Spezifikation](2026-11-21-M1-Spezifikation.md) · [Sprint-Log](../05-Fortschritt/Sprint-Log.md)
