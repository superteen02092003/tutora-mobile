import 'package:flutter/material.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/core/theme/tutor_design.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_recorder/tutor_report_review_screen.dart';
import 'package:tutora/features/tutor/presentation/widgets/canvas_ui.dart';
import 'package:tutora/features/tutor/presentation/widgets/lesson_insights_card.dart';
import 'package:tutora/features/tutor/presentation/widgets/topi_skills_section.dart';
import 'package:tutora/features/tutor/presentation/widgets/topi_tips_card.dart';

/// Kết quả "Trượt để gửi phụ huynh" — dữ liệu cho bước 2/3 và 3/3.
class ReportSentArgs {
  const ReportSentArgs({
    required this.lessonId,
    required this.studentName,
    required this.offPlatform,
    required this.approvedAtUtc,
    this.lessonDay,
    this.deliveryChannel,
    this.deliveryStatus,
    this.aiDrafted = true,
    this.hasParentPhone = true,
  });

  final String lessonId;
  final String studentName;

  /// Học sinh ngoài nền tảng (gửi Zalo); false = buổi có booking (TopTutor).
  final bool offPlatform;
  final DateTime approvedAtUtc;
  final DateTime? lessonDay;

  /// zns | booking | null (chưa gửi được, vd. chưa có SĐT phụ huynh).
  final String? deliveryChannel;

  /// sent | pending | failed | null.
  final String? deliveryStatus;
  final bool aiDrafted;

  /// Học sinh ngoài nền tảng có SĐT phụ huynh (backend vẫn ghi kênh ZNS khi
  /// chưa có số, nhưng tin không gửi được).
  final bool hasParentPhone;
}

String _dm(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

/// Tiêu đề + câu báo của bước 3/3 theo kênh và trạng thái gửi.
({String title, String text}) reportSentCopy(ReportSentArgs a) {
  final who = a.studentName.isEmpty ? 'học sinh' : a.studentName;
  if (a.deliveryChannel == 'booking' || !a.offPlatform) {
    return (title: 'Đã gửi', text: 'Phụ huynh $who xem báo cáo trên TopTutor.');
  }
  if (a.deliveryChannel != 'zns' || !a.hasParentPhone) {
    return (
      title: 'Đã duyệt',
      text: 'Báo cáo đã lưu. Thêm SĐT phụ huynh để gửi qua Zalo.',
    );
  }
  if (a.deliveryStatus == 'sent') {
    return (title: 'Đã gửi', text: 'Phụ huynh $who đã nhận báo cáo qua Zalo.');
  }
  if (a.deliveryStatus == 'failed') {
    return (
      title: 'Đã duyệt',
      text: 'Báo cáo đã lưu nhưng chưa gửi Zalo được. Hệ thống sẽ thử lại.',
    );
  }
  final morning = zaloQuietMorning(a.approvedAtUtc);
  if (morning != null) {
    return (
      title: 'Đã lên lịch gửi',
      text: 'Phụ huynh $who nhận báo cáo qua Zalo lúc 06:30 $morning.',
    );
  }
  return (
    title: 'Đang gửi',
    text: 'Tin Zalo cho phụ huynh $who đang chờ gửi.',
  );
}

class _Top extends StatelessWidget {
  const _Top({required this.step});

  final String step;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      // Báo cáo đã gửi: quay lại là về trang trước luồng duyệt.
      CanvasBackButton(
        onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
      ),
      const Spacer(),
      Text(step, style: TutorType.rowSub()),
    ],
  );
}

class _Frame extends StatelessWidget {
  const _Frame({required this.children, required this.bottom});

  final List<Widget> children;
  final Widget bottom;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: TutorColors.bg,
    body: DecoratedBox(
      decoration: TutorSurface.paper,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  TutorSurface.gutter,
                  16,
                  TutorSurface.gutter,
                  24,
                ),
                children: children,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                TutorSurface.gutter,
                10,
                TutorSurface.gutter,
                16,
              ),
              child: bottom,
            ),
          ],
        ),
      ),
    ),
  );
}

/// Bước 2/3 "Nhận xét buổi dạy" (V56-Feedback): T13 "Dành cho bạn" (tự ẩn
/// khi cờ Topi `tips` tắt) và chất lượng bản ghi; chỉ gia sư thấy.
class ReportFeedbackScreen extends StatelessWidget {
  const ReportFeedbackScreen({required this.args, super.key});

  final ReportSentArgs args;

  @override
  Widget build(BuildContext context) {
    final day = args.lessonDay;
    return _Frame(
      bottom: CanvasCta(
        label: 'Tiếp tục',
        onPressed: () => Navigator.of(context).pushReplacement<void, void>(
          MaterialPageRoute(builder: (_) => ReportSentScreen(args: args)),
        ),
      ),
      children: [
        const _Top(step: 'Bước 2/3'),
        const SizedBox(height: 16),
        Text(
          [
            'Dành cho bạn',
            if (day != null) 'buổi ${_dm(day)}',
            if (args.studentName.isNotEmpty) args.studentName,
          ].join(' · '),
          style: TutorType.caption(color: TutorColors.ink3),
        ),
        const SizedBox(height: 4),
        Text('Nhận xét buổi dạy', style: TutorType.display(size: 26)),
        TopiTipsCard(lessonId: args.lessonId),
        LessonInsightsCard(
          lessonId: args.lessonId,
          kicker: 'Buổi học qua bản ghi · chỉ bạn thấy',
          padding: const EdgeInsets.only(top: 20),
        ),
        const SizedBox(height: 18),
        Text(
          'Chất lượng buổi dạy hiện sau khi thẩm định',
          style: TutorType.caption(color: TutorColors.ink3),
        ),
      ],
    );
  }
}

/// Bước 3/3 "Đã lên lịch gửi" / "Đã gửi" (V56-Sent): giờ phụ huynh nhận, thẻ
/// báo cáo đã duyệt, tiến bộ kỹ năng (Topi, tự ẩn khi cờ `skills` tắt).
class ReportSentScreen extends StatelessWidget {
  const ReportSentScreen({required this.args, super.key});

  final ReportSentArgs args;

  @override
  Widget build(BuildContext context) {
    final copy = reportSentCopy(args);
    final day = args.lessonDay;
    final channel = switch (args.deliveryChannel) {
      'zns' => 'Zalo',
      'booking' => 'TopTutor',
      _ => args.offPlatform ? 'Chưa gửi' : 'TopTutor',
    };
    final shownChannel = args.offPlatform && !args.hasParentPhone
        ? 'Chưa gửi'
        : channel;
    final rows = <(String, String)>[
      (
        day == null ? 'Báo cáo buổi học' : 'Báo cáo buổi ${_dm(day)}',
        'Đã duyệt',
      ),
      ('Kênh', shownChannel),
      ('Ghi chú', args.aiDrafted ? 'AI soạn, bạn đã duyệt' : 'Bạn tự viết'),
    ];
    return _Frame(
      bottom: CanvasCta(
        label: 'Về trang chủ',
        onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
      ),
      children: [
        const _Top(step: 'Bước 3/3'),
        const SizedBox(height: 22),
        Text(copy.title, style: TutorType.display(size: 32, height: 1.05)),
        const SizedBox(height: 8),
        Text(copy.text, style: TutorType.body()),
        const SizedBox(height: 22),
        DecoratedBox(
          decoration: TutorSurface.card(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: i == 0
                        ? null
                        : const BoxDecoration(
                            border: Border(
                              top: BorderSide(color: TutorColors.line),
                            ),
                          ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            rows[i].$1,
                            style: i == 0
                                ? TutorType.rowTitle()
                                : TutorType.rowSub(),
                          ),
                        ),
                        if (i == 0)
                          CanvasTag(rows[i].$2)
                        else
                          Text(rows[i].$2, style: TutorType.rowTitle()),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        TopiSkillsSection(
          lessonId: args.lessonId,
          title: args.studentName.isEmpty
              ? 'Tiến bộ của học sinh'
              : 'Tiến bộ của ${args.studentName}',
          padding: const EdgeInsets.only(top: 24),
        ),
      ],
    );
  }
}
