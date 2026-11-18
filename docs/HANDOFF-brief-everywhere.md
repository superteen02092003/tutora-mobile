# Handoff — the 15-minute brief everywhere (Khanh, 2026-11-18)

Branch `feat/brief-everywhere` (from `feat/tutor-redesign`). Design: canvas
https://claude.ai/artifact/2srTp55xc9WYYtxBPYJVgu, row 7 (V510-*), approved by Khanh 2026-11-18.

## Done
- Tab "Bài học" → "Lịch" (`shell/v2/tutor_shell_v2.dart`), integration test updated.

## To do (in this order)
1. **Recording screen** (`screens/tutor_recorder/tutor_recording_screen.dart`): sage card "Kế hoạch 15 phút"
   under the timer (sub line: Ưu tiên 1 title). Tap → modal bottom sheet with the plan (reuse `_PlanView`
   from `topi_before_lesson_screen.dart`: make it public or add `TopiPlanSheet.show(context, lessonId)`),
   red chip "Vẫn đang ghi · mm:ss", button "Đóng, tiếp tục buổi học". Recording must not stop
   (sheet only, no route pop). Plan source: `lessonTopiProvider(<latest reported lesson of the pupil>)`
   — same lesson `latestReportedLesson()` picks on the pupil profile. Hide the card when flags.plan is off
   or there is no plan. Canvas: V510-Recording, V510-RecordingPlan.
2. **Lịch tab** (`screens/tutor_schedule/tutor_calendar_agenda.dart`): each lesson card gets an inner
   lighter box "Kế hoạch trước giờ học" + one-line preview ("Ưu tiên 1: … 15 phút đầu: …"). Tap → sheet
   with the brief (date/time, pupil, Ưu tiên 1, steps, "Xem kế hoạch đầy đủ" → `TopiBeforeLessonScreen`,
   "Bắt đầu ghi âm"). Lesson without a plan yet: "Có sau khi buổi <dd/mm> được ghi âm và xử lý xong";
   pupil with no recorded lesson: no box. Canvas: V510-Calendar, V510-CalendarBrief.
3. **Quick record** (nav mic → `tutor_recorder_entry_screen.dart` / `recording_target.dart`): each lesson
   row gets "Brief 15 phút" (light green pill) next to "Ghi âm"; opens the same brief sheet. Canvas: V510-QuickRecord.
4. Tests for the sheet (plan shown / hidden), `flutter analyze`, `flutter test`, PR into `feat/tutor-redesign`.
5. Build for the phone: `flutter build apk --profile --dart-define=BASE_URL=https://api.toptutor.ai`
   (profile = package `ai.toptutor.record.dev`; release would be the Play package — never install that).
   Install: `adb -s R3CX8032MEP install -r build/app/outputs/flutter-apk/app-profile.apk`;
   Fold6 screenshots: `adb exec-out screencap -p -d 4630947194243491972`.

## Also open (not this branch)
- tutora-mobile#53 "Gợi ý của Topi" label: not merged.
- Canvas row 6 (V59): "Cần luyện tập" moves from the profile into "Xem cả N kỹ năng" — designed, not built.
- Topi watch rule: an error seen in one lesson must stay "theo dõi"; `plan.py` `rank_gaps` still promotes
  the top watch to focus (scoring-model.md, process 07).
- Never record or tap send/approve in the .dev app: it uses the production server.
