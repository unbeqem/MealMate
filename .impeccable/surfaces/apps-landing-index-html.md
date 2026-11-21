---
version: 1
slug: "apps-landing-index-html"
primary_target: "apps/landing/index.html"
related_targets: ["apps/mobile"]
---

# Surface brief: Landing page (Warteliste)

Scope: apps/landing/index.html, visitor mode **Persuade**. The app screens (apps/mobile, mode **Operate**) inherit the same world with more restraint.

Audience: 20–35, Singles/Paare in Deutschland, die Packungsreste wegwerfen. Action: sich auf die Warteliste eintragen (E-Mail, funktionierendes Formular im ersten Viewport). Proof: the mechanism itself, shown on a receipt (sample data, labelled „Beispieldaten“). No invented users, numbers, partners.

## Direction contract

THESIS: MealMate prints your receipt before you shop: every line is a real package, every leftover a highlighted line already assigned to a later meal. Refuses the category default of food photography + phone mockup + green button.

OWN-WORLD: Saturated violet ground (#7C5CFF) owning whole regions, deep indigo (#2B1A78) for actions, thermal-paper white (#FBFBF8) receipts with zig-zag tear edge, dashed cut rules, barcode; highlighter yellow (#FFE45C) only for leftover lines; mint (#5CE1B0) for "done/verplant". Archivo condensed black for headlines, Martian Mono for anything that is a receipt line (quantities, packages), Archivo for body.

STORY: Visitor sees the receipt, understands "it rounds to packages and plans the rest", believes it because the receipt shows the math (Bedarf → Packung → Rest → Rezept), joins the waitlist.

FIRST VIEWPORT: Left: condensed headline „Kauf nur, was du isst.“, one-sentence lead, waitlist form (email + indigo button). Center: a tilted receipt (~440px) printing in line by line, two highlighted REST lines, total „Weggeworfen 0 g“. Right: phone showing the shopping list with the leftover banner. Primary action in the left column at ~y 500.

FORM: Der Kassenbon, position 1 on my ordered grounded list (chosen as IMPECCABLE'S PICK), seed:8118e4a55f00c617. Signature interaction: receipt prints line by line on load; hovering/tapping a REST line draws the arrow to its recipe. Motion grammar: print feed (vertical, stepped), highlighter swipe (left→right), reduced motion = static receipt.

FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance
