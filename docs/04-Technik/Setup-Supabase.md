---
title: Setup Supabase
date: 2026-11-21
tags: [technik, supabase, setup]
---

# Setup Supabase

Projekt: `ethuwpvfwmephvbuyjli` (Zugangsdaten stehen in der privaten Notiz `supabase` im Vault-Root, **nicht** im Repo).

## Status (21.11.2026)

| Schritt | Status |
|---|---|
| Migrationen `init` + `rls` eingespielt | ✅ erledigt (`supabase db push --include-seed`) |
| Seed: 107 Zutaten, 39 Rezepte | ✅ erledigt, per REST geprüft |
| `apps/mobile/.env` mit URL + Publishable Key | ✅ lokal angelegt (gitignored) |
| Auth: E-Mail-Code aktivieren | ⏳ Dashboard (siehe unten) |
| Auth: Google-Provider | ⏳ Dashboard + Google Cloud Console |
| Edge Functions deployen | ⏳ braucht `supabase login` (Access Token) |
| Secret `ANTHROPIC_API_KEY` | ⏳ `supabase secrets set` |

## Auth im Dashboard

1. **Authentication → Providers → Email**: aktiviert lassen, „Confirm email“ an.
2. **Authentication → Email Templates → Magic Link**: den Code einfügen, damit die App ihn abfragen kann, z. B. `Dein Code: {{ .Token }}` (der Link `{{ .ConfirmationURL }}` darf bleiben).
3. **Authentication → URL Configuration**: Site URL = Web-Adresse der App; Redirect URLs: `http://localhost:8081/auth-callback`, `mealmate://auth-callback`, die spätere Produktions-URL `/auth-callback`.
4. **Google**: In der Google Cloud Console einen OAuth-Client (Web) anlegen, Redirect-URI `https://ethuwpvfwmephvbuyjli.supabase.co/auth/v1/callback`; Client-ID und Secret unter **Providers → Google** eintragen.

## Edge Functions

```bash
npx supabase login
npx supabase link --project-ref ethuwpvfwmephvbuyjli
npx supabase secrets set ANTHROPIC_API_KEY=sk-ant-...      # optional: LLM_MODEL, LLM_PROVIDER
npx supabase functions deploy generate-recipe build-shopping-list
```

- `generate-recipe`: KI-Rezept (Claude, [ADR-005](../02-Entscheidungen/ADR-005-LLM-Provider.md)), Mapping auf Zutaten, harte Allergie-Prüfung, Speichern, Protokoll in `ai_generations`.
- `build-shopping-list`: serverseitige Einkaufsliste mit derselben Logik wie die App ([ADR-002](../02-Entscheidungen/ADR-002-Geteilte-Logik.md)).
- Beide importieren `packages/core` relativ. Wenn der Bundler das beim Deploy ablehnt, `packages/core/src` nach `supabase/functions/_shared/core` kopieren und die Importe anpassen.

## Schema ändern

Neue Datei in `supabase/migrations/`, dann `npx supabase db push`. Seed-Daten nur in `packages/core/src/seed/*` ändern, danach `npm run seed:sql` (die CI prüft, dass `seed.sql` aktuell ist).

Related: [Datenbankschema](Datenbankschema.md) · [ADR-003 Demo-Modus](../02-Entscheidungen/ADR-003-Demo-Modus.md)
