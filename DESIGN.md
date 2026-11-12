---
version: "1.0"
name: "TopTutor tutor app"
description: "Swiss / editorial: paper background, ink type and 1.5 px ink rules, big grotesque headlines, copper for actions only, no shadows."
status: "proposed, 2026-11-12 (Le Quoc Khanh); awaits Michael Liebmann. Record: toptutor-main 00-strategy/01-decisions/2026-11-12_tutor-app-visual-style.md"
colors:
  background: "#F6F4EE"        # TutorColors.bg, paper
  surface-sunken: "#EDEAE0"    # TutorColors.surfaceSunken, info boxes, wells
  ink: "#1B352D"               # TutorColors.ink, text and rules
  ink-strong: "#24443A"        # TutorColors.ink2 / heroInk, headlines, the one dark card
  ink-muted: "#566860"         # TutorColors.ink3, secondary text, kickers
  ink-faint: "#66766D"         # TutorColors.ink4, captions
  line: "#CFCBBE"              # TutorColors.line, light dividers inside a block
  accent: "#D9A15B"            # TutorColors.accent, copper: actions only
  accent-soft: "#F6E8D3"       # TutorColors.accentBg
  success: "#1F6B43"           # TutorColors.success
  warning-text: "#8A5A12"      # TutorColors.warning (brown, readable on paper)
  danger: "#9B2C2C"            # TutorColors.danger
  on-dark: "#FFFFFF"
typography:
  display:
    fontFamily: "Bricolage Grotesque"
    fontWeight: "800"
    letterSpacing: "-0.045em"
    lineHeight: "1.0"
  numeral:
    fontFamily: "Bricolage Grotesque"
    fontWeight: "300"
  base:
    fontFamily: "Inter"
    fontSize: "16px"
    lineHeight: "1.35"
  kicker:
    fontFamily: "Inter"
    fontSize: "12px"
    fontWeight: "700"
    letterSpacing: "1.7px"
    textTransform: "uppercase"
rounded:
  sm: "6px"
  md: "6px"
  full: "9999px"
spacing:
  gutter: "24px"
  row: "14px"
  row-gap: "10px"
  section: "28px"
components:
  button-primary:
    backgroundColor: "{colors.accent}"
    textColor: "{colors.ink}"
    rounded: "{rounded.md}"
    height: "56px"
  button-ghost:
    textColor: "{colors.ink-muted}"
    height: "44px"
  row:
    borderTop: "1.5px solid {colors.ink}"
    padding: "{spacing.row} 0"
  card-outline:
    backgroundColor: "transparent"
    border: "1.5px solid {colors.ink}"
    rounded: "{rounded.md}"
  card-dark:
    backgroundColor: "{colors.ink-strong}"
    textColor: "{colors.on-dark}"
    rounded: "{rounded.md}"
  tip-box:
    backgroundColor: "{colors.surface-sunken}"
    icon: "lightbulb_outline"
    rounded: "{rounded.md}"
  tag:
    border: "1.5px solid {colors.ink}"
    rounded: "{rounded.md}"
    text: "{typography.kicker}"
---

# TopTutor tutor app: design

**Status: proposed (2026-11-12).** This file writes down the style the tutor app already uses on branch `feat/tutor-redesign` (PR #49), so nobody has to infer it from code. Michael Liebmann approves it; until then the code is the reference. Source of truth for each value: `lib/core/constants/tutor_colors.dart`, `lib/core/theme/tutor_design.dart`, `lib/features/tutor/presentation/widgets/canvas_ui.dart`. The design canvas (claude.ai artifact "TopTutor: tutor app and parent Mini App", pages H3-*) shows every screen.

## Overview

**Swiss style (International Typographic Style) with an editorial feel.** A paper-coloured page, ink text, blocks separated by 1.5 px ink rules instead of cards and shadows, small uppercase "kicker" labels, big tight grotesque headlines, thin large numerals for counts. Few colours, each with one job. Everything aligns to one left edge (24 px gutter).

The aim (meeting 2026-11-10): every screen is understood at a glance. Tasks start with a verb, gaps are numbered, and every tip or information box carries a light bulb: "this is like a design language".

## Colors

- **Paper `#F6F4EE`**: every screen's background. No white cards on paper.
- **Ink `#1B352D`**: body text and all rules. **Ink strong `#24443A`**: headlines and the one dark "in focus" card per screen.
- **Ink muted `#566860` / faint `#66766D`**: secondary text, kickers, captions.
- **Copper `#D9A15B`: actions only.** The primary button, and the filled "Please approve / Cần duyệt" tag. Text on copper is ink, never white (contrast).
- **Sunken `#EDEAE0`**: tip and information boxes, wells.
- **Status**: success `#1F6B43`, warning text `#8A5A12` (brown: copper is too light for text), danger `#9B2C2C`. Always with a word, never colour alone.
- **Relation to the brand palette.** The proposed online brand palette "Sage" (toptutor-main decision 2026-10-21, item 5) keeps background `#F6F4EE`, anchor `#24443A` and accent `#D9A15B`, but its text colour is `#26332E` and its main colour `#3F6B57`. The app uses ink `#1B352D` for text and barely uses `#3F6B57`. To settle together with the brand palette.

### Proposed next (canvas board "V2 · Status colours and labels", not in code yet)
- Copper strictly for "you act now".
- Four maths-skill levels as one green family, light to dark: to do (grey outline), improving `#A9CDB4`, standard `#2F7D4F`, mastered `#1B352D`, so a level never reads like a school grade.
- Gap: earth orange (`#8A3F12` on `#F3DDC9`); error: deep red `#8E2B2B`; later / not in this version: grey.
- One label set for a report's life: Recording, Recorded, AI drafting, Please approve, Approved, Sent.
- Authorship chips: "AI draft" (dashed outline), "Edited by you" (solid outline), "From the lesson" (quote with minute). Hard rule D1: no AI text reaches a parent as the tutor's own.

## Typography

- **Display: Bricolage Grotesque.** Headlines weight 800, tight tracking (−0.045 em), line height 1.0. Screen titles 46 px on screens seen once (welcome, path, a pupil's profile); **proposed: 30 px on daily screens** (Home, Lessons, Recordings, Settings), from the design review of 2026-11-12.
- **Numerals: Bricolage Grotesque 300** (thin, large: 30–84 px) for counts, times, the recording clock.
- **Text: Inter.** Rows 16 px / 1.35, weight 500; secondary 13–15 px.
- **Kicker: Inter 12 px, 700, uppercase, 1.7 px tracking.** Section labels and the line above a title ("GIA SƯ HÀ · 2 HỌC SINH").
- **Not used:** serif italic (Michael, 2026-11-10: it "distracts from reading"); IBM Plex Serif only for the logo wordmark and quotations.
- The app is Vietnamese; check every font size with Vietnamese diacritics (stacked marks need line height ≥ 1.0 for display, ≥ 1.3 for text).

## Layout & Spacing

- 24 px side gutter on every screen; 28 px between sections; 14 px row padding; 10 px between rows of one group.
- Lists are **ruled rows** (`CanvasRow`): a 1.5 px ink rule on top, optional rule under the last row.
- Four text tabs at the bottom (Trang chủ · Lộ trình · Bài học · Ghi âm), the active one underlined in copper. No floating buttons.
- Phone first (390 × 844 design frame); test on the Galaxy Z Fold6 cover screen too.

## Shapes

- **Corners: 6 px everywhere** (buttons, cards, tags, inputs). Circles only for status dots and avatars' fallback.
- **No shadows.** Separation comes from paper vs. ink rules. The only raised elements were the old floating nav and mic, now removed.
- Rules are 1.5 px ink; light dividers inside a block are 1 px `#CFCBBE`.

## Components (`canvas_ui.dart`)

- `CanvasHeader`: kicker left/right, big title, optional lead line, "‹ Quay lại" as a kicker for back.
- `CanvasCta`: copper, 56 px high, ink text. One per screen.
- `CanvasGhostLink`: grey text link, 44 px tap target, for secondary actions ("Mẹo ghi âm ›").
- `CanvasRow` / `CanvasStatRow`: ruled rows; stat rows put a kicker label left and a thin large numeral right.
- `CanvasDarkCard`: ink-strong block, white text: the one thing in focus, once per screen.
- `CanvasOutlineCard`: 1.5 px ink outline on paper: a second, lighter emphasis.
- `CanvasTipBox`: sunken grey with a light bulb icon; for every tip and information line.
- `CanvasExpander`: `<details>`-like ruled row with + / −, for content that can wait.
- `CanvasTag`: uppercase outlined tag; `filled` = copper (only for "Please approve").
- Recording (T10): the one dark full screen (ink background), thin 84 px clock, slide-to-end instead of a button.

## Do's and Don'ts

- ✅ Do lead each screen with the action ("Please approve" first), then the information.
- ✅ Do give every tip a light bulb box; every status a word.
- ✅ Do keep one copper button and at most one dark card per screen.
- ✅ Do reuse `canvas_ui.dart`; add a component there before styling one screen by hand.
- ❌ Don't use white cards, rounded-16 cards or shadows (the old style).
- ❌ Don't use copper for decoration or for progress; don't put white text on copper.
- ❌ Don't use serif italic, playful icons or emoji in the interface (the star artwork is the exception).
- ❌ Don't show a number the app cannot measure (e.g. per-speaker voice levels).
- ❌ Don't format with the local Flutter: CI runs Flutter 3.38.9; format with `dart pub global run dart_style:format` (dart_style 3.1.2).
