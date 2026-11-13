import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/core/router/app_routes.dart';
import 'package:tutora/core/theme/tutor_design.dart';
import 'package:tutora/features/tutor/presentation/widgets/canvas_ui.dart';

/// T7 · Mẹo ghi âm (design V5.6, board V56-Tips): thói quen của tuần trong thẻ
/// sage nổi, bốn điều cơ bản (kể cả học online) và đủ 6 thói quen. Nội dung
/// tĩnh.
class TutorRecordingTipsScreen extends StatelessWidget {
  const TutorRecordingTipsScreen({super.key});

  static Future<void> open(BuildContext context) =>
      GoRouter.of(context).push(AppRoutes.tutorRecordingTips);

  static const List<(String, String?)> _basics = [
    ('Điện thoại đặt giữa bàn', null),
    ('Phòng yên tĩnh', null),
    ('Pin trên 30% · mang sạc', null),
    (
      'Học online',
      'Dùng loa laptop, không tai nghe, đặt điện thoại cạnh laptop.',
    ),
  ];

  static const _habits = [
    'Bấm ghi trước khi chào con',
    'Nhờ con đọc to đề bài',
    'Đọc to điều mình viết lên bảng',
    'Hỏi xong, đếm thầm đến ba',
    'Không nói đè lên con',
    'Nhắc con nói to hơn nếu nhỏ',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TutorColors.bg,
      body: DecoratedBox(
        decoration: TutorSurface.paper,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              CanvasHeader(
                onBack: () => Navigator.of(context).maybePop(),
                title: 'Mẹo ghi âm',
                lead: 'Thói quen nhỏ cho bản ghi rõ.',
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  TutorSurface.gutter,
                  18,
                  TutorSurface.gutter,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Thói quen tuần này (sage nổi) ─────────────────────
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: TutorSurface.sage(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.lightbulb_outline_rounded,
                                size: 16,
                                color: TutorColors.ink,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Thói quen tuần này',
                                style: TutorType.caption(
                                  color: TutorColors.ink,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Hỏi xong, đếm thầm đến ba.',
                            style: TutorType.display(
                              size: 19,
                              weight: FontWeight.w500,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Con trả lời dài hơn, và mình nghe con rõ hơn.',
                            style: TutorType.rowSub(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Bốn điều cơ bản ──────────────────────────────────
                    for (final (i, (title, sub)) in _basics.indexed)
                      _StepRow(
                        n: i + 1,
                        title: title,
                        sub: sub,
                        firstRule: i > 0,
                      ),
                    const SizedBox(height: 12),

                    // ── Đủ 6 thói quen ───────────────────────────────────
                    Text('Cả 6 thói quen', style: TutorType.sectionTitle()),
                    const SizedBox(height: 8),
                    for (final (i, h) in _habits.indexed)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '${i + 1}. $h',
                          style: TutorType.rowSub(
                            color: TutorColors.ink,
                          ).copyWith(height: 1.6),
                        ),
                      ),
                    const SizedBox(height: 28),
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: CanvasHand('Mỗi tuần một thói quen', size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hàng có số tròn viền (step.off) và đường kẻ mảnh phía trên.
class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.n,
    required this.title,
    required this.sub,
    required this.firstRule,
  });

  final int n;
  final String title;
  final String? sub;
  final bool firstRule;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 13),
    decoration: BoxDecoration(
      border: Border(top: firstRule ? TutorSurface.rule : BorderSide.none),
    ),
    child: Row(
      crossAxisAlignment: sub == null
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFA3A8A2), width: 1.4),
          ),
          child: Text(
            '$n',
            style: TutorType.caption(color: TutorColors.ink),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TutorType.body()),
              if (sub != null) Text(sub!, style: TutorType.rowSub()),
            ],
          ),
        ),
      ],
    ),
  );
}
