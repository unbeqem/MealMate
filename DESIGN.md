---
name: MealMate
description: Der Wochenplaner, der in Packungen denkt – the week printed as a receipt, every leftover already assigned.
colors:
  frame-violet: "#6B4CF0"
  frame-ink: "#FFFFFF"
  frame-ink-muted: "#EFEAFF"
  action-indigo: "#2B1A78"
  on-action: "#FFFFFF"
  accent-violet: "#6A48F5"
  accent-soft: "#E7E1FF"
  highlighter: "#FFE45C"
  on-highlighter: "#2A2400"
  done-green: "#1F9E73"
  done-soft: "#D5F6EA"
  danger: "#B42332"
  danger-soft: "#FBE3E5"
  ground: "#EEEBFA"
  paper: "#FBFBF8"
  paper-sunk: "#F1F0EA"
  ink: "#1A1A1A"
  ink-muted: "#5B5A55"
  rule: "#D6D4CB"
  dark-ground: "#120E24"
  dark-frame: "#2A1F63"
  dark-paper: "#1E1A33"
  dark-ink: "#F3F1FF"
  dark-action: "#A895FF"
  dark-done: "#5CE1B0"
typography:
  hero:
    fontFamily: "Archivo (wdth 68), system-ui, sans-serif"
    fontSize: "clamp(3.4rem, 8.4vw, 6rem)"
    fontWeight: 900
    lineHeight: 0.88
    letterSpacing: "-0.015em"
  display:
    fontFamily: "Archivo Narrow, Archivo (wdth 75), sans-serif"
    fontSize: "40px"
    fontWeight: 700
    lineHeight: "42px"
    letterSpacing: "-0.6px"
  headline:
    fontFamily: "Archivo Narrow, Archivo (wdth 75), sans-serif"
    fontSize: "28px"
    fontWeight: 700
    lineHeight: "32px"
    letterSpacing: "-0.3px"
  title:
    fontFamily: "Archivo, sans-serif"
    fontSize: "18px"
    fontWeight: 700
    lineHeight: "24px"
  body:
    fontFamily: "Archivo, sans-serif"
    fontSize: "16px"
    fontWeight: 400
    lineHeight: "23px"
  body-strong:
    fontFamily: "Archivo, sans-serif"
    fontSize: "16px"
    fontWeight: 700
    lineHeight: "23px"
  label:
    fontFamily: "Archivo, sans-serif"
    fontSize: "14px"
    fontWeight: 500
    lineHeight: "19px"
  small:
    fontFamily: "Archivo, sans-serif"
    fontSize: "13px"
    fontWeight: 400
    lineHeight: "18px"
  mono:
    fontFamily: "Martian Mono, ui-monospace, monospace"
    fontSize: "13px"
    fontWeight: 400
    lineHeight: "19px"
  mono-strong:
    fontFamily: "Martian Mono, ui-monospace, monospace"
    fontSize: "14px"
    fontWeight: 600
    lineHeight: "20px"
rounded:
  hairline: "3px"
  sm: "6px"
  md: "10px"
  lg: "16px"
  pill: "999px"
spacing:
  xxs: "2px"
  xs: "4px"
  sm: "8px"
  md: "12px"
  lg: "16px"
  xl: "24px"
  xxl: "32px"
  xxxl: "48px"
components:
  button-primary:
    backgroundColor: "{colors.action-indigo}"
    textColor: "{colors.on-action}"
    typography: "{typography.body-strong}"
    rounded: "{rounded.md}"
    padding: "0 24px"
    height: "48px"
  button-primary-hover:
    backgroundColor: "{colors.accent-violet}"
    textColor: "{colors.on-action}"
  button-secondary:
    backgroundColor: "transparent"
    textColor: "{colors.ink}"
    typography: "{typography.body-strong}"
    rounded: "{rounded.md}"
    padding: "0 24px"
    height: "48px"
  button-secondary-hover:
    backgroundColor: "{colors.paper-sunk}"
  button-ghost:
    backgroundColor: "transparent"
    textColor: "{colors.accent-violet}"
    typography: "{typography.body-strong}"
    rounded: "{rounded.md}"
    padding: "0 24px"
    height: "48px"
  button-ghost-hover:
    backgroundColor: "{colors.accent-soft}"
  button-on-frame:
    backgroundColor: "{colors.frame-ink}"
    textColor: "{colors.frame-violet}"
    typography: "{typography.body-strong}"
    rounded: "{rounded.md}"
    padding: "0 24px"
    height: "48px"
  button-compact:
    padding: "0 16px"
    height: "40px"
  icon-button:
    backgroundColor: "transparent"
    textColor: "{colors.ink}"
    rounded: "{rounded.pill}"
    size: "48px"
  chip:
    backgroundColor: "transparent"
    textColor: "{colors.ink}"
    typography: "{typography.label}"
    rounded: "{rounded.pill}"
    padding: "0 12px"
    height: "40px"
  chip-selected:
    backgroundColor: "{colors.accent-soft}"
    textColor: "{colors.accent-violet}"
  field:
    backgroundColor: "{colors.paper}"
    textColor: "{colors.ink}"
    typography: "{typography.body}"
    rounded: "{rounded.md}"
    padding: "0 16px"
    height: "52px"
  frame-header:
    backgroundColor: "{colors.frame-violet}"
    textColor: "{colors.frame-ink}"
    padding: "8px 16px 24px"
  receipt-paper:
    backgroundColor: "{colors.paper}"
    textColor: "{colors.ink}"
    rounded: "{rounded.sm}"
    padding: "16px"
  rest-line:
    backgroundColor: "{colors.highlighter}"
    textColor: "{colors.on-highlighter}"
    typography: "{typography.mono-strong}"
    rounded: "{rounded.hairline}"
    padding: "4px 8px"
  sheet:
    backgroundColor: "{colors.paper}"
    textColor: "{colors.ink}"
    rounded: "{rounded.lg}"
    width: "560px"
  tab-bar:
    backgroundColor: "{colors.paper}"
    textColor: "{colors.ink-muted}"
    typography: "{typography.label}"
    height: "56px"
  tab-bar-active:
    backgroundColor: "{colors.accent-soft}"
    textColor: "{colors.accent-violet}"
    rounded: "{rounded.pill}"
---

# Design System: MealMate

## Overview

**Creative North Star: "Der Kassenbon"**

MealMate prints the week before you shop. A saturated violet frame owns the top of every screen (and whole sections of the landing page), and the content arrives on thermal-paper slips: off-white paper with zig-zag tear edges, dashed cut rules, monospaced quantities, a barcode at the foot. The receipt is not decoration; it is the proof of the mechanism. Every line is a real package, and every leftover is a highlighted line that already points to the meal that will use it up.

The system runs at two volumes. The landing page (Persuade) is loud: violet fills the viewport, a condensed black headline, a tilted receipt printing in line by line, an arrow drawing from a REST line to its meal. The app (Operate) is the same world with more restraint: violet header band, receipts lying flat (the sign-in sample bon is the one tilted exception), dense lists sized for one-handed use in the aisle with 48dp targets throughout.

Colour carries meaning, never mood alone. Yellow means "leftover, and it has a plan". Green means "done or bought". Indigo means "the thing to press". Everything else is violet frame, paper and ink.

**Key Characteristics:**
- Violet frame band + thermal-paper receipts on a violet-tinted ground.
- Zig-zag tear edges, dashed cut rules and a centred letter-spaced `MEALMATE` receipt head are the world's native devices.
- Martian Mono for anything that is a receipt line: quantities, package counts, REST lines, aisle labels.
- Highlighter yellow is rationed to leftover lines and the targets they light.
- Motion is mechanical: a printer feed and a highlighter stroke, both static under reduced motion.

## Colors

A violet-and-paper palette with two signal inks (highlighter yellow, receipt green) and one indigo for action; the dark theme turns the paper into deep violet card stock rather than inverting it to grey.

### Primary
- **Frame Violet** (frame-violet): Owns the header band of every app screen, the landing page hero, nav and "how" section, the brand wordmark ground. White text on it holds 5.4:1; secondary text on it uses Frame Ink Muted (4.6:1). Never used as a small accent on paper; on paper the job goes to Accent Violet.
- **Action Indigo** (action-indigo): The fill of the primary button and the landing waitlist button, the phone bezel and the closing section. One primary action per view.
- **Accent Violet** (accent-violet): Links, selected chips, the active tab pill, focus rings and the primary-button hover on paper. Its soft tint (accent-soft) backs selected chips and the active tab.

### Secondary
- **Highlighter Yellow** (highlighter) with **Highlighter Ink** (on-highlighter): The REST line – a leftover with an assigned meal – and the target it lights (the landing phone's day row, the plan sheet's "verbraucht …" line). Also the landing focus ring and text selection, because on violet ground yellow is the only colour that reads as "look here". Identical in light and dark.

### Tertiary
- **Receipt Green** (done-green, dark: dark-done): Checked-off shopping items, the filled portion of the package bar, "Rest vom Fr" links in the plan. Done-soft backs success surfaces.
- **Storno Red** (danger, danger-soft): Errors only (field error border and text, the error box).

### Neutral
- **Violet Mist** (ground): App and landing section background behind paper; violet-tinted so paper reads as lifted.
- **Thermal Paper** (paper): Every receipt, card, sheet, field and the tab bar.
- **Sunken Paper** (paper-sunk): Hover on paper, secondary surfaces inside a receipt.
- **Receipt Ink** (ink) / **Faded Ink** (ink-muted): Text; ink-muted for "Bedarf …" sublines, hints, inactive tabs.
- **Cut Rule** (rule): Dashed rules, chip and field borders at rest, tab-bar top border.
- **Dark theme**: ground becomes dark-ground, frame becomes dark-frame (deep violet, not black), paper becomes dark-paper, ink becomes dark-ink, the action fill lightens to dark-action with dark-ground text. Highlighter stays yellow.

### Named Rules
**The Highlighter Rule.** Yellow marks a leftover that has a plan, and the thing it points at. Nothing else on paper is yellow: no badges, no promos, no warnings. If a line is yellow, the user should be able to read "REST" on it.

**The Frame Owns the Top Rule.** Violet is a region, not an accent. It fills the header band or the section; it does not appear as violet text on paper (that is Accent Violet's job).

**The Not By Colour Alone Rule.** Every coloured state also carries a word or mark: REST lines say "REST", checked items get a check glyph and strike-through, errors carry a message.

## Typography

**Display Font:** Archivo, condensed (Archivo Narrow 700 on native; variable Archivo at wdth 68–75, weight 900 on the web)
**Body Font:** Archivo (400/500/700/800)
**Label/Mono Font:** Martian Mono (400/600)

**Character:** A tall, compressed grotesk shouting the week's headline over a typewriter-receipt mono that does the counting. The condensed display is the voice; the mono is the evidence.

### Hierarchy
- **Hero** (900, clamp 3.4–6rem, 0.88): Landing h1 only. Section h2 on the landing uses the same face at wdth 72, clamp 2.2–3.6rem, 0.95.
- **Display** (700, 40px, 42px): Onboarding and screen-level hero titles on violet. The frame-header title runs 36px (44px wide).
- **Headline** (700, 28px, 32px): Sheet titles, the tab-layout wordmark.
- **Title** (700, 18px, 24px): Day names on plan receipts, card titles.
- **Body / Body Strong** (400/700, 16px, 23px): Running text; Body Strong for item names and button labels. Landing body runs 1.0625rem/1.55 with 32–62ch measures.
- **Label** (500, 14px, 19px): Field labels, chips, header subtitles, tab labels (12px in the phone tab bar).
- **Small** (400, 13px, 18px): Hints and helper text.
- **Mono / Mono Strong** (400/600, 13–14px): Quantities ("1 × 450 g"), REST lines, receipt heads (`MEALMATE`, letter-spacing 2px / 0.18em), aisle labels, steppers.

### Named Rules
**The Receipt Line Rule.** If it is a quantity, a package, a leftover or a line that would be printed on a till slip, it is set in Martian Mono. Names of food and recipes stay in Archivo.

**The Condensed Voice Rule.** Display sizes are always the condensed cut with tight negative tracking; never set a headline in regular-width Archivo.

## Layout

Single column on phones with a 16px gutter (space lg) and 16px vertical gaps between paper slips; content capped at 1120px and centred on wide screens. At 900px (the `wide` breakpoint) the bottom tab bar becomes a left sidebar with a violet brand block, sheets become centred 560px panels, and header titles step up. Spacing follows a 4-based scale (2/4/8/12/16/24/32/48); screens end with 48px of scroll padding so the last slip clears the tab bar.

The landing page uses a 1320px container with fluid gutters (clamp 1–3rem), a three-column first viewport (copy | receipt | phone, 1.05/0.95/0.62fr) that drops the phone below 1100px and stacks below 760px. Sections alternate full-bleed violet, ground, and indigo bands; padding is fluid (clamp 3.5–6.5rem).

## Elevation & Depth

Depth is paper lying on a surface. Receipts carry one soft, violet-tinted drop shadow so they read as slips laid on the ground; nothing else is lifted. Sheets rise over a dark violet scrim rather than casting their own shadow. The landing receipt and phone use a deeper, two-layer shadow because they float over a saturated violet field.

### Shadow Vocabulary
- **Slip** (`shadow-color rgba(43,26,120,0.16), offset 0 6px, radius 14px`; Android elevation 3): Every `Paper` receipt in the app.
- **Floating slip** (`box-shadow: 0 18px 40px -12px rgba(0,0,0,0.38), 0 4px 10px rgba(0,0,0,0.14)`): Landing receipt and phone over violet.
- **Scrim** (`rgba(18,14,36,0.55)`): Behind sheets.

### Named Rules
**The Only Paper Floats Rule.** Shadows belong to receipts and the landing phone. Buttons, chips, fields and rows are flat; they show state with fill, border and a 0.98 press scale.

## Shapes

Receipts have a straight top (6px corners) and a 12px-tooth zig-zag tear (7px deep in the app, 12px on the landing) at the open edge; a slip can be torn at the top, bottom, both, or neither. Interactive controls use gently rounded 10px corners (buttons, fields, entries, snackbars); chips, icon buttons and the active-tab pill are full pills; sheets round their top corners at 16px. The highlighter stroke has a near-square 3px corner, like a real marker swipe. Dividers inside paper are dashed (1.5px app, 2px landing), never solid. Small tilts (−1.2° to 1.4°) are reserved for showcase receipts: the landing hero, demo and steps strip, and the sign-in sample bon.

## Components

### Buttons
Firm, flat, labelled in Body Strong.
- **Shape:** gently rounded (10px), 2px border in the fill colour, min height 48px (40px compact), 24px side padding (16px compact), 8px gap to an optional 18px Lucide icon.
- **Primary:** Action Indigo fill, white label. One per view.
- **Hover / Focus / Press:** hover shifts the fill to Accent Violet; focus draws a 2px Accent Violet outline offset 2px (web); press scales to 0.98 in 120ms; disabled/loading drops to 50% opacity with a spinner.
- **Secondary:** transparent with an Ink border; hover fills Sunken Paper.
- **Ghost:** Accent Violet text, no border; hover fills accent-soft. Used for retry and snackbar actions.
- **On Frame / Frame Ghost:** on the violet band, a white fill with violet label, or a transparent button with a Frame Ink Muted border.
- **Landing CTA:** white with indigo text on violet/indigo bands (nav, close), indigo fill under the email field; 56px tall in the form and close section.

### Chips
- **Style:** pill, 40px tall, 1.5px Cut Rule border, Label type, optional 16px icon.
- **State:** selected switches border and text to Accent Violet over accent-soft; they are checkboxes to assistive tech.

### Cards / Containers (Receipt Paper)
- **Corner Style:** 6px on the straight edges, zig-zag on torn edges.
- **Background:** Thermal Paper.
- **Shadow Strategy:** Slip (see Elevation).
- **Border:** none; internal sections divided by dashed Cut Rules.
- **Internal Padding:** 16px.

### Inputs / Fields
- **Style:** Thermal Paper fill, 2px Cut Rule border, 10px radius, 52px min height, Label above, hint below in Small. Quantity fields switch to Mono Strong.
- **Focus:** border turns Accent Violet (the landing email field turns Highlighter with a 3px 45% yellow halo, since it sits on violet).
- **Error:** Storno Red border plus a polite live-region message in Small.

### Navigation
- **Phone:** paper tab bar, 1px Cut Rule top border, four tabs (Planen, Rezepte, Einkauf, Profil), 22px Lucide icons over 12px labels; active tab gets an accent-soft pill (56×30) and Accent Violet icon and label.
- **Wide (≥900px):** left sidebar on paper with a violet brand block (wordmark in display 28px), 48px rows, active row filled accent-soft.
- **Landing:** white condensed wordmark, Frame Ink Muted links that underline on hover, white CTA; links hide below 760px.

### Frame Header (signature)
The violet band at the top of every app screen: display title in Frame Ink, optional Label subtitle in Frame Ink Muted, optional left/right icon buttons and a child slot (the plan's day-chip strip). It ends where the first paper slip begins.

### REST Line (signature)
A leftover with a plan: Highlighter fill swiped left-to-right (220ms ease-out-expo, 120ms delay) behind Mono Strong "REST 350 g" and a Mono "→ Gnocchi mit Rahmspinat" subline, with an outlined "Einplanen" action in Highlighter Ink. On the landing, hovering or focusing a REST line draws a white arrow (280ms) to the meal it feeds and lights that target yellow.

### Print Feed (signature motion)
Receipt lines enter like a printer feed: each line fades and drops 6px over 260ms, staggered 40ms, capped at 8 lines, easing ease-out-expo. The landing hero receipt prints with a stepped clip reveal (900ms, 12 steps). Under reduced motion everything is static and fully visible; content never depends on the animation having run.

### Sheet
Bottom sheet on phones (16px top corners, max 88% height), centred 560px panel on wide screens; headline title with a close icon button. Opens in 260ms ease-out-expo, closes in 140ms ease-in. Snackbars use Ink fill with Paper text, 10px radius, above the tab bar.

## Do's and Don'ts

### Do:
- **Do** put every screen's title in the violet Frame Header and its content on Thermal Paper slips.
- **Do** set quantities, package counts and REST lines in Martian Mono, and divide receipt sections with dashed Cut Rules.
- **Do** reserve Highlighter Yellow for leftover lines that have a plan and for the targets they light.
- **Do** keep touch targets at 48dp or more (40px only for compact buttons and chips inside dense rows).
- **Do** make every motion skippable: print feed, highlighter swipe and arrow draw all resolve to the final static state under reduced motion.
- **Do** close faster than you open (260ms in, 140ms out).

### Don't:
- **Don't** use yellow for anything that is not a leftover: no promo badges, warnings or "new" tags.
- **Don't** place violet text or violet accents on paper as a substitute for Accent Violet; the frame violet is a region colour.
- **Don't** add shadows to buttons, chips or rows; only paper floats.
- **Don't** draw solid divider lines inside a receipt; cut rules are dashed.
- **Don't** tilt working receipts in the app; tilt belongs to showcase slips (landing, sign-in sample).
- **Don't** show food photography or invented savings figures as proof; the receipt's arithmetic is the proof, and sample data is labelled "Beispieldaten".
