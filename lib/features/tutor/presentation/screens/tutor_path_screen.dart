import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/core/theme/tutor_design.dart';
import 'package:tutora/features/tutor/data/models/recorder_models.dart';
import 'package:tutora/features/tutor/presentation/providers/recorder_provider.dart';
import 'package:tutora/features/tutor/presentation/providers/tutor_profile_provider.dart';
import 'package:tutora/features/tutor/presentation/widgets/canvas_ui.dart';

/// T3 · Lộ trình gia sư (design canvas 11/2026): ba chặng tới chuẩn TopTutor.
///
/// Chặng 1 (Được liệt kê) tính từ dữ liệu thật: buổi ghi âm 7 ngày qua và phụ
/// huynh đã đồng ý ghi âm. Chặng 2 (10 hành vi dạy) và chặng 3 (kết quả học
/// sinh giữ được) chờ kiểm chứng — chưa có số liệu nên ghi rõ "sau khi kiểm
/// chứng", không đặt gia sư vào chặng nào. Ngưỡng của từng chặng chờ Michael.
class TutorPathScreen extends ConsumerWidget {
  const TutorPathScreen({super.key});

  static const _recorded = {
    'processing',
    'awaiting_approval',
    'failed',
    'sent',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(tutorProfileProvider).user?.fullName ?? '';
    final students =
        ref.watch(recorderStudentsProvider).valueOrNull ??
        const <RecorderStudentDto>[];
    final lessons =
        ref.watch(recorderAllLessonsProvider).valueOrNull ??
        const <RecorderLessonDto>[];

    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final lastWeek = lessons.where((l) {
      final w = l.when;
      return w != null &&
          w.isAfter(weekAgo) &&
          w.isBefore(now) &&
          l.status != 'discarded';
    }).toList();
    final recorded = lastWeek.where((l) => _recorded.contains(l.status)).length;
    final consented = students.where((s) => s.hasConsent).length;
    final stage1Done =
        students.isNotEmpty && consented == students.length && recorded > 0;

    return Scaffold(
      backgroundColor: TutorColors.bg,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: TutorColors.ink2,
          onRefresh: () async {
            ref
              ..invalidate(recorderStudentsProvider)
              ..invalidate(recorderAllLessonsProvider);
          },
          child: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              CanvasHeader(
                left: name.isEmpty ? 'Gia sư' : 'Gia sư $name',
                right: _today(now),
                title: 'Lộ trình của bạn',
                titleSize: 44,
                lead:
                    'Ba chặng tới chuẩn TopTutor. Mỗi chặng cho biết cần gì, bạn đang ở đâu và bước tiếp theo.',
              ),
              const SizedBox(height: 24),
              Padding(
                padding: TutorSurface.screenPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Stage(
                      number: 1,
                      title: 'Được liệt kê',
                      status: stage1Done ? '✓ Đã xong' : 'Đang làm',
                      statusColor: stage1Done
                          ? TutorColors.success
                          : TutorColors.warning,
                      body:
                          'Buổi nào cũng ghi âm và dùng được; phụ huynh nào cũng đồng ý ghi âm. Đây là nền: chặng này không cộng điểm.',
                      facts: [
                        (
                          'Buổi đã ghi âm · 7 ngày qua',
                          lastWeek.isEmpty
                              ? 'chưa có buổi'
                              : '$recorded / ${lastWeek.length}',
                        ),
                        (
                          'Phụ huynh đồng ý ghi âm',
                          '$consented / ${students.length} học sinh',
                        ),
                      ],
                    ),
                    const _Stage(
                      number: 2,
                      title: 'Đạt chuẩn',
                      status: 'Sắp có',
                      body:
                          'Phần lớn 10 hành vi dạy học đạt, tính trên 10 buổi gần nhất của bạn.',
                      facts: [('Kết quả của bạn', 'sau khi kiểm chứng')],
                    ),
                    const _Stage(
                      number: 3,
                      title: 'Kết quả đã chứng minh',
                      status: 'Sắp có',
                      body:
                          'Kỹ năng toán của học sinh lên mức và giữ được: có sao mỗi tháng, có kỹ năng đạt mức thành thạo.',
                      facts: [
                        (
                          'Kỹ năng thành thạo · tháng này',
                          'sau khi kiểm chứng',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const CanvasExpander(
                      title: '10 hành vi dạy học',
                      lastRule: true,
                      children: [
                        Text('1. Học sinh được nói'),
                        Text('2. Học sinh thử trước'),
                        Text('3. Gia sư chờ'),
                        Text('4. Gia sư hỏi, không giảng thay'),
                        Text('5. Học sinh nói ra mình đang làm gì'),
                        Text('6. Lỗi được tìm ra, không giải lại thay'),
                        Text('7. Bài về nhà được kiểm tra'),
                        Text('8. Buổi học kết thúc bằng tóm tắt'),
                        Text('9. Khen việc làm, không khen con người'),
                        Text('10. Học sinh được tập thói quen học'),
                        Text(
                          'Chỉ so với chính các buổi trước của bạn, không so với gia sư khác.',
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Học phí luôn do bạn tự đặt.',
                      style: TutorType.rowSub().copyWith(fontSize: 14),
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

  static String _today(DateTime d) {
    const wd = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    return '${wd[d.weekday - 1]} ${d.day}/${d.month}';
  }
}

class _Stage extends StatelessWidget {
  const _Stage({
    required this.number,
    required this.title,
    required this.status,
    required this.body,
    required this.facts,
    this.statusColor = TutorColors.ink3,
  });

  final int number;
  final String title;
  final String status;
  final Color statusColor;
  final String body;
  final List<(String, String)> facts;
  @override
  Widget build(BuildContext context) {
    return CanvasRow(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 44,
            child: Text(
              '$number',
              style: TutorType.display(
                size: 44,
                weight: FontWeight.w300,
                color: TutorColors.ink,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TutorType.display(
                          size: 22,
                          weight: FontWeight.w700,
                          color: TutorColors.ink,
                          height: 1.2,
                        ).copyWith(letterSpacing: -0.5),
                      ),
                    ),
                    CanvasKicker(status, color: statusColor),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TutorType.rowSub().copyWith(
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 6),
                for (final (k, v) in facts)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: TutorColors.line)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            k,
                            style: TutorType.rowSub().copyWith(fontSize: 14),
                          ),
                        ),
                        Text(
                          v,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: TutorColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
