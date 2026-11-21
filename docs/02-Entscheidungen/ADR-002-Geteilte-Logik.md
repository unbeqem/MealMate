---
title: ADR-002 Einkaufslogik als geteiltes TS-Paket statt PL/pgSQL
date: 2026-11-21
tags: [adr, logik]
---

# ADR-002: Einkaufslogik als geteiltes TS-Paket

**Status:** angenommen

**Kontext:** Das Konzept nennt „Postgres-Funktion oder Edge Function“. Die Liste muss offline im Supermarkt neu berechenbar sein, und die Logik soll testbar sein.

**Entscheidung:** Die Logik liegt in `packages/core` (reines TypeScript, keine Abhängigkeiten, mit Vitest getestet). Der Client rechnet damit offline. Die Edge Function `build-shopping-list` importiert dieselben Dateien und speichert das Ergebnis.

**Alternativen:** PL/pgSQL (zweite Implementierung für offline nötig, schwer testbar) – verworfen.

**Folgen:** Eine Quelle der Wahrheit. Server und Client können nicht auseinanderlaufen.

Related: [ADR-001](ADR-001-Monorepo.md) · [Einkaufslisten-Algorithmus](../04-Technik/Einkaufslisten-Algorithmus.md)
