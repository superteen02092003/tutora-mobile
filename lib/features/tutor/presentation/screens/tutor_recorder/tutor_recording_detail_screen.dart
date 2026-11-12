import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/core/router/app_routes.dart';
import 'package:tutora/core/theme/tutor_design.dart';
import 'package:tutora/features/tutor/data/datasources/app_recording_datasource.dart';
import 'package:tutora/features/tutor/data/models/app_recording_models.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_recorder/topi_before_lesson_screen.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_recorder/tutor_report_review_screen.dart';
import 'package:tutora/features/tutor/presentation/widgets/canvas_ui.dart';
import 'package:tutora/features/tutor/presentation/widgets/topi_skills_section.dart';

/// Tham số mở màn chi tiết một buổi đã ghi.
class RecordingDetailArgs {
  const RecordingDetailArgs({required this.recordingId, this.studentName = ''});

  final String recordingId;
  final String studentName;
}

String _mmss(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return h > 0 ? '${h.toString().padLeft(2, '0')}:$m:$s' : '$m:$s';
}

String _date(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

String _hm(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// Chi tiết một buổi đã ghi: báo cáo gửi phụ huynh (Báo cáo) và tóm tắt buổi (Tóm tắt buổi).
/// Gia sư không nghe lại âm thanh và không xem lời thoại đầy đủ.
class TutorRecordingDetailScreen extends ConsumerStatefulWidget {
  const TutorRecordingDetailScreen({required this.args, super.key});

  final RecordingDetailArgs args;

  static Future<void> open(BuildContext context, RecordingDetailArgs args) =>
      GoRouter.of(context).push(AppRoutes.tutorRecordingDetail, extra: args);

  @override
  ConsumerState<TutorRecordingDetailScreen> createState() => _State();
}

class _State extends ConsumerState<TutorRecordingDetailScreen> {
  AppRecordingStatusDto? _s;
  Object? _error;
  Timer? _poll;
  int _tab = 0;

  static bool _isProcessing(AppRecordingStatusDto s) =>
      s.isAiRunning || s.status == 'processing';

  @override
  void initState() {
    super.initState();
    unawaited(_load());
    _poll = Timer.periodic(const Duration(seconds: 5), (_) {
      final s = _s;
      if (s == null || _isProcessing(s)) unawaited(_load());
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final s = await ref
          .read(appRecordingDatasourceProvider)
          .status(widget.args.recordingId);
      if (!mounted) return;
      setState(() {
        _s = s;
        _error = null;
      });
      if (!_isProcessing(s)) _poll?.cancel();
    } on Object catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _s;
    final name = (s?.studentName.isNotEmpty ?? false)
        ? s!.studentName
        : widget.args.studentName;
    final when = s?.startedAt ?? s?.scheduledStart;

    final subject = [
      if (s?.subject != null && s!.subject!.isNotEmpty) s.subject!,
      if (s?.grade != null) 'Lớp ${s!.grade}',
    ].join(' · ');

    return Scaffold(
      backgroundColor: TutorColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CanvasHeader(
              title: name,
              titleSize: 38,
              onBack: () => Navigator.of(context).maybePop(),
              right: [
                if (when != null) '${when.day}/${when.month}',
                if (subject.isNotEmpty) subject,
              ].join(' · '),
            ),
            if (s == null)
              Expanded(
                child: Center(
                  child: _error == null
                      ? const CircularProgressIndicator()
                      : TextButton(
                          onPressed: _load,
                          child: const Text('Không tải được. Chạm để thử lại.'),
                        ),
                ),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  TutorSurface.gutter,
                  18,
                  TutorSurface.gutter,
                  0,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(bottom: TutorSurface.rule),
                  ),
                  child: Row(
                    children: [
                      _TabPill(
                        label: 'Báo cáo',
                        selected: _tab == 0,
                        onTap: () => setState(() => _tab = 0),
                      ),
                      const SizedBox(width: 24),
                      _TabPill(
                        label: 'Tóm tắt buổi',
                        selected: _tab == 1,
                        onTap: () => setState(() => _tab = 1),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: TutorColors.primary,
                  onRefresh: _load,
                  child: _tab == 0
                      ? _SummaryTab(
                          status: s,
                          name: name,
                          onEdit: _openEditor,
                        )
                      : _MinutesTab(status: s),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openEditor() async {
    final s = _s!;
    await GoRouter.of(context).push(
      AppRoutes.tutorReportReview,
      extra: ReportReviewArgs(
        recordingId: s.recordingId,
        studentName: s.studentName,
        subtitle: [
          if (s.subject != null && s.subject!.isNotEmpty) s.subject!,
          if (s.grade != null) 'Lớp ${s.grade}',
        ].join(' · '),
      ),
    );
    if (mounted) unawaited(_load());
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Tab chữ kiểu canvas: tab đang chọn có gạch mực dày bên dưới.
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: selected ? TutorColors.ink : Colors.transparent,
            width: 3,
          ),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? TutorColors.ink : TutorColors.ink3,
        ),
      ),
    ),
  );
}

// ── Báo cáo ──────────────────────────────────────────────────────────────────

class _SummaryTab extends StatelessWidget {
  const _SummaryTab({
    required this.status,
    required this.name,
    required this.onEdit,
  });

  final AppRecordingStatusDto status;
  final String name;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final s = status;
    final start = s.startedAt ?? s.scheduledStart;
    final end = s.endedAt;
    final subtitle = [
      if (s.subject != null && s.subject!.isNotEmpty) s.subject!,
      if (s.grade != null) 'Lớp ${s.grade}',
    ].join(' · ');

    final (stLabel, stFilled) = switch (s.status) {
      'sent' =>
        s.deliveryStatus == 'sent'
            ? ('Đã gửi phụ huynh', false)
            : ('Đã duyệt · chờ gửi Zalo', false),
      'awaiting_approval' => ('Chờ bạn duyệt', true),
      'failed' => ('AI lỗi', true),
      _ => ('AI đang viết báo cáo', false),
    };

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        TutorSurface.gutter,
        20,
        TutorSurface.gutter,
        40,
      ),
      children: [
        Row(
          children: [
            const Expanded(child: CanvasKicker('Báo cáo buổi học')),
            CanvasTag(stLabel, filled: stFilled),
          ],
        ),
        const SizedBox(height: 14),
        _InfoCard(
          rows: [
            (
              Icons.person_outline_rounded,
              'Học sinh',
              subtitle.isEmpty ? name : '$name · $subtitle',
            ),
            if (start != null) (Icons.event_outlined, 'Ngày', _date(start)),
            if (start != null)
              (
                Icons.schedule_rounded,
                'Giờ ghi',
                end == null ? _hm(start) : '${_hm(start)} – ${_hm(end)}',
              ),
            (
              Icons.timer_outlined,
              'Thời lượng',
              s.durationSec > 0 ? _mmss(Duration(seconds: s.durationSec)) : '—',
            ),
            (
              Icons.graphic_eq_rounded,
              'Số đoạn ghi',
              '${s.partCount} đoạn · ${(s.bytes / 1048576).toStringAsFixed(1)} MB',
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (s.isAiRunning || s.status == 'processing')
          const _Note(
            'AI đang viết báo cáo. Thường mất 1–2 phút — màn này tự cập nhật.',
          )
        else if (s.isFailed && (s.lessonContent ?? '').isEmpty)
          _Note(s.errorMessage ?? 'AI chưa tạo được báo cáo từ bản ghi này.')
        else ...[
          _Section(
            title: 'Nội dung buổi học',
            body: _pick(s.zaloContent, s.lessonContent),
          ),
          _Section(
            title: 'Bài tập về nhà',
            body: _pick(s.zaloHomework, s.homework),
          ),
          _Section(title: 'Nhận xét', body: _pick(s.zaloNotes, s.tutorNotes)),
        ],
        if (s.isAwaitingApproval || (s.isFailed && !s.isSent)) ...[
          const SizedBox(height: 8),
          CanvasCta(
            label: s.isAwaitingApproval
                ? 'Sửa và gửi phụ huynh'
                : 'Tự viết báo cáo',
            onPressed: onEdit,
          ),
        ],
        if (s.approvedAt != null || s.isSent) ...[
          const SizedBox(height: 8),
          _DeliveryState(status: s),
        ],
        // Topi v1 — mỗi phần tự ẩn khi cờ tắt hoặc chưa có dữ liệu.
        TopiBeforeLessonEntry(
          args: BeforeLessonArgs(lessonId: s.recordingId, studentName: name),
          padding: const EdgeInsets.only(top: 20),
        ),
        TopiSkillsSection(lessonId: s.recordingId),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.rows});

  final List<(IconData, String, String)> rows;

  /// Hàng kẻ mực của canvas: nhãn nhỏ viết hoa trái, giá trị phải (bỏ icon).
  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var i = 0; i < rows.length; i++)
        CanvasRow(
          lastRule: i == rows.length - 1,
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              SizedBox(
                width: 110,
                child: CanvasKicker(rows[i].$2),
              ),
              Expanded(
                child: Text(
                  rows[i].$3,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: TutorColors.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

/// Mục phụ huynh nhận: tin Zalo đã duyệt; buổi cũ chưa có thì dùng bản dài.
String? _pick(String? zalo, String? long) =>
    (zalo ?? '').trim().isNotEmpty ? zalo : long;

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) {
    final text = (body ?? '').trim();
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CanvasKicker(title, color: TutorColors.ink),
          const SizedBox(height: 8),
          SelectableText(
            text,
            style: const TextStyle(
              fontSize: 16,
              height: 1.55,
              color: TutorColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: TutorSurface.well(),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        color: TutorColors.ink3,
        height: 1.4,
      ),
    ),
  );
}

/// Trạng thái gửi báo cáo qua Zalo.
class _DeliveryState extends StatelessWidget {
  const _DeliveryState({required this.status});

  final AppRecordingStatusDto status;

  @override
  Widget build(BuildContext context) {
    final s = status;
    final v = switch (s.deliveryStatus) {
      'sent' => (
        Icons.check_circle_outline_rounded,
        'Đã gửi qua Zalo',
        TutorColors.success,
      ),
      'failed' => (
        Icons.error_outline_rounded,
        '${(s.deliveryError ?? '').trim().isNotEmpty ? s.deliveryError!.trim() : 'Chưa gửi được qua Zalo.'}'
            ' Hãy kiểm tra lại số điện thoại phụ huynh.',
        TutorColors.warning,
      ),
      'pending' when s.deliveryChannel != 'booking' => (
        Icons.schedule_rounded,
        'Đang chờ gửi qua Zalo',
        TutorColors.warning,
      ),
      _ => null,
    };
    if (v == null) return const SizedBox.shrink();
    final (icon, text, color) = v;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tóm tắt buổi ─────────────────────────────────────────────────────────────

class _MinutesTab extends StatelessWidget {
  const _MinutesTab({required this.status});

  final AppRecordingStatusDto status;

  static const _bullet = Padding(
    padding: EdgeInsets.only(top: 8),
    child: SizedBox(
      width: 6,
      height: 6,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: TutorColors.primary,
          shape: BoxShape.circle,
        ),
      ),
    ),
  );

  static Widget _icon(IconData icon, Color color) => Padding(
    padding: const EdgeInsets.only(top: 1),
    child: Icon(icon, size: 18, color: color),
  );

  @override
  Widget build(BuildContext context) {
    final m = status.sessionMinutes;
    final processing = status.isAiRunning || status.status == 'processing';
    final summary = (m?.summary ?? '').trim();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        TutorSurface.gutter,
        20,
        TutorSurface.gutter,
        40,
      ),
      children: [
        if (m == null || m.isEmpty)
          _Note(
            processing
                ? 'AI đang tóm tắt buổi học. Thường mất 1–2 phút — màn này tự cập nhật.'
                : 'Chưa có tóm tắt buổi cho bản ghi này.',
          )
        else ...[
          if (summary.isNotEmpty) ...[
            const _MinutesHeading('Tóm tắt'),
            SelectableText(
              summary,
              style: const TextStyle(
                fontSize: 15,
                height: 1.55,
                color: TutorColors.ink2,
              ),
            ),
            const SizedBox(height: 20),
          ],
          if (m.sections.isNotEmpty) ...[
            const _MinutesHeading('Diễn biến buổi học'),
            for (final (i, s) in m.sections.indexed) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '${i + 1}. ${s.title ?? ''}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: TutorColors.ink,
                  ),
                ),
              ),
              for (final d in s.details) _ListItem(leading: _bullet, text: d),
              const SizedBox(height: 6),
            ],
            const SizedBox(height: 12),
          ],
          if (m.exercises.isNotEmpty) ...[
            _MinutesHeading('Bài đã làm (${m.exercises.length})'),
            for (final e in m.exercises) _ExerciseCard(exercise: e),
            const SizedBox(height: 14),
          ],
          if (m.strengths.isNotEmpty) ...[
            const _MinutesHeading('Học sinh đã nắm'),
            for (final s in m.strengths)
              _ListItem(
                leading: _icon(
                  Icons.check_circle_outline_rounded,
                  TutorColors.success,
                ),
                text: s,
              ),
            const SizedBox(height: 12),
          ],
          if (m.difficulties.isNotEmpty) ...[
            const _MinutesHeading('Học sinh còn vướng'),
            for (final d in m.difficulties)
              _ListItem(
                leading: _icon(
                  Icons.error_outline_rounded,
                  TutorColors.warning,
                ),
                text: d,
              ),
            const SizedBox(height: 12),
          ],
          if (m.usefulNotes.isNotEmpty) ...[
            const _MinutesHeading('Thông tin hữu ích'),
            for (final u in m.usefulNotes)
              _ListItem(
                leading: _icon(
                  Icons.lightbulb_outline_rounded,
                  TutorColors.accent,
                ),
                text: u,
              ),
            const SizedBox(height: 12),
          ],
          if (m.teachingNotes.isNotEmpty) ...[
            const _MinutesHeading('Gợi ý cách dạy'),
            for (final n in m.teachingNotes) _TeachingNoteCard(note: n),
            const SizedBox(height: 14),
          ],
          if (m.keyPoints.isNotEmpty) ...[
            const _MinutesHeading('Ý chính'),
            for (final k in m.keyPoints) _ListItem(leading: _bullet, text: k),
            const SizedBox(height: 12),
          ],
          if (m.followUps.isNotEmpty) ...[
            const _MinutesHeading('Việc cần làm buổi sau'),
            for (final f in m.followUps)
              _ListItem(
                leading: _icon(
                  Icons.check_box_outline_blank_rounded,
                  TutorColors.ink4,
                ),
                text: f,
              ),
          ],
        ],
      ],
    );
  }
}

class _MinutesHeading extends StatelessWidget {
  const _MinutesHeading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: CanvasKicker(text, color: TutorColors.ink),
  );
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({required this.exercise});

  final MinutesExerciseDto exercise;

  (Color, Color) get _tone => switch (exercise.result) {
    'Tự làm đúng' => (TutorColors.success, TutorColors.successBg),
    'Đúng sau khi được gợi ý' => (TutorColors.warning, TutorColors.warningBg),
    'Làm sai' => (TutorColors.danger, TutorColors.dangerBg),
    _ => (TutorColors.ink3, TutorColors.surfaceSunken),
  };

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = _tone;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TutorColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: TutorColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            exercise.type,
            style: const TextStyle(
              fontSize: 15,
              height: 1.45,
              color: TutorColors.ink,
            ),
          ),
          if (exercise.result != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                exercise.result!,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ),
          ],
          if (exercise.note != null) ...[
            const SizedBox(height: 6),
            Text(
              exercise.note!,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: TutorColors.ink3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TeachingNoteCard extends StatelessWidget {
  const _TeachingNoteCard({required this.note});

  final TeachingNoteDto note;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: TutorColors.accentBg,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: TutorColors.accentBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          note.content,
          style: const TextStyle(
            fontSize: 15,
            height: 1.45,
            color: TutorColors.ink,
          ),
        ),
        if (note.example != null) ...[
          const SizedBox(height: 6),
          Text(
            note.example!,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.45,
              fontStyle: FontStyle.italic,
              color: TutorColors.ink3,
            ),
          ),
        ],
      ],
    ),
  );
}

class _ListItem extends StatelessWidget {
  const _ListItem({required this.leading, required this.text});

  final Widget leading;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 22,
          child: Align(alignment: Alignment.topLeft, child: leading),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
              color: TutorColors.ink2,
            ),
          ),
        ),
      ],
    ),
  );
}
