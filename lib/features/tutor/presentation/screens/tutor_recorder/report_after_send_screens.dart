import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/core/theme/tutor_design.dart';
import 'package:tutora/features/tutor/data/models/recorder_insights_models.dart';
import 'package:tutora/features/tutor/data/models/topi_models.dart';
import 'package:tutora/features/tutor/presentation/providers/recorder_insights_provider.dart';
import 'package:tutora/features/tutor/presentation/providers/topi_provider.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_recorder/topi_before_lesson_screen.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_recorder/tutor_recording_detail_screen.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_recorder/tutor_report_review_screen.dart';
import 'package:tutora/features/tutor/presentation/widgets/canvas_ui.dart';

/// Kết quả "Trượt để gửi phụ huynh" — dữ liệu cho màn "Đã gửi" (V57-Done).
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

/// "9/11": ngày/tháng không thêm số 0, giống trang chủ (U4, thử persona 2026-11-20).
String _dm(DateTime d) => '${d.day}/${d.month}';

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

/// Số liệu ô "Buổi này" (V57-Done). null = chưa có dữ liệu, không hiện ô đó.
class ReportDoneStats {
  const ReportDoneStats({
    this.minutesRecorded,
    this.minutesPlanned,
    this.newGaps,
    this.improvedGaps,
    this.stars = 0,
    this.newSkills = 0,
    this.newSkillsCanDo = 0,
  });

  /// Từ chỉ số bản ghi (insights) và kết quả Topi của buổi.
  factory ReportDoneStats.from(LessonInsightsDto? insights, LessonTopi? topi) {
    final ok = insights != null && insights.available;
    final gaps = topi?.plan?.gaps;
    final changes = topi?.skills?.proposedChanges;
    final first = (topi?.skills?.firstSeen ?? const <TopiFirstSeen>[])
        .where((f) => f.level != null)
        .toList();
    return ReportDoneStats(
      // Kỹ năng Topi gặp lần đầu ở buổi này, và bao nhiêu trong số đó học
      // sinh đã làm được (từ mức Tiến bộ trở lên).
      newSkills: first.length,
      newSkillsCanDo: first
          .where((f) => f.level!.index >= TopiLevel.improving.index)
          .length,
      minutesRecorded: ok ? insights.minutesRecorded : null,
      minutesPlanned: ok ? insights.minutesPlanned : null,
      // Lỗ hổng mới: lần đầu gặp ở buổi này.
      newGaps: gaps?.where((g) => (g.seenInLessons ?? 1) <= 1).length,
      // Lỗ hổng tiến bộ: kỹ năng lên mức so với trước buổi.
      improvedGaps: changes
          ?.where(
            (c) =>
                c.from != null && c.to != null && c.to!.index > c.from!.index,
          )
          .length,
      stars: changes?.where((c) => c.star).length ?? 0,
    );
  }

  final int? minutesRecorded;
  final int? minutesPlanned;
  final int? newGaps;
  final int? improvedGaps;
  final int stars;
  final int newSkills;
  final int newSkillsCanDo;

  /// Buổi mở chương mới: không kỹ năng nào lên mức vì kỹ năng nào cũng mới gặp,
  /// nhưng học sinh đã làm được một phần. Khi đó ô đứng đầu là số kỹ năng mới
  /// thay cho "0 kỹ năng lên mức" (buổi 28/10: 8/11 bài tự làm đúng mà ô ghi 0).
  bool get leadWithNewSkills => (improvedGaps ?? 0) == 0 && newSkillsCanDo > 0;

  bool get isEmpty =>
      minutesRecorded == null &&
      newGaps == null &&
      improvedGaps == null &&
      newSkills == 0;
}

/// "31:05" từ số giây.
String reportClock(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

/// Chữ lớn hơn một bậc trên màn này (Michael 13/11: chữ quá nhỏ).
TextStyle _big() => TutorType.body().copyWith(fontSize: 16.5);
TextStyle _sub() => TutorType.rowSub().copyWith(fontSize: 14.5);

/// Màn duy nhất sau "Trượt để gửi" (V57-Done, góp ý Michael 13/11): đã gửi →
/// ô "Buổi này" (phút ghi âm, lỗ hổng mới / tiến bộ, sao) → hôm nay bạn dạy
/// thế nào (kèm phút) → lần sau thử + kế hoạch buổi sau → chi tiết ở cuối.
/// Điểm và sao chỉ hiện sau khi gửi. Phần Topi tự ẩn khi chưa có kết quả.
class ReportDoneScreen extends ConsumerWidget {
  const ReportDoneScreen({required this.args, super.key});

  final ReportSentArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final copy = reportSentCopy(args);
    final insights = ref
        .watch(lessonInsightsProvider(args.lessonId))
        .valueOrNull;
    return _Frame(
      bottom: CanvasCta(
        label: 'Về trang chủ',
        onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
      ),
      children: [
        Row(
          children: [
            CanvasBackButton(
              onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
            ),
            const Spacer(),
            Text(
              [
                if (args.lessonDay != null) 'Buổi ${_dm(args.lessonDay!)}',
                if (args.studentName.isNotEmpty) args.studentName,
              ].join(' · '),
              style: _sub(),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: TutorColors.ink,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(copy.title, style: TutorType.display(size: 26)),
                  const SizedBox(height: 2),
                  Text(copy.text, style: _sub()),
                ],
              ),
            ),
          ],
        ),
        LessonFeedbackSections(
          lessonId: args.lessonId,
          studentName: args.studentName,
        ),
        const SizedBox(height: 28),
        Text('Chi tiết', style: TutorType.caption(color: TutorColors.ink3)),
        const SizedBox(height: 4),
        _DetailRow(
          title: 'Bài đã làm và kỹ năng',
          onTap: () => _openDetail(context),
        ),
        _DetailRow(
          title: insights?.bothVoices ?? false
              ? 'Ghi âm · nghe rõ cả hai giọng'
              : 'Ghi âm',
          trailing: insights?.studentTalkShare == null
              ? null
              : '${args.studentName.isEmpty ? 'Học sinh' : args.studentName} '
                    'nói ${(insights!.studentTalkShare! * 100).round()}%',
          onTap: () => _openDetail(context),
        ),
      ],
    );
  }

  void _openDetail(BuildContext context) => TutorRecordingDetailScreen.open(
    context,
    RecordingDetailArgs(
      recordingId: args.lessonId,
      studentName: args.studentName,
    ),
  );
}

/// Nhận xét một buổi (V57-Done, Michael 13/11): ô "Buổi này", "Hôm nay bạn
/// dạy thế nào" (kèm phút), "Lần sau thử" + kế hoạch buổi sau. Dùng ở màn
/// "Đã gửi" và tab "Nhận xét" của chi tiết buổi. Phần Topi tự ẩn khi chưa có.
class LessonFeedbackSections extends ConsumerWidget {
  const LessonFeedbackSections({
    required this.lessonId,
    required this.studentName,
    super.key,
  });

  final String lessonId;
  final String studentName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flags = ref.watch(topiFlagsNowProvider);
    final insights = ref.watch(lessonInsightsProvider(lessonId)).valueOrNull;
    final topi = flags.any
        ? ref.watch(lessonTopiProvider(lessonId)).valueOrNull
        : null;
    final stats = ReportDoneStats.from(insights, topi);
    final tips = flags.tips ? topi?.tips : null;
    final plan = flags.plan ? topi?.plan : null;
    TopiGap? focus;
    for (final g in plan?.gaps ?? const <TopiGap>[]) {
      if (g.role == 'focus') focus ??= g;
    }
    focus ??= plan?.gaps.firstOrNull;

    final today = <(String?, String)>[
      if (tips?.didWell != null)
        (_clock(tips!.didWell!.ts), 'Làm tốt: ${tips.didWell!.text}'),
      if (tips?.talkMore != null)
        (_clock(tips!.talkMore!.ts), tips.talkMore!.text),
      for (final q in insights?.studentQuietStretches ?? const <QuietStretch>[])
        (
          '${q.fromMin}–${q.toMin}',
          '${studentName.isEmpty ? 'Học sinh' : studentName} '
              'gần như không nói trong ${q.toMin - q.fromMin} phút.',
        ),
    ];

    if (stats.isEmpty &&
        today.isEmpty &&
        tips?.tryNext == null &&
        focus == null) {
      return Padding(
        padding: const EdgeInsets.only(top: 22),
        child: Text(
          'Buổi này chưa có nhận xét. Nhận xét có sau khi AI đọc xong bản ghi.',
          style: _sub(),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!stats.isEmpty) ...[
          const SizedBox(height: 22),
          _StatsBox(stats: stats),
        ],
        if (today.isNotEmpty) ...[
          const SizedBox(height: 26),
          Text('Hôm nay bạn dạy thế nào', style: TutorType.sectionTitle()),
          const SizedBox(height: 4),
          for (var i = 0; i < today.length; i++)
            _Moment(clock: today[i].$1, text: today[i].$2, first: i == 0),
        ],
        if (tips?.tryNext != null || focus != null) ...[
          const SizedBox(height: 20),
          DecoratedBox(
            decoration: TutorSurface.sage(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Expanded(
                        child: CanvasKicker(
                          'Lần sau thử',
                          color: TutorColors.ink,
                        ),
                      ),
                      CanvasAiDraftTag(onSage: true),
                    ],
                  ),
                  if (tips?.tryNext != null) ...[
                    const SizedBox(height: 8),
                    Text(tips!.tryNext!.text, style: _big()),
                  ],
                  if (focus?.title != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Luyện ngay: ${focus!.title}'
                      '${(focus.seenInLessons ?? 0) > 1 ? ' (gặp ${focus.seenInLessons} buổi)' : ''}.',
                      style: _big(),
                    ),
                  ],
                  if (plan != null && !plan.isEmpty)
                    CanvasRow(
                      onTap: () => TopiBeforeLessonScreen.open(
                        context,
                        BeforeLessonArgs(
                          lessonId: lessonId,
                          studentName: studentName,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Kế hoạch đầu buổi sau',
                              style: _big(),
                            ),
                          ),
                          const CanvasChevron(),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  static String? _clock(int? ts) => ts == null ? null : reportClock(ts);
}

/// Ô "Kết quả buổi này" (A3, Michael 16/11: "thành công ở đâu?"): số kỹ năng
/// lên mức đứng đầu, chữ lớn; kỹ năng mới phát hiện và thời lượng ghi âm là
/// hai dòng nhỏ bên dưới.
class _StatsBox extends StatelessWidget {
  const _StatsBox({required this.stats});

  final ReportDoneStats stats;

  @override
  Widget build(BuildContext context) {
    final improved = stats.improvedGaps;
    final minutes = stats.minutesRecorded;
    final rows = <(String, String)>[
      if (stats.newGaps != null)
        ('Mới phát hiện', '${stats.newGaps} kỹ năng cần luyện tập'),
      if (minutes != null)
        (
          'Thời lượng ghi âm',
          stats.minutesPlanned == null
              ? '$minutes phút'
              : '$minutes phút · lịch ${stats.minutesPlanned} phút',
        ),
    ];
    return DecoratedBox(
      decoration: TutorSurface.card(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: CanvasKicker(
                    'Kết quả buổi này',
                    color: TutorColors.ink,
                  ),
                ),
                if (stats.stars > 0)
                  Text(
                    '${List.filled(stats.stars, '★').join(' ')}  +${stats.stars} sao',
                    style: _sub().copyWith(color: TutorColors.ink),
                  ),
              ],
            ),
            if (stats.leadWithNewSkills) ...[
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${stats.newSkills}',
                    style: TutorType.display(size: 40),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('kỹ năng mới học', style: _big()),
                          const SizedBox(height: 2),
                          Text(
                            '${stats.newSkillsCanDo == stats.newSkills ? 'Cả ${stats.newSkills}' : '${stats.newSkillsCanDo}'} '
                            'kỹ năng bé đã làm được. Lên mức ở buổi sau = '
                            '1 sao cho bé và cho bạn.',
                            style: _sub(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (improved != null) ...[
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$improved', style: TutorType.display(size: 40)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('kỹ năng lên mức', style: _big()),
                          const SizedBox(height: 2),
                          Text(
                            improved == 0
                                ? 'Chưa ghi nhận tiến bộ trong buổi này. '
                                      'Mỗi kỹ năng lên mức = 1 sao cho bé và '
                                      'cho bạn.'
                                : 'Mỗi kỹ năng lên mức = 1 sao cho bé và '
                                      'cho bạn.',
                            style: _sub(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            for (final r in rows)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: TutorColors.line)),
                ),
                child: Row(
                  children: [
                    Text(r.$1, style: _sub()),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        r.$2,
                        textAlign: TextAlign.end,
                        style: _sub().copyWith(color: TutorColors.ink),
                      ),
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

/// Một khoảnh khắc trong buổi: nhãn phút (nếu có) + câu nhận xét.
class _Moment extends StatelessWidget {
  const _Moment({required this.clock, required this.text, required this.first});

  final String? clock;
  final String text;
  final bool first;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: first
        ? null
        : const BoxDecoration(
            border: Border(top: BorderSide(color: TutorColors.line)),
          ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (clock != null) ...[
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFEAEAE4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              clock!,
              style: TutorType.caption(color: TutorColors.ink),
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(child: Text(text, style: _big())),
      ],
    ),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.title, required this.onTap, this.trailing});

  final String title;
  final String? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => CanvasRow(
    onTap: onTap,
    child: Row(
      children: [
        Expanded(child: Text(title, style: _big())),
        if (trailing != null) ...[
          Text(trailing!, style: _sub()),
          const SizedBox(width: 6),
        ],
        const CanvasChevron(),
      ],
    ),
  );
}
