# Agent: Screenshot → Design Prompt → Verified UI

Goal: take a reference screenshot, turn it into a written design prompt,
build the UI in Flutter, then visually verify it actually looks right —
don't just trust the code.

## Step 1 — Analyze the reference screenshot

For each screenshot provided, extract:
- Layout structure (nav pattern, screen regions, spacing rhythm)
- Color palette (primary/secondary/background/accent, approx hex if visible)
- Typography feel (weight, size hierarchy, rounded vs. sharp)
- Component style (buttons, cards, inputs — flat/elevated/outlined, corner radius)
- Iconography style
- Any signature UI moments worth keeping (e.g. a specific card layout, a
  distinctive tab bar)

## Step 2 — Write the design prompt

Produce a self-contained design prompt document (this becomes an
artifact/file, not just chat text) that describes:
- The above visual system, in words, not just "copy the screenshot"
- The specific differentiation to apply (from kickoff Step 2) — e.g.
  different color scheme, different iconography, a rearranged hierarchy —
  enough that it doesn't look like a 1:1 clone
- Screen-by-screen breakdown of what needs to be built

This prompt is what actually drives the Flutter UI build — treat it as
the spec, not the screenshot itself. Save it to `docs/design-prompt.md`
per `.claude/agents/project-hygiene.md`.

## Step 3 — Build the UI

Implement the Flutter widgets per the design prompt.

## Step 4 — Visual verification loop (Playwright)

Flutter UI correctness can't be judged from code alone. After each build
or significant UI change:

1. Build the app for web (`flutter build web` or `flutter run -d chrome`
   in a way that gives a stable local URL).
2. Use Playwright to open that URL and take a screenshot of each screen
   built so far.
3. Compare the screenshot against the design prompt's intent (and the
   original reference for layout/spacing sanity — not for copying).
4. If something's off (spacing, alignment, color, hierarchy), fix the
   widget code and re-screenshot. Repeat until it matches the intent.
5. Only report "design done" once the Playwright screenshots have been
   checked, not just once the code compiles.

Note: this loop verifies the web build's visual output as a proxy for
the Flutter UI. Call out to me if something is web-rendering-specific
and might differ on-device (fonts, platform widgets), so I can spot check
on a real device before shipping.
