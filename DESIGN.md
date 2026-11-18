---
version: "2.0"
name: "TopTutor tutor app"
description: "V5.6: soft paper, deep moss ink, sage for 'next / needs you', three surface levels, Bricolage Grotesque headlines, Charm handwriting in empty space, leaf photos. No copper, no logo."
status: "approved by Le Quoc Khanh 2026-11-12 (V5.5 style, then V5.6 for every screen); Michael Liebmann: copper dropped (fine), handwriting kept, brand headline font, no logo. Design canvas: claude.ai artifact 'TopTutor tutor app V5.6'."
colors:
  paper-top: "#F2F0EA"         # TutorColors.paperTop  (page gradient)
  paper-bottom: "#EDEDE8"      # TutorColors.paperBottom
  background: "#EFEEE9"        # TutorColors.bg / AppColors.cream
  surface: "#F5F4F0"           # TutorColors.surface, level-1 cards
  surface-sunken: "#ECEBE6"    # TutorColors.surfaceSunken, wells, icon tiles
  sage: "#E6EAE2"              # TutorColors.sage, 'next / needs you'
  ink: "#1F2A24"               # TutorColors.ink, text, buttons, dark block
  ink-muted: "#62686A"         # TutorColors.ink3
  ink-faint: "#6B716C"         # TutorColors.ink4 (>= 4.5:1 on paper)
  hand: "#7A807A"              # TutorColors.hand, Charm handwriting
  line: "rgba(31,42,36,.10)"   # TutorColors.line, thin dividers
  success: "#2E4A3A"
  warning-text: "#7A5B1E"
  danger: "#9B2C2C"
typography:
  display:
    fontFamily: "Bricolage Grotesque"   # brand headline font (decision 2026-10-19)
    fontWeight: "700"
    letterSpacing: "-0.022em"
  name:
    fontFamily: "Bricolage Grotesque"
    fontSize: "38px"
    fontWeight: "700"
  section:
    fontFamily: "Bricolage Grotesque"
    fontSize: "19px"
    fontWeight: "700"
  body:
    fontFamily: "Inter"
    fontSize: "15px"
    fontWeight: "500"
  sub:
    fontFamily: "Inter"
    fontSize: "13px"
    fontWeight: "500"
  label:
    fontFamily: "Inter"
    fontSize: "12.5px"
    fontWeight: "500"
    textTransform: "none"
  hand:
    fontFamily: "Charm"
    fontSize: "17-19px"
    rotate: "-4deg"
rounded:
  card: "20px"
  small: "12px"
  input: "14px"
  sheet: "24px"
  pill: "9999px"
spacing:
  gutter: "22px"
  row: "13px"
  section: "28px"
elevation:
  level-0: "flat on paper"
  level-1: "0 1px 2px 3% + 0 6px 18px 4.5% (TutorColors.cardShadow)"
  level-2: "0 1px 2px 4% + 0 16px 36px 11% (raisedCardShadow): banner, 'next' card, tab bar"
---

# TopTutor tutor app: design (V5.6)

Source of truth in code: `lib/core/constants/tutor_colors.dart`, `lib/core/constants/app_colors.dart`, `lib/core/theme/tutor_design.dart`, `lib/core/theme/app_theme.dart`, `lib/features/tutor/presentation/widgets/canvas_ui.dart`. Every screen is drawn on the design canvas "TopTutor tutor app V5.6" (boards V55-Home, V55-Lessons, V56-*).

## Overview
Two colours: paper and deep moss. Sage marks the one thing that is "next / needs you". Calm, light type; one short handwritten line in empty space; a leaf photo in an empty corner. The aim: every screen is understood at a glance; tasks start with a verb; every tip has a light bulb.

## Colors
- Paper gradient `#F2F0EA → #EDEDE8` behind every screen (`TutorSurface.paper`).
- Ink `#1F2A24` for text, the primary pill button and the one dark block per screen (the report banner on Home).
- Sage `#E6EAE2` for the "next / needs you" card (lifted), secondary pill buttons, tip boxes.
- Status colours only for real warnings (failed upload, failed delivery, delete). Never colour alone: always a word.
- No copper, navy or burgundy anywhere (`AppColors` keeps its old names with V5.6 values).

## Typography
- Headlines: Bricolage Grotesque Bold (brand font). Name on Home 38 px, screen titles 24–28 px, section titles 19 px.
- Text: Inter 15/500, secondary 13/500, labels 12.5/500 in sentence case (no uppercase kickers).
- Handwriting: Charm, ~18 px, rotated −4°, grey, with an optional swash (`CanvasHand`). One or two short Vietnamese lines per screen, only in empty space, never over content. Note: the 2026-10-19 brand font decision says "no handwritten fonts"; Charm is an approved exception for the app.
- No serif, no italic.

## Surfaces & shapes
- Three levels: flat on paper; level-1 card (`TutorSurface.card()`, radius 20, soft shadow); level-2 lifted (`lift()` / `sage()`).
- Pills for buttons and the tab bar; round 44 px buttons for back, bell, light bulb.
- Thin 10% dividers between rows; inputs on light wells (radius 14, moss focus border).
- Sheets: radius 24 top corners, grab handle.

## Navigation
- Floating pill tab bar: Trang chủ · Lộ trình · Bài học · Học sinh, plus a round moss record button on the right (opens the "Chọn buổi học" sheet).
- Recordings list (`/tutor/recordings`) is a sub-screen opened from Lộ trình.
- No logo in the app (only the plain word "TopTutor" on splash and login).

## Components (`canvas_ui.dart`)
- `CanvasHeader` (round back button, label, title, lead), `CanvasCircleButton`, `CanvasBackButton`.
- `CanvasCta` (moss pill; `secondary: true` = sage), `CanvasGhostLink`.
- `CanvasOutlineCard` (level-1; `sage: true` = lifted sage), `CanvasDarkCard`.
- `CanvasRow`, `CanvasStatRow`, `CanvasExpander`, `CanvasChevron`.
- `CanvasTag` (22 px chip; `filled` = ink), `CanvasAiDraftTag` ("Nháp AI").
- `CanvasTipBox` (sage, light bulb), `CanvasHand` (Charm), `CanvasSkillDots` (4 dots).

## Rules
- ✅ Every AI-drafted block carries "Nháp AI" (hard rule D1); it becomes "✓ Bạn đã sửa" once the tutor edits it.
- ✅ Skill levels are 4 dots (Cần học · Tiến bộ · Chuẩn · Vững), never a progress bar or a school grade.
- ✅ Pupils: name and grade only; no birth date, phone or school of the pupil (PDPL).
- ❌ Don't show a number the app cannot measure (per-speaker voice levels, "recorded well" quality, behaviour progress) — leave it out until the data exists.
- ❌ Don't format with the local Flutter: CI runs Flutter 3.38.9; format with `dart pub global run dart_style:format` (dart_style 3.1.2).

## Preview without a phone
`flutter run -t integration_test/preview_main.dart -d emulator-5554` runs the real app on the Android emulator against the fake backend of the as-built test (no real server, token or microphone). `integration_test/as_built_screens_test.dart` walks every screen and saves screenshots (`flutter drive --driver=test_driver/integration_test.dart --target=integration_test/as_built_screens_test.dart -d emulator-5554 --profile`, output folder `$AS_BUILT_OUT`).
