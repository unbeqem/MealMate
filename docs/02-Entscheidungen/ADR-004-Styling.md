---
title: ADR-004 Styling mit Design-Tokens statt NativeWind/Tamagui
date: 2026-11-21
tags: [adr, design]
---

# ADR-004: Styling mit typisierten Design-Tokens

**Status:** angenommen

**Kontext:** Im Konzept steht „NativeWind oder Tamagui“. Die gewählte Welt („Der Kassenbon“) braucht wenige, sehr präzise Bausteine (Bon-Zeile, Abrisskante, Markierung) und Hell/Dunkel-Rollen.

**Entscheidung:** Eigene Tokens (`theme/tokens.ts`: Farbrollen hell/dunkel, Typo-Rollen, Abstände, Radien) und `StyleSheet`. Keine zusätzliche Styling-Engine.

**Begründung:** Keine Build-Konfiguration (Babel/Tailwind/Compiler) und keine Risiken bei Versions-Upgrades. Typsicher, und die Tokens lassen sich 1:1 in `DESIGN.md` dokumentieren.

**Revisit:** wenn das Team wächst oder viele generische Screens dazukommen, NativeWind nachrüsten.

Related: [Design-Richtung](../03-Design/Design-Richtung-Kassenbon.md)
