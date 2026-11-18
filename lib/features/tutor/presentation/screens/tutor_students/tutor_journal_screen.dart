import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/core/theme/tutor_design.dart';
import 'package:tutora/features/tutor/data/models/recorder_insights_models.dart';
import 'package:tutora/features/tutor/presentation/providers/recorder_insights_provider.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_recorder/tutor_recording_detail_screen.dart';
import 'package:tutora/features/tutor/presentation/widgets/canvas_ui.dart';

/// Nhật ký học tập của một học sinh theo tháng (canvas V5.6 Journal): buổi mới
/// nhất là thẻ đủ mục (Nội dung, Bài cũ, Bài về nhà, Ý thức, Nhận xét), các
/// buổi trước là hàng kẻ mảnh mở chi tiết buổi. Mọi mục tự điền từ bản ghi âm
/// (`GET /recorder/students/{id}/journal?month=`).
class TutorJournalScreen extends ConsumerStatefulWidget {
  const TutorJournalScreen({
    required this.studentId,
    required this.studentName,
    this.initialMonth,
    super.key,
  });

  final String studentId;
  final String studentName;

  /// Tháng mở đầu tiên (mặc định tháng hiện tại).
  final DateTime? initialMonth;

  static Future<void> open(
    BuildContext context,
    String studentId,
    String studentName,
  ) => Navigator.of(context, rootNavigator: true).push<void>(
    MaterialPageRoute(
      builder: (_) =>
          TutorJournalScreen(studentId: studentId, studentName: studentName),
    ),
  );

  @override
  ConsumerState<TutorJournalScreen> createState() => _TutorJournalScreenState();
}

class _TutorJournalScreenState extends ConsumerState<TutorJournalScreen> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final m = widget.initialMonth ?? DateTime.now();
    _month = DateTime(m.year, m.month);
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _month.year == now.year && _month.month == now.month;
  }

  void _shift(int delta) =>
      setState(() => _month = DateTime(_month.year, _month.month + delta));

  String get _monthLabel {
    final now = DateTime.now();
    return _month.year == now.year
        ? 'Tháng ${_month.month}'
        : 'Tháng ${_month.month}/${_month.year}';
  }

  @override
  Widget build(BuildContext context) {
    final key = (
      studentId: widget.studentId,
      month: formatJournalMonth(_month),
    );
    final journal = ref.watch(studentJournalProvider(key));

    return Scaffold(
      backgroundColor: TutorColors.bg,
      body: DecoratedBox(
        decoration: TutorSurface.paper,
        child: SafeArea(
          child: RefreshIndicator(
            color: TutorColors.ink2,
            onRefresh: () async {
              ref.invalidate(studentJournalProvider(key));
              try {
                await ref.read(studentJournalProvider(key).future);
              } on Object {
                // Lỗi hiện trong danh sách (nhánh error).
              }
            },
            child: ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                _Top(
                  label: '${widget.studentName} · $_monthLabel',
                  onBack: () => Navigator.of(context).maybePop(),
                  onPrev: () => _shift(-1),
                  onNext: _isCurrentMonth ? null : () => _shift(1),
                ),
                ...journal.when<List<Widget>>(
                  loading: () => [
                    const _Title(sub: null),
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ],
                  error: (_, _) => [
                    const _Title(sub: null),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        TutorSurface.gutter,
                        24,
                        TutorSurface.gutter,
                        0,
                      ),
                      child: Text(
                        'Không tải được nhật ký. Kéo xuống để thử lại.',
                        style: TutorType.rowSub(),
                      ),
                    ),
                  ],
                  data: (dto) => _content(context, dto),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _content(BuildContext context, StudentJournalDto dto) {
    final now = DateTime.now();
    // Buổi đã diễn ra (hoặc đã điểm danh / có bản ghi) — buổi sắp tới trong
    // tháng chưa có gì để ghi nhật ký. Mới nhất trước.
    final lessons =
        dto.lessons
            .where(
              (l) =>
                  l.attendance != null ||
                  l.status != 'scheduled' ||
                  (l.scheduledStart?.isBefore(now) ?? false),
            )
            .toList()
          ..sort(
            (a, b) =>
                (b.scheduledStart ?? now).compareTo(a.scheduledStart ?? now),
          );
    final attended = lessons.where((l) => !l.isAbsent).length;

    if (lessons.isEmpty) {
      return [
        const _Title(sub: null),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            TutorSurface.gutter,
            28,
            TutorSurface.gutter,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tháng này chưa có buổi học nào.',
                style: TutorType.body(),
              ),
              const SizedBox(height: 4),
              Text(
                'Ghi âm buổi học, nhật ký sẽ tự điền từ bản ghi.',
                style: TutorType.rowSub(),
              ),
              const SizedBox(height: 18),
              const CanvasHand('Bạn không phải gõ gì', size: 17),
            ],
          ),
        ),
      ];
    }

    void open(JournalLessonDto l) => unawaited(
      TutorRecordingDetailScreen.open(
        context,
        RecordingDetailArgs(
          recordingId: l.lessonId,
          studentName: widget.studentName,
        ),
      ),
    );

    return [
      _Title(sub: '$attended buổi đã học · tự điền từ bản ghi âm'),
      Padding(
        padding: const EdgeInsets.fromLTRB(
          TutorSurface.gutter,
          14,
          TutorSurface.gutter,
          0,
        ),
        child: _LatestCard(
          lesson: lessons.first,
          onTap: _hasDetail(lessons.first) ? () => open(lessons.first) : null,
        ),
      ),
      if (lessons.length > 1)
        Padding(
          padding: const EdgeInsets.fromLTRB(
            TutorSurface.gutter,
            6,
            TutorSurface.gutter,
            0,
          ),
          child: Column(
            children: [
              for (var i = 1; i < lessons.length; i++)
                _OlderRow(
                  lesson: lessons[i],
                  first: i == 1,
                  onTap: _hasDetail(lessons[i]) ? () => open(lessons[i]) : null,
                ),
            ],
          ),
        ),
      const Padding(
        padding: EdgeInsets.fromLTRB(0, 28, 30, 0),
        child: Align(
          alignment: Alignment.centerRight,
          child: CanvasHand('Bạn không phải gõ gì', size: 17, swash: false),
        ),
      ),
    ];
  }
}

/// Có trang chi tiết buổi: buổi không vắng và đã ghi (như "Từng buổi học").
bool _hasDetail(JournalLessonDto l) => !l.isAbsent && l.status != 'scheduled';

String _day(DateTime? d) => d == null ? '—' : '${d.day}/${d.month}';

String _weekday(DateTime d) => switch (d.weekday) {
  DateTime.monday => 'Thứ Hai',
  DateTime.tuesday => 'Thứ Ba',
  DateTime.wednesday => 'Thứ Tư',
  DateTime.thursday => 'Thứ Năm',
  DateTime.friday => 'Thứ Sáu',
  DateTime.saturday => 'Thứ Bảy',
  _ => 'Chủ nhật',
};

String _absence(String? reason) {
  final label = switch (reason) {
    RecorderAbsenceReason.cancelled => 'buổi đã huỷ',
    RecorderAbsenceReason.pupilAbsent => 'học sinh nghỉ',
    RecorderAbsenceReason.forgot => 'quên ghi âm',
    RecorderAbsenceReason.battery => 'hết pin',
    RecorderAbsenceReason.appProblem => 'ứng dụng lỗi',
    RecorderAbsenceReason.other => 'lý do khác',
    _ => null,
  };
  return label == null ? 'Vắng' : 'Vắng · $label';
}

String _percent(double share) => '${(share * 100).round()}%';

String? _nonEmpty(String? s) => s == null || s.trim().isEmpty ? null : s.trim();

/// Hàng đầu: nút quay lại tròn, rồi "{tên} · Tháng M" giữa hai mũi tên tháng.
class _Top extends StatelessWidget {
  const _Top({
    required this.label,
    required this.onBack,
    required this.onPrev,
    required this.onNext,
  });

  final String label;
  final VoidCallback onBack;
  final VoidCallback onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      TutorSurface.gutter,
      16,
      TutorSurface.gutter - 8,
      0,
    ),
    child: Row(
      children: [
        CanvasBackButton(onTap: onBack),
        const Spacer(),
        IconButton(
          onPressed: onPrev,
          tooltip: 'Tháng trước',
          icon: const Icon(Icons.chevron_left_rounded, size: 22),
          color: TutorColors.ink3,
        ),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TutorType.rowSub(),
          ),
        ),
        IconButton(
          onPressed: onNext,
          tooltip: 'Tháng sau',
          icon: const Icon(Icons.chevron_right_rounded, size: 22),
          color: TutorColors.ink3,
          disabledColor: const Color(0x331F2A24),
        ),
      ],
    ),
  );
}

class _Title extends StatelessWidget {
  const _Title({required this.sub});

  final String? sub;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      TutorSurface.gutter,
      14,
      TutorSurface.gutter,
      0,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nhật ký học tập',
          style: TutorType.display(size: 26, weight: FontWeight.w600),
        ),
        if (sub != null) ...[
          const SizedBox(height: 4),
          Text(sub!, style: TutorType.rowSub()),
        ],
      ],
    ),
  );
}

/// Chip cao 22; `sage` cho điểm mạnh.
class _Chip extends StatelessWidget {
  const _Chip(this.text, {this.sage = false, this.icon});

  final String text;
  final bool sage;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: sage ? TutorColors.sage : const Color(0xFFEAEAE4),
      borderRadius: BorderRadius.circular(11),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 12, color: TutorColors.ink),
          const SizedBox(width: 5),
        ],
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TutorType.caption(
              color: TutorColors.ink,
            ).copyWith(fontSize: 11.5, height: 1),
          ),
        ),
      ],
    ),
  );
}

/// Buổi mới nhất: thẻ đủ mục.
class _LatestCard extends StatelessWidget {
  const _LatestCard({required this.lesson, required this.onTap});

  final JournalLessonDto lesson;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = lesson;
    final d = l.scheduledStart;
    final content = _nonEmpty(l.content);
    final homework = _nonEmpty(l.homework);
    final previous = _nonEmpty(l.previousHomework);
    final comment = _nonEmpty(l.comment);

    final behaviour = <Widget>[
      if (l.strengths.isNotEmpty) _Chip(l.strengths.first, sage: true),
      if (l.studentTalkShare != null)
        _Chip('Nói ${_percent(l.studentTalkShare!)}'),
      for (final q in l.studentQuietStretches)
        _Chip('Ít nói phút ${q.fromMin}–${q.toMin}'),
    ];

    final fields = <(String, Widget)>[
      if (content != null) ('Nội dung', _value(content)),
      if (previous != null || l.hasExercises)
        (
          'Bài cũ',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (l.hasExercises)
                _value(
                  'Làm ${l.exercisesCorrect ?? 0}/${l.exercisesTotal} bài',
                ),
              if (previous != null && l.hasExercises)
                Text(previous, style: TutorType.rowSub())
              else if (previous != null)
                _value(previous),
            ],
          ),
        ),
      if (homework != null) ('Bài về nhà', _value(homework)),
      if (behaviour.isNotEmpty)
        ('Ý thức', Wrap(spacing: 6, runSpacing: 6, children: behaviour)),
    ];

    return CanvasOutlineCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  d == null ? '—' : '${_weekday(d)} ${_day(d)}',
                  style: TutorType.body(),
                ),
              ),
              if (l.isAbsent)
                CanvasTag(_absence(l.absenceReason))
              else if (l.durationSec > 0)
                const _Chip(
                  'Từ ghi âm',
                  sage: true,
                  icon: Icons.mic_none_rounded,
                ),
            ],
          ),
          if (!l.isAbsent && fields.isEmpty && comment == null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                l.durationSec > 0
                    ? 'Báo cáo buổi này chưa xong.'
                    : 'Buổi này chưa có bản ghi âm.',
                style: TutorType.rowSub(),
              ),
            ),
          for (final (label, value) in fields)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 78,
                    child: Text(label, style: TutorType.rowSub()),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: value),
                ],
              ),
            ),
          if (comment != null)
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                border: Border(top: TutorSurface.rule),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Nhận xét',
                          style: TutorType.caption(color: TutorColors.ink3),
                        ),
                      ),
                      if (l.aiDrafted)
                        const CanvasAiDraftTag()
                      else if (l.editedByTutor)
                        const CanvasTag('Bạn đã sửa'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    comment,
                    style: TutorType.rowSub(color: TutorColors.ink),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static Widget _value(String text) => Text(
    text,
    style: TutorType.body().copyWith(fontSize: 13.5, height: 1.45),
  );
}

/// Buổi trước: ngày nhỏ, nội dung, một dòng ngắn; mở chi tiết buổi.
class _OlderRow extends StatelessWidget {
  const _OlderRow({
    required this.lesson,
    required this.first,
    required this.onTap,
  });

  final JournalLessonDto lesson;
  final bool first;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = lesson;
    final String title;
    final String? sub;
    if (l.isAbsent) {
      title = _absence(l.absenceReason);
      sub = null;
    } else {
      title =
          _nonEmpty(l.content) ??
          (l.durationSec > 0 ? 'Báo cáo chưa xong' : 'Không có bản ghi âm');
      final note = l.difficulties.firstOrNull ?? l.strengths.firstOrNull;
      final parts = [
        if (l.hasExercises)
          'Bài cũ ${l.exercisesCorrect ?? 0}/${l.exercisesTotal}',
        ?note,
      ];
      sub = parts.isEmpty ? null : parts.join(' · ');
    }
    final body = Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        border: Border(top: first ? BorderSide.none : TutorSurface.rule),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 46,
            child: Text(
              _day(l.scheduledStart),
              style: TutorType.caption(color: TutorColors.ink3),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TutorType.body(
                    color: l.isAbsent ? TutorColors.ink3 : TutorColors.ink,
                  ),
                ),
                if (sub != null)
                  Text(
                    sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TutorType.rowSub(),
                  ),
              ],
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 6),
            const CanvasChevron(),
          ],
        ],
      ),
    );
    if (onTap == null) return body;
    return InkWell(onTap: onTap, child: body);
  }
}
