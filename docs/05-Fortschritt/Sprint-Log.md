---
title: Sprint-Log
date: 2026-11-21
tags: [fortschritt, log]
---

# Sprint-Log

## 21.11.2026 – Milestone 1 gebaut

**Erledigt**
- Planung: [Spezifikation](../01-Planung/2026-11-21-M1-Spezifikation.md), [Implementierungsplan](../01-Planung/2026-11-21-M1-Implementierungsplan.md), ADR-001 bis 005.
- Design: Richtung per Impeccable-Würfel und Mockups gewählt, [Der Kassenbon](../03-Design/Design-Richtung-Kassenbon.md).
- `packages/core`: Einheiten, Packungswahl (DP), Einkaufsliste mit Resten, Vorschlägen und Merge, Filter (Diät/Allergene aus Zutaten), Auto-Fill mit Reste-Synergie, Suche. **27 Tests grün.**
- Seed: 107 Zutaten (Packungen, Abteilungen, Allergene, Haltbarkeit), 39 kuratierte Rezepte.
- Supabase: Schema + RLS + Seed **live im Projekt**; Edge Functions `generate-recipe` (Claude, harte Allergie-Prüfung) und `build-shopping-list` geschrieben.
- App (Expo SDK 58, Android + Web): Anmeldung (E-Mail-Code, Google, Gastmodus), Onboarding in 4 Schritten, Wochenplaner (Tabs/Sidebar, Auto-Fill, Reste für morgen Mittag, Tauschen, Portionen), Rezeptliste und -detail (Live-Portionen), KI-Erstellung, Einkauf als Bon (Abteilungen, abhaken, Rest-Zeilen mit „Einplanen“, Mengenkorrektur, eigene Einträge, offline per Query-Persistenz), Profil.
- Landingpage mit funktionierender Warteliste (Supabase `waitlist`), interaktiver Spinat-Demo, FAQ, Entwürfen für Datenschutz und Impressum.
- Browser-Prüfung mit Playwright (mobil + Desktop), Impeccable-Detector, unabhängiges Finish-Review: zwei Fix-Runden, Verdikt **ship**. DESIGN.md geschrieben.

**Offen (braucht dich)**
- Supabase-Dashboard: E-Mail-Template mit `{{ .Token }}`, Redirect-URLs, Google-Provider ([Setup](../04-Technik/Setup-Supabase.md)).
- `supabase login`, Edge Functions deployen, `ANTHROPIC_API_KEY` als Secret setzen.
- Impressum und Datenschutz mit echten Angaben füllen und prüfen lassen.
- Android-Build auf Gerät/Emulator testen (`npx expo run:android` oder EAS).
- Mehr Rezepte: Ziel aus dem Konzept 100+ (jetzt 39).
- Node wurde per nvm auf 22.23.5 umgestellt (Expo 58 braucht ≥ 20.19.4).

Related: [Implementierungsplan](../01-Planung/2026-11-21-M1-Implementierungsplan.md)
