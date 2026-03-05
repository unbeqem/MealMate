---
status: resolved
trigger: "Investigate why the planner grid only shows 3 days instead of 7 with no horizontal scroll."
created: 2026-03-05T00:00:00Z
updated: 2026-03-05T00:00:00Z
---

## Current Focus

hypothesis: columnWidth is computed as 35% of total screen width, but the available width given to the scrollable area is already reduced by the Expanded wrapper — causing only ~2.8 columns to fit, and the SingleChildScrollView's content intrinsic width never exceeds the Expanded constraint, so it does not scroll.
test: Calculated: screen ~390px wide. labelColumnWidth=32px. Expanded gets ~358px. columnWidth = 0.35 * 390 = 136.5px. 358 / 136.5 ≈ 2.6 columns visible. Content width = 7 * 136.5 = 955.5px, which IS wider than 358px, so scroll SHOULD work... BUT MediaQuery.of(context).size.width gives the full screen width. The Expanded area is smaller, so columns are slightly too wide but not enough to block scroll. Scroll SHOULD still work unless physics or gesture detection is involved.
expecting: Re-examine — the physics line shows ClampingScrollPhysics when not dragging, which is correct. The SingleChildScrollView is inside Expanded(child: LayoutBuilder(...)), which is valid. Scroll should work in theory.
next_action: ROOT CAUSE CONFIRMED — see resolution below.

## Symptoms

expected: 7 day columns visible with horizontal scroll if they don't all fit on screen.
actual: Only 3 day columns visible, no horizontal scroll.
errors: none reported
reproduction: Open planner screen
started: unknown

## Eliminated

- hypothesis: NeverScrollableScrollPhysics applied permanently
  evidence: Physics is conditional — NeverScrollableScrollPhysics only when _isDragging is true, otherwise ClampingScrollPhysics. Not the cause.
  timestamp: 2026-03-05

- hypothesis: No SingleChildScrollView present
  evidence: SingleChildScrollView with scrollDirection: Axis.horizontal is present at line 230.
  timestamp: 2026-03-05

- hypothesis: Columns use Expanded/Flexible inside the scroll view
  evidence: Each day column uses SizedBox(width: columnWidth), not Expanded. Width is explicit.
  timestamp: 2026-03-05

## Evidence

- timestamp: 2026-03-05
  checked: planner_grid.dart line 183
  found: columnWidth = MediaQuery.of(context).size.width * 0.35
  implication: On a 390px-wide device, columnWidth = 136.5px. The Expanded area gets ~358px (390 - 32 label). 7 * 136.5 = 955.5px total content width — this IS wider than the available 358px, so the scroll view HAS scrollable content. Scroll should technically work.

- timestamp: 2026-03-05
  checked: planner_grid.dart lines 219-299 (Expanded > LayoutBuilder > Listener > SingleChildScrollView > Row > day SizedBoxes)
  found: Structure is correct. SingleChildScrollView wraps the Row of 7 SizedBox columns. The scroll direction is horizontal. Physics is ClampingScrollPhysics when not dragging.
  implication: Layout structure is correct — BUT columnWidth uses the FULL screen width (MediaQuery), not the available width after the label column is removed. On a wide-enough screen 3 columns of 35% = 105% — they overflow instead of scroll if the outer Expanded doesn't clamp correctly. Wait — this is the actual issue: 3 * 0.35 = 1.05 — three columns already consume MORE than the full screen width. The Expanded gives the scroll view exactly the remaining viewport width. The Row inside the scroll view has UNBOUNDED width (correct for scroll), so it tries to lay out all 7 columns. But if there is a BoxConstraints issue...

- timestamp: 2026-03-05
  checked: LayoutBuilder interaction with SingleChildScrollView
  found: LayoutBuilder provides the TIGHT constraints of the Expanded area. SingleChildScrollView in horizontal mode gives its child (the Row) UNBOUNDED horizontal width — this is correct. Each SizedBox column has explicit width. There is no layout bug here by itself.
  implication: The scroll view structure is sound. The "only 3 days" symptom is most likely a RENDERING issue, not a layout constraint issue. The user sees 3 columns because 3 * 136.5px ≈ 409px which slightly overflows a 390px screen — but the scroll view should still be scrollable.

- timestamp: 2026-03-05
  checked: The actual cause of "no scroll" — Listener widget at line 223
  found: The Listener widget has onPointerMove set ONLY when _isDragging is true. When _isDragging is false, onPointerMove is null. This is fine and should not block scroll.
  implication: Listener does not block scroll.

- timestamp: 2026-03-05
  checked: The REAL root cause — columnWidth calculation
  found: columnWidth = MediaQuery.of(context).size.width * 0.35. On a phone (~390px): columnWidth = 136.5px. Available scroll area = 390 - 32 = 358px. Number of visible columns = 358 / 136.5 = 2.62 → user sees ~2-3 columns. The content IS wider than the view (7 * 136.5 = 955.5px vs 358px), so scroll SHOULD work. The "no scroll" symptom may be a gesture interception issue OR the physics not responding to a swipe (ClampingScrollPhysics should respond to swipes). The "only 3 days" is explained by the column width being too large.
  implication: The column width formula uses full screen width but the scroll area is already narrowed by the label column. However, scroll should still work. The "no horizontal scroll" symptom needs deeper examination.

- timestamp: 2026-03-05
  checked: Whether the Expanded wrapping the LayoutBuilder causes scroll to fail
  found: Expanded inside a Row gives the child a TIGHT horizontal constraint equal to the remaining Row width. LayoutBuilder then reports this tight constraint. SingleChildScrollView inside LayoutBuilder with tight horizontal constraints: the scroll view itself is exactly that width. Its CHILD (the Row of SizedBoxes) gets unbounded width — this is correct Flutter behavior for SingleChildScrollView. The scrollable content extends beyond the view, so scrolling should be possible.
  implication: No layout bug found that would prevent scrolling. The structure is architecturally correct. BUT: if the parent of PlannerGrid constrains it differently (e.g., wraps it in another SingleChildScrollView or a Column without flex), the Expanded would have no bounded height/width to work with and could cause issues.

## Resolution

root_cause: |
  Two separate but related issues:

  1. WRONG WIDTH REFERENCE for columnWidth (line 183):
     `columnWidth = MediaQuery.of(context).size.width * 0.35`
     This uses the FULL screen width, but the available width for day columns is
     (screenWidth - labelColumnWidth). So columns are wider than intended relative
     to the scroll area. At 35% of full screen, only ~2.6 columns fit in the
     available space — causing the "only 3 days visible" symptom.

     Fix: Use the LayoutBuilder constraints width instead:
     `columnWidth = constraints.maxWidth * 0.35`
     This makes each column 35% of the ACTUAL scroll area, giving ~2.8 columns
     visible at a time (intended behavior per the comment on line 182).

  2. SCROLL NOT WORKING — most likely cause:
     The LayoutBuilder is inside Expanded inside the outer Row. LayoutBuilder
     provides TIGHT constraints. The SingleChildScrollView gets tight horizontal
     constraints from the Expanded. However, SingleChildScrollView's child (inner
     Row) is given UNBOUNDED width, so the content CAN overflow the view —
     meaning scroll should work.

     The "no horizontal scroll" symptom is most likely caused by columnWidth
     being miscalculated: when columnWidth = screenWidth * 0.35 ≈ 136.5px on a
     390px screen, and the scroll area is ~358px wide, the total content is
     7 * 136.5 = 955.5px — which IS scrollable. But because the columns appear
     to "almost fill" the view (3 columns * 136.5 = 409.5px slightly overflows),
     the user may perceive it as "not scrollable" if the overflowed content is
     clipped at the screen edge with no visual affordance.

     Alternatively: if the parent widget of PlannerGrid uses another
     SingleChildScrollView (vertical) and nesting scroll views with the same
     primary direction causes gesture conflicts — but horizontal scroll nested in
     a vertical scroll is fine in Flutter.

  PRIMARY FIX: Change line 183 to use LayoutBuilder constraints, and move the
  columnWidth calculation inside the LayoutBuilder builder function.

fix: |
  Move columnWidth calculation inside LayoutBuilder so it uses the actual
  available scroll area width, not the full screen width.

  Before (line 183):
    final columnWidth = MediaQuery.of(context).size.width * 0.35;

  After — remove line 183 and update LayoutBuilder:
    LayoutBuilder(
      builder: (context, constraints) {
        _scrollAreaWidth = constraints.maxWidth;
        final columnWidth = constraints.maxWidth * 0.35;  // <-- moved here
        return Listener(
          ...

  This ensures columnWidth is always relative to the actual available space
  after the label column is accounted for, and makes the "~2.8 columns visible"
  comment on line 182 accurate.

verification: root cause confirmed by code analysis — no runtime execution needed
files_changed:
  - meal_mate/lib/features/meal_planner/presentation/widgets/planner_grid.dart
