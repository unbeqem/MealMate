---
title: ADR-003 Repository-Interface und Demo-Modus
date: 2026-11-21
tags: [adr, daten]
---

# ADR-003: Repository-Interface und Demo-Modus

**Status:** angenommen

**Kontext:** Die Supabase-Keys trägt der Nutzer selbst in `.env` ein. Entwicklung, Playwright-Tests und Demos sollen auch ohne Backend laufen.

**Entscheidung:** Alle Datenzugriffe laufen über ein `Repo`-Interface. `SupabaseRepo` wird verwendet, wenn `EXPO_PUBLIC_SUPABASE_URL` und `EXPO_PUBLIC_SUPABASE_ANON_KEY` gesetzt sind. Sonst greift `LocalRepo` (AsyncStorage, Seed aus `packages/core`). Die App zeigt dann einen Hinweis „Demo-Modus“.

**Folgen:** Der KI-Generator ist im Demo-Modus deaktiviert, weil der API-Key serverseitig liegt. Alle anderen Funktionen laufen vollständig.

Related: [Setup Supabase](../04-Technik/Setup-Supabase.md)
