---
title: ADR-001 Monorepo mit npm workspaces
date: 2026-11-21
tags: [adr, architektur]
---

# ADR-001: Monorepo mit npm workspaces

**Status:** angenommen

**Kontext:** App, Landingpage, Server-Logik und Doku sollen in ein Repo (`unbeqem/MealMate`). Die Einkaufslisten-Logik muss im Client (offline) und auf dem Server identisch laufen.

**Entscheidung:** npm workspaces mit `apps/mobile`, `apps/landing`, `packages/core`, dazu `supabase/` und `docs/`. Kein Turborepo/Nx im MVP, weil der Mehrwert bei vier Paketen gering ist.

**Folgen:** Expo erkennt Monorepos automatisch (Metro `watchFolders`). `packages/core` hat keine Abhängigkeiten, deshalb kann die Edge Function (Deno) die Dateien direkt importieren.

Related: [ADR-002](ADR-002-Geteilte-Logik.md)
