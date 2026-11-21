# MealMate

Der Wochenplaner, der in **Packungsgrößen und Resten** denkt: MealMate rundet die Einkaufsliste auf echte Packungen auf und plant, was übrig bleibt, gleich in eine weitere Mahlzeit der Woche ein.

| Paket | Inhalt |
|---|---|
| [apps/mobile](apps/mobile) | Expo-App (Android + Web), Expo Router, TanStack Query, Zustand |
| [apps/landing](apps/landing) | Statische Landingpage mit Warteliste |
| [packages/core](packages/core) | Reine TS-Logik: Einheiten, Packungen, Einkaufsliste, Reste, Auto-Fill, Filter, Seed-Daten |
| [supabase](supabase) | Migrationen (Schema + RLS), `seed.sql`, Edge Functions |
| [docs](docs/INDEX.md) | Konzept, Planung, Entscheidungen, Design, Technik (Obsidian-Vault „MealMate“) |

## Schnellstart

Voraussetzung: Node ≥ 20.19.4 (empfohlen 22).

```bash
npm install
cp apps/mobile/.env.example apps/mobile/.env   # Supabase-URL + Publishable Key eintragen
npm test                                        # Core-Logik (Vitest)
npm run dev                                     # App im Browser (http://localhost:8081)
npm run dev -w landing                          # Landingpage (http://localhost:4173)
```

Ohne `.env` startet die App im Gastmodus (Daten nur auf dem Gerät).

Android: `cd apps/mobile && npx expo run:android` (Dev-Build) oder `npx eas-cli@latest build -p android`.

## Backend

Einrichtung, Auth-Einstellungen, Edge Functions und Secrets: [docs/04-Technik/Setup-Supabase.md](docs/04-Technik/Setup-Supabase.md).

```bash
npm run seed:sql                      # seed.sql aus packages/core neu erzeugen
npx supabase db push --include-seed   # Schema + Seed einspielen
npx supabase functions deploy generate-recipe build-shopping-list
```
