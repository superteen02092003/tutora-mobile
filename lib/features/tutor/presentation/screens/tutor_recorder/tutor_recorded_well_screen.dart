import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/core/router/app_routes.dart';
import 'package:tutora/core/theme/tutor_design.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_recorder/tutor_report_review_screen.dart';
import 'package:tutora/features/tutor/presentation/widgets/canvas_ui.dart';

/// Dữ liệu cho T11: lấy từ máy (thời lượng, mức âm thanh), không chờ server.
class RecordedWellArgs {
  const RecordedWellArgs({
    required this.review,
    required this.recordedMin,
    this.bookedMin,
    this.quietShare = 0,
  });

  final ReportReviewArgs review;
  final int recordedMin;
  final int? bookedMin;

  /// Tỉ lệ thời gian máy nghe nhỏ hoặc không nghe (0–1).
  final double quietShare;
}

/// T11 "Ghi âm tốt" (design V5.6, board V56-AfterRec): ngay sau khi kết thúc buổi, báo bản ghi
/// có ổn không, một mẹo cho lần sau, rồi mở bản nháp báo cáo.
class TutorRecordedWellScreen extends StatelessWidget {
  const TutorRecordedWellScreen({required this.args, super.key});

  final RecordedWellArgs args;

  bool get _good => args.quietShare < 0.25;

  String get _minutesLine {
    final b = args.bookedMin;
    return b != null && b > 0
        ? '${args.recordedMin} / $b phút'
        : '${args.recordedMin} phút';
  }

  void _openDraft(BuildContext context) => context.pushReplacement(
    AppRoutes.tutorReportReview,
    extra: args.review,
  );

  @override
  Widget build(BuildContext context) {
    final r = args.review;
    final kicker = [
      r.studentName,
      r.subtitle,
      _minutesLine,
    ].where((s) => s.trim().isNotEmpty).join(' · ');
    final quietPct = (args.quietShare * 100).round();

    return Scaffold(
      backgroundColor: TutorColors.bg,
      body: DecoratedBox(
        decoration: TutorSurface.paper,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    TutorSurface.gutter,
                    28,
                    TutorSurface.gutter,
                    16,
                  ),
                  children: [
                    // ── Dấu kết quả + tiêu đề ────────────────────────────
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _ResultRing(ok: _good),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      _good ? 'Ghi âm tốt' : 'Đã ghi xong',
                      style: TutorType.display(size: 32, height: 1.05),
                    ),
                    const SizedBox(height: 8),
                    Text(kicker, style: TutorType.rowSub()),
                    const SizedBox(height: 22),

                    // ── Kiểm tra bản ghi ─────────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: TutorSurface.card(),
                      child: Column(
                        children: [
                          _Check(
                            ok: true,
                            first: true,
                            text:
                                'Đã ghi ${args.recordedMin} phút và lưu lên máy chủ',
                          ),
                          _Check(
                            ok: _good,
                            text: _good
                                ? 'Âm thanh rõ'
                                : 'Âm thanh nhỏ khoảng $quietPct% thời gian',
                            link: _good
                                ? null
                                : InkWell(
                                    onTap: () => unawaited(
                                      context.push(
                                        AppRoutes.tutorRecordingTips,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Xem mẹo',
                                            style: TutorType.rowSub(
                                              color: TutorColors.ink,
                                            ),
                                          ),
                                          const Icon(
                                            Icons.chevron_right_rounded,
                                            size: 16,
                                            color: TutorColors.ink,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // ── Mẹo lần sau: chữ tay ở khoảng trống ──────────────
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: CanvasHand(
                          _good
                              ? 'Lần sau: giữ điện thoại\ngiữa bàn như hôm nay'
                              : 'Lần sau: đặt điện thoại\ngiữa bàn ngay từ đầu',
                          size: 18,
                          swash: false,
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),

                    // ── Báo cáo đang soạn (sage) ─────────────────────────
                    const _DraftingCard(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  TutorSurface.gutter,
                  8,
                  TutorSurface.gutter,
                  24,
                ),
                child: CanvasCta(
                  label: 'Mở bản nháp',
                  onPressed: () => _openDraft(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Vòng tròn 44 px: tô mực với dấu ✓ khi nghe rõ, viền xám với "!" khi nhỏ.
class _ResultRing extends StatelessWidget {
  const _ResultRing({required this.ok});

  final bool ok;

  @override
  Widget build(BuildContext context) => Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: ok ? TutorColors.ink : Colors.transparent,
      border: ok
          ? null
          : Border.all(color: const Color(0xFFA3A8A2), width: 1.6),
    ),
    child: Icon(
      ok ? Icons.check_rounded : Icons.priority_high_rounded,
      size: 22,
      color: ok ? Colors.white : TutorColors.ink,
    ),
  );
}

/// "Đang soạn báo cáo" — server soạn trong nền; không có tiến độ thật nên
/// thanh chạy không xác định.
class _DraftingCard extends StatelessWidget {
  const _DraftingCard();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
    decoration: TutorSurface.sage(lifted: false),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFF8F7F4),
            borderRadius: BorderRadius.circular(TutorSurface.radiusSmall),
          ),
          child: const Icon(
            Icons.edit_note_rounded,
            size: 20,
            color: TutorColors.ink,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Đang soạn báo cáo', style: TutorType.body()),
              Text(
                'Khoảng 5 phút. Điện thoại sẽ báo khi xong.',
                style: TutorType.rowSub(),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  minHeight: 4,
                  backgroundColor: TutorColors.ink.withValues(alpha: 0.12),
                  color: TutorColors.ink,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Check extends StatelessWidget {
  const _Check({
    required this.ok,
    required this.text,
    this.link,
    this.first = false,
  });

  final bool ok;
  final String text;

  /// Liên kết nhỏ dưới dòng chữ ("Xem mẹo ›").
  final Widget? link;
  final bool first;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 13),
    decoration: BoxDecoration(
      border: Border(top: first ? BorderSide.none : TutorSurface.rule),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(
            ok
                ? Icons.check_circle_outline_rounded
                : Icons.error_outline_rounded,
            size: 20,
            color: ok ? TutorColors.ink : TutorColors.warning,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(text, style: TutorType.body()),
              ?link,
            ],
          ),
        ),
      ],
    ),
  );
}
