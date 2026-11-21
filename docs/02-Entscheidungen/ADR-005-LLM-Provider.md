---
title: ADR-005 LLM hinter Provider-Interface (Claude zuerst)
date: 2026-11-21
tags: [adr, ki]
---

# ADR-005: LLM hinter Provider-Interface

**Status:** angenommen

**Kontext:** Zuerst Claude, später ein eigenes trainiertes Modell.

**Entscheidung:** Die Edge Function `generate-recipe` spricht nur mit `RecipeModel { generate(prompt, constraints): RawRecipe }`. Implementierungen: `ClaudeProvider` (Messages API, Tool-Use mit JSON-Schema, Modell per Secret `LLM_MODEL`, Default `claude-opus-5-5`, Structured Outputs (`output_config.format`) und serverseitiger Refusal-Fallback (`fallbacks: "default"`)). Gewählt wird über das Secret `LLM_PROVIDER`. Ein späteres eigenes Modell (z. B. OpenAI-kompatibler Endpoint) wird als weiterer Adapter ergänzt.

**Unabhängig vom Modell:** Die Antwort wird validiert, Zutaten werden über Aliase auf die Datenbank abgebildet, unbekannte Zutaten als `needs_review` markiert, und Allergene werden **nach** der Generierung hart gegen die Datenbank geprüft.

**Datensammlung fürs eigene Modell:** Jede Generierung (Prompt, Rohantwort, Mapping, ob gespeichert/geplant) landet in `ai_generations`. Das wird später zur Trainingsgrundlage.

Related: [M1-Spezifikation](../01-Planung/2026-11-21-M1-Spezifikation.md)
