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

/// T11 "Ghi âm tốt" (canvas H3-AfterRec): ngay sau khi kết thúc buổi, báo bản ghi
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
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                children: [
                  CanvasHeader(
                    left: kicker,
                    title: _good ? 'Ghi âm tốt' : 'Đã ghi xong',
                    lead: _good
                        ? '$_minutesLine · nghe rõ phần lớn buổi'
                        : '$_minutesLine · máy nghe nhỏ khoảng $quietPct% thời gian',
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: TutorSurface.screenPadding,
                    child: Column(
                      children: [
                        _Check(
                          ok: true,
                          text:
                              'Đã ghi ${args.recordedMin} phút và lưu lên máy chủ',
                        ),
                        _Check(
                          ok: _good,
                          text: _good
                              ? 'Âm thanh rõ'
                              : 'Âm thanh nhỏ khoảng $quietPct% thời gian',
                          trailing: _good
                              ? null
                              : InkWell(
                                  onTap: () => unawaited(
                                    context.push(AppRoutes.tutorRecordingTips),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: Text(
                                      'Xem mẹo',
                                      style: TutorType.action(
                                        color: TutorColors.warning,
                                      ),
                                    ),
                                  ),
                                ),
                          last: true,
                        ),
                        const SizedBox(height: 18),
                        CanvasTipBox(
                          _good
                              ? 'giữ điện thoại ở giữa bàn như hôm nay.'
                              : 'đặt điện thoại ở giữa bàn ngay từ đầu buổi.',
                          bold: 'Lần sau:',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                TutorSurface.gutter,
                12,
                TutorSurface.gutter,
                20,
              ),
              child: Column(
                children: [
                  Text(
                    'Báo cáo đang được soạn, khoảng 5 phút. Điện thoại sẽ báo '
                    'khi xong.',
                    textAlign: TextAlign.center,
                    style: TutorType.rowSub().copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  CanvasCta(
                    label: 'Mở bản nháp',
                    onPressed: () => _openDraft(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Check extends StatelessWidget {
  const _Check({
    required this.ok,
    required this.text,
    this.trailing,
    this.last = false,
  });

  final bool ok;
  final String text;
  final Widget? trailing;
  final bool last;

  @override
  Widget build(BuildContext context) => CanvasRow(
    lastRule: last,
    child: Row(
      children: [
        SizedBox(
          width: 40,
          child: Text(
            ok ? '✓' : '!',
            style: TutorType.display(
              size: 26,
              weight: FontWeight.w300,
              color: ok ? TutorColors.success : TutorColors.warning,
            ),
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              height: 1.35,
              fontWeight: FontWeight.w500,
              color: TutorColors.ink,
            ),
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 10), trailing!],
      ],
    ),
  );
}
