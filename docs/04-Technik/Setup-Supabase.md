---
title: Setup Supabase – Schritt für Schritt
date: 2026-11-21
tags: [technik, supabase, setup, anleitung]
aliases: [Supabase einrichten]
---

# Setup Supabase – Schritt für Schritt

Projekt-Ref: `ethuwpvfwmephvbuyjli` · Dashboard: <https://supabase.com/dashboard/project/ethuwpvfwmephvbuyjli>
Zugangsdaten stehen in deiner privaten Notiz `supabase` im Vault-Root (nicht im Repo).

> [!NOTE]
> **Schon erledigt, nichts zu tun:** Datenbank-Tabellen, Sicherheitsregeln (RLS), 107 Zutaten und 39 Rezepte sind eingespielt. Die App kennt URL und Publishable Key über `apps/mobile/.env`.

Reihenfolge: **Teil A** (Login per Mail-Code, ca. 5 Min) → **Teil B** (Google-Login, ca. 15 Min, optional) → **Teil C** (KI-Rezepte, ca. 10 Min). Jeder Teil endet mit einem Test.

Die Menüpunkte im Supabase-Dashboard heißen auf Englisch. Falls ein Name leicht anders lautet, nimm die Suche oben im Dashboard (`Ctrl + K`) und tipp den fettgedruckten Begriff ein.

---

## Teil A – Login per E-Mail-Code

Die App schickt beim Anmelden eine Mail und fragt dann nach einem **Code**. Standardmäßig verschickt Supabase aber nur einen Link. Deshalb muss der Code in die Mail-Vorlagen.

### A1. E-Mail-Login prüfen
1. Dashboard öffnen → links **Authentication** (Personen-Symbol).
2. Im Authentication-Menü **Sign In / Providers** (ältere Oberfläche: **Providers**) anklicken.
3. **Email** muss aktiv sein (Schalter grün). Darin:
   - **Confirm email**: an lassen.
   - **Email OTP Length**: `6` (die App erwartet 6 bis 8 Ziffern).
4. Unten **Save**.

### A2. Code in die Mail-Vorlagen einfügen
1. Im Authentication-Menü **Emails** → Reiter **Templates** (ältere Oberfläche: **Email Templates**).
2. Vorlage **Confirm signup** öffnen (diese Mail bekommen **neue** Nutzer).
   - **Subject heading** ersetzen durch: `Dein MealMate-Code`
   - Im Feld **Message body** den ganzen Inhalt ersetzen durch:
     ```html
     <h2>Dein Code für MealMate</h2>
     <p style="font-size:28px;font-weight:bold;letter-spacing:4px">{{ .Token }}</p>
     <p>Gib den Code in der App ein. Oder tipp auf diesen Link:</p>
     <p><a href="{{ .ConfirmationURL }}">Anmelden</a></p>
     ```
   - **Save changes**.
3. Vorlage **Magic Link** öffnen (diese Mail bekommen **bestehende** Nutzer) und genau dasselbe eintragen. **Save changes**.

### A3. Erlaubte Rücksprung-Adressen
1. Im Authentication-Menü **URL Configuration**.
2. **Site URL**: vorerst `http://localhost:8081` → **Save**. (Später ersetzt du das durch die echte Web-Adresse der App.)
3. Unter **Redirect URLs** auf **Add URL** und diese drei einzeln hinzufügen:
   - `http://localhost:8081/auth-callback`
   - `mealmate://auth-callback`
   - `exp://**` (für Tests mit Expo Go auf dem Handy)
4. **Save URLs**.

### A4. Test
1. In PowerShell:
   ```powershell
   cd C:\Obsidian\mealmate\app
   npm run dev
   ```
2. Browser: <http://localhost:8081> → deine E-Mail eingeben → **Code per Mail senden**.
3. Mail öffnen → Code in der App eingeben → **Anmelden**. Du landest im Onboarding.
4. Kontrolle im Dashboard: **Authentication → Users** zeigt deine Adresse. **Table Editor → profiles** hat eine neue Zeile.

> [!WARNING]
> Supabase verschickt ohne eigenen Mailserver nur **wenige Mails pro Stunde** (für Tests reicht das). Vor dem Teststart mit echten Nutzern unter **Authentication → Emails → SMTP Settings** einen eigenen Anbieter eintragen (z. B. Resend, Brevo, Postmark).

---

## Teil B – Login mit Google (optional)

Du brauchst ein Google-Konto. Die Google Cloud Console nennt Menüs manchmal leicht anders; die Suche oben hilft auch dort.

### B1. Projekt bei Google anlegen
1. <https://console.cloud.google.com> öffnen und anmelden.
2. Oben links neben dem Google-Cloud-Logo auf die **Projektauswahl** → **Neues Projekt** → Name `MealMate` → **Erstellen**. Danach sicherstellen, dass oben `MealMate` ausgewählt ist.

### B2. Zustimmungsbildschirm (was Nutzer beim Login sehen)
1. Suche oben: **Google Auth Platform** öffnen (ältere Oberfläche: **APIs & Dienste → OAuth-Zustimmungsbildschirm**).
2. **Jetzt starten** / **Get started**:
   - App-Name: `MealMate`
   - Nutzer-Support-E-Mail: deine Adresse
   - Zielgruppe: **Extern**
   - Kontaktdaten: deine Adresse
   - Bedingungen akzeptieren → **Erstellen**.
3. Links **Zielgruppe / Audience** → unter **Testnutzer** deine eigene Google-Adresse hinzufügen (solange die App im Testmodus ist, dürfen sich nur Testnutzer anmelden).

### B3. Zugangsdaten (Client-ID) erstellen
1. Links **Clients** (ältere Oberfläche: **APIs & Dienste → Anmeldedaten → Anmeldedaten erstellen → OAuth-Client-ID**) → **Client erstellen**.
2. Anwendungstyp: **Webanwendung**. Name: `MealMate Supabase`.
3. **Autorisierte JavaScript-Quellen** → **URI hinzufügen**: `http://localhost:8081`
4. **Autorisierte Weiterleitungs-URIs** → **URI hinzufügen**, exakt:
   ```
   https://ethuwpvfwmephvbuyjli.supabase.co/auth/v1/callback
   ```
5. **Erstellen**. Es erscheint ein Fenster mit **Client-ID** und **Clientschlüssel**. Beide kopieren (das Fenster lässt sich später unter **Clients** wieder öffnen).

### B4. In Supabase eintragen
1. Supabase-Dashboard → **Authentication → Sign In / Providers** → **Google** aufklappen.
2. **Enable Sign in with Google** einschalten.
3. **Client IDs**: die Client-ID einfügen. **Client Secret (for OAuth)**: den Clientschlüssel einfügen.
4. **Save**.

### B5. Test
<http://localhost:8081> → **Mit Google anmelden** → Google-Konto wählen (muss als Testnutzer eingetragen sein) → zurück in der App im Onboarding.

---

## Teil C – KI-Rezepte (Edge Functions)

Die KI läuft auf dem Server, damit dein API-Key nie in der App steckt. Dafür lädst du zwei Funktionen hoch und hinterlegst den Claude-Key.

### C1. Claude-API-Key besorgen
1. <https://console.anthropic.com> öffnen und anmelden (oder Konto erstellen).
2. **Settings → Billing**: Zahlungsmittel hinterlegen bzw. Guthaben aufladen (ohne Guthaben antwortet die API nicht).
3. **Settings → API Keys** → **Create Key** → Name `MealMate` → **Create**.
4. Den Key (beginnt mit `sk-ant-`) **sofort kopieren**, er wird nur einmal angezeigt. Nicht in Obsidian-Notizen speichern, die synchronisiert werden.

### C2. Supabase-CLI anmelden
In PowerShell:
```powershell
cd C:\Obsidian\mealmate\app
npx supabase login
```
Es öffnet sich der Browser → **Authorize**. Im Terminal erscheint `You are now logged in`. (Falls kein Browser aufgeht: den angezeigten Link öffnen und den Code im Terminal eingeben.)

### C3. Projekt verknüpfen
```powershell
npx supabase link --project-ref ethuwpvfwmephvbuyjli
```
Fragt es nach dem **Database password**: das Passwort aus deiner Notiz `supabase` eingeben (beim Tippen ist nichts zu sehen, das ist normal) → Enter.

### C4. API-Key als Secret hinterlegen
```powershell
npx supabase secrets set ANTHROPIC_API_KEY=sk-ant-DEIN-KEY
```
Kontrolle: `npx supabase secrets list` zeigt `ANTHROPIC_API_KEY` (nur als Prüfsumme, nicht im Klartext).

Optional: anderes Modell wählen, z. B. günstiger: `npx supabase secrets set LLM_MODEL=claude-sonnet-5-5` (Standard ist `claude-opus-5-5`).

### C5. Funktionen hochladen
```powershell
npm run functions:deploy
```
Das kopiert zuerst die gemeinsame Logik in `supabase/functions/_shared/core` und lädt dann `generate-recipe` und `build-shopping-list` hoch. Am Ende steht je Funktion `Deployed Function ...`.

Kontrolle im Dashboard: links **Edge Functions** → beide Funktionen sind aufgelistet.

### C6. Test
1. In der App angemeldet (nicht Gastmodus) → **Rezepte** → **Rezept mit KI erstellen**.
2. z. B. „Schnelles Abendessen mit Brokkoli und Feta“ → **Rezept erstellen**. Nach 10–30 Sekunden öffnet sich das neue Rezept.
3. Kontrolle: **Table Editor → ai_generations** hat eine Zeile mit `status = saved`.

### Wenn etwas nicht klappt
- Dashboard → **Edge Functions → generate-recipe → Logs** zeigt die Fehlermeldung.
- `Kein Publishable Key` oder `Kein Secret Key` in den Logs: Dein Projekt nutzt nur die neuen API-Keys. Dann zusätzlich setzen (Werte unter **Project Settings → API Keys**):
  ```powershell
  npx supabase secrets set MM_PUBLISHABLE_KEY=sb_publishable_... MM_SECRET_KEY=sb_secret_...
  ```
  und `npm run functions:deploy` erneut ausführen.
- `401 invalid x-api-key` oder `credit balance`: Key falsch kopiert oder kein Guthaben (C1).
- „Die KI ist gerade nicht erreichbar“ in der App: Logs ansehen, meist Key oder Guthaben.

---

## Später: Schema oder Seed ändern

| Was | Befehl (im Ordner `C:\Obsidian\mealmate\app`) |
|---|---|
| Zutaten/Rezepte ändern | Datei in `packages/core/src/seed/` bearbeiten → `npm run seed:sql` → `npx supabase db push --include-seed` |
| Tabelle ändern | neue Datei in `supabase/migrations/` → `npx supabase db push` |
| Logik in `packages/core` geändert | `npm run functions:deploy` (sonst rechnet der Server mit der alten Logik) |

## Checkliste

- [ ] A1 E-Mail-Provider geprüft
- [ ] A2 Vorlagen „Confirm signup“ und „Magic Link“ mit `{{ .Token }}`
- [ ] A3 Site URL + 3 Redirect URLs
- [ ] A4 Test Login per Code
- [ ] B1–B4 Google eingerichtet (optional)
- [ ] B5 Test Google-Login
- [ ] C1 Claude-Key erstellt, Guthaben vorhanden
- [ ] C2–C5 CLI-Login, Link, Secret, Deploy
- [ ] C6 Test KI-Rezept
- [ ] Vor echten Nutzern: eigener SMTP-Anbieter (Warnung in A4)

Related: [Datenbankschema](Datenbankschema.md) · [ADR-003 Demo-Modus](../02-Entscheidungen/ADR-003-Demo-Modus.md) · [ADR-005 LLM-Provider](../02-Entscheidungen/ADR-005-LLM-Provider.md)
