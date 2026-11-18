import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/core/router/app_routes.dart';
import 'package:tutora/core/theme/tutor_design.dart';
import 'package:tutora/features/tutor/data/models/recorder_insights_models.dart';
import 'package:tutora/features/tutor/data/models/recorder_models.dart';
import 'package:tutora/features/tutor/presentation/providers/recorder_insights_provider.dart';
import 'package:tutora/features/tutor/presentation/providers/recorder_provider.dart';
import 'package:tutora/features/tutor/presentation/providers/tutor_profile_provider.dart';
import 'package:tutora/features/tutor/presentation/widgets/canvas_ui.dart';

/// T3 · Lộ trình gia sư (design V5.6, board V56-Path): ba chặng tới chuẩn
/// TopTutor trên một đường thời gian dọc.
///
/// Chặng 1 tính từ dữ liệu thật: "ghi âm tốt" tuần trước (API tuần; lỗi thì
/// buổi đã ghi 7 ngày qua) và phụ huynh đã đồng ý ghi âm; hàng ghi âm mở danh
/// sách bản ghi (không còn là tab). Chặng 2 hiện "học sinh nói trung bình" của
/// tuần này khi server có số; 10 hành vi dạy và chặng 3 (kết quả học sinh giữ
/// được) chờ kiểm chứng — ghi rõ "sau khi kiểm chứng"; board có "6/10 hành vi"
/// và ô "Đang luyện" nhưng chưa có dữ liệu nên không vẽ.
class TutorPathScreen extends ConsumerWidget {
  const TutorPathScreen({super.key});

  static const _recorded = {
    'processing',
    'awaiting_approval',
    'failed',
    'sent',
  };

  static const _stage2Body =
      'Đạt phần lớn 10 hành vi dạy tốt, trong 10 buổi gần nhất.';

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

    // "Ghi âm tốt" theo tuần (API B, mới nhất trước). Tuần trước = weeks[1];
    // chỉ có một tuần thì dùng tuần đó. Chưa có / lỗi → đếm như cũ.
    final weeks =
        ref.watch(weeklyRecordingProvider).valueOrNull?.weeks ??
        const <WeeklyRecordingWeek>[];
    final scoreWeek = weeks.length > 1
        ? weeks[1]
        : (weeks.isEmpty ? null : weeks.first);
    final talkShare = weeks.isEmpty ? null : weeks.first.avgStudentTalkShare;
    void openRecordings() => unawaited(context.push(AppRoutes.tutorRecordings));

    final stage1Facts = [
      if (scoreWeek != null)
        _Fact(
          label: weeks.length > 1
              ? 'Ghi âm tốt · tuần trước'
              : 'Ghi âm tốt · tuần này',
          value: scoreWeek.lessonsDue == 0
              ? 'chưa có buổi'
              : '${scoreWeek.usable}/${scoreWeek.lessonsDue}',
          onTap: openRecordings,
        )
      else
        _Fact(
          label: 'Buổi đã ghi âm · 7 ngày qua',
          value: lastWeek.isEmpty
              ? 'chưa có buổi'
              : '$recorded/${lastWeek.length}',
          onTap: openRecordings,
        ),
      _Fact(
        label: 'Phụ huynh đồng ý',
        value: '$consented/${students.length} học sinh',
      ),
    ];
    final stage2Facts = [
      // Số đo thật từ bản ghi tuần này; null thì không hiện.
      if (talkShare != null)
        _Fact(
          label: 'Học sinh nói trung bình · tuần này',
          value: '${(talkShare.clamp(0, 1) * 100).round()}%',
        ),
      const _Fact(label: 'Kết quả của bạn', value: 'sau khi kiểm chứng'),
    ];

    return Scaffold(
      backgroundColor: TutorColors.bg,
      body: DecoratedBox(
        decoration: TutorSurface.paper,
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: TutorColors.primary,
            onRefresh: () async {
              ref
                ..invalidate(recorderStudentsProvider)
                ..invalidate(recorderAllLessonsProvider)
                ..invalidate(weeklyRecordingProvider);
            },
            child: ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    TutorSurface.gutter,
                    22,
                    TutorSurface.gutter,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lộ trình của bạn',
                        style: TutorType.display(size: 24),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          if (name.isNotEmpty) 'Gia sư $name',
                          'Ba chặng đến chuẩn TopTutor.',
                        ].join(' · '),
                        style: TutorType.rowSub(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: TutorSurface.screenPadding,
                  child: Stack(
                    children: [
                      // Đường thời gian dọc nối ba chặng.
                      const Positioned(
                        left: 11.5,
                        top: 30,
                        bottom: 60,
                        child: SizedBox(
                          width: 1,
                          child: ColoredBox(color: Color(0x241F2A24)),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Chặng 1 — Đã đăng ký.
                          _StageRow(
                            marker: stage1Done
                                ? const _DoneMarker()
                                : const _StepMarker(1),
                            child: stage1Done
                                ? _FlatStage(
                                    title: '1 · Đã đăng ký',
                                    titleColor: const Color(0xFF7E847E),
                                    status: 'Xong',
                                    facts: stage1Facts,
                                  )
                                : _SageStage(
                                    title: 'Đã đăng ký',
                                    body:
                                        'Buổi nào cũng ghi âm và dùng được; phụ huynh nào cũng đồng ý ghi âm. Đây là nền: chặng này không cộng điểm.',
                                    facts: stage1Facts,
                                  ),
                          ),
                          // Chặng 2 — Đạt chuẩn.
                          _StageRow(
                            marker: _StepMarker(2, off: !stage1Done),
                            child: stage1Done
                                ? _SageStage(
                                    title: 'Đạt chuẩn',
                                    body: _stage2Body,
                                    facts: stage2Facts,
                                  )
                                : _FlatStage(
                                    title: 'Đạt chuẩn',
                                    status: 'Tiếp theo',
                                    body: _stage2Body,
                                    facts: stage2Facts,
                                  ),
                          ),
                          // Chặng 3 — Có kết quả.
                          _StageRow(
                            last: true,
                            marker: const _StepMarker(3, off: true),
                            child: _FlatStage(
                              title: 'Có kết quả',
                              status: stage1Done ? 'Tiếp theo' : 'Sắp có',
                              body:
                                  'Kỹ năng của học sinh tăng và giữ được: có sao mỗi tháng.',
                              facts: [
                                _Fact(
                                  label: 'Kỹ năng đã vững · tháng ${now.month}',
                                  value: 'sau khi kiểm chứng',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Padding(
                  padding: TutorSurface.screenPadding,
                  child: CanvasExpander(
                    title: '10 hành vi dạy tốt',
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
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    TutorSurface.gutter,
                    14,
                    TutorSurface.gutter,
                    0,
                  ),
                  child: Text(
                    'Học phí luôn do bạn tự đặt.',
                    style: TutorType.rowSub(),
                  ),
                ),
                const SizedBox(height: 28),
                const Padding(
                  padding: EdgeInsets.only(right: 28),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: CanvasHand('Chỉ so với chính bạn', size: 17),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Một chặng: ô đánh dấu bên trái (trên đường thời gian), nội dung bên phải.
class _StageRow extends StatelessWidget {
  const _StageRow({
    required this.marker,
    required this.child,
    this.last = false,
  });

  final Widget marker;
  final Widget child;
  final bool last;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: last ? 0 : 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 24, child: Center(child: marker)),
        const SizedBox(width: 14),
        Expanded(child: child),
      ],
    ),
  );
}

/// Vòng tròn đặc có dấu ✓ (chặng đã xong).
class _DoneMarker extends StatelessWidget {
  const _DoneMarker();

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Đã xong',
    child: Container(
      width: 20,
      height: 20,
      margin: const EdgeInsets.only(top: 1),
      decoration: const BoxDecoration(
        color: TutorColors.ink,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.check_rounded, size: 13, color: Colors.white),
    ),
  );
}

/// Số chặng trong vòng tròn 24: đặc (đang làm) hoặc viền (chưa tới).
class _StepMarker extends StatelessWidget {
  const _StepMarker(this.number, {this.off = false});

  final int number;
  final bool off;

  @override
  Widget build(BuildContext context) => Container(
    width: 24,
    height: 24,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: off ? const Color(0xFFEFEEE8) : TutorColors.ink,
      border: off
          ? Border.all(color: const Color(0xFFA3A8A2), width: 1.4)
          : null,
    ),
    child: Text(
      '$number',
      style: TutorType.caption(
        color: off ? TutorColors.ink : Colors.white,
      ).copyWith(height: 1),
    ),
  );
}

/// Chặng phẳng trên nền giấy (đã xong / chưa tới).
class _FlatStage extends StatelessWidget {
  const _FlatStage({
    required this.title,
    required this.status,
    required this.facts,
    this.body,
    this.titleColor = TutorColors.ink,
  });

  final String title;
  final Color titleColor;
  final String status;
  final String? body;
  final List<_Fact> facts;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(title, style: TutorType.body(color: titleColor)),
          ),
          Text(status, style: TutorType.caption(color: TutorColors.ink3)),
        ],
      ),
      if (body != null) ...[
        const SizedBox(height: 4),
        Text(body!, style: TutorType.rowSub()),
      ],
      ...facts,
    ],
  );
}

/// Chặng "bạn ở đây": thẻ sage nổi.
class _SageStage extends StatelessWidget {
  const _SageStage({
    required this.title,
    required this.body,
    required this.facts,
  });

  final String title;
  final String body;
  final List<_Fact> facts;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: TutorSurface.sage(),
    child: Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: TutorType.body())),
                const CanvasTag('Bạn ở đây', filled: true),
              ],
            ),
            const SizedBox(height: 6),
            Text(body, style: TutorType.rowSub()),
            const SizedBox(height: 4),
            ...facts,
          ],
        ),
      ),
    ),
  );
}

/// Hàng "nhãn ........ giá trị" không kẻ; có [onTap] thì thêm "›" và bấm được.
class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value, this.onTap});

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TutorType.rowSub().copyWith(fontSize: 13.5),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            onTap == null ? value : '$value ›',
            style: TutorType.rowSub(
              color: TutorColors.ink,
            ).copyWith(fontSize: 13.5),
          ),
        ],
      ),
    );
    if (onTap == null) return row;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Align(alignment: Alignment.centerLeft, child: row),
      ),
    );
  }
}
