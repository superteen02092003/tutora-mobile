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
import 'package:tutora/features/tutor/presentation/widgets/lesson_insights_card.dart';
import 'package:tutora/features/tutor/presentation/widgets/topi_skills_section.dart';

/// Tham số mở màn chi tiết một buổi đã ghi.
class RecordingDetailArgs {
  const RecordingDetailArgs({required this.recordingId, this.studentName = ''});

  final String recordingId;
  final String studentName;
}

String _hm(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// Chi tiết một buổi đã ghi (V5.6 board V56-LessonDetail): báo cáo gửi phụ
/// huynh (Báo cáo) và tóm tắt buổi (Tóm tắt buổi).
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

    // "19:01 – 20:30 · 86 phút · 18 đoạn ghi" — chỉ phần có dữ liệu.
    final start = s?.startedAt ?? s?.scheduledStart;
    final end = s?.endedAt;
    final lead = s == null
        ? null
        : [
            if (start != null && end != null)
              '${_hm(start)} – ${_hm(end)}'
            else if (start != null)
              _hm(start),
            if (s.durationSec > 0) '${(s.durationSec / 60).round()} phút',
            if (s.partCount > 0) '${s.partCount} đoạn ghi',
          ].join(' · ');

    return Scaffold(
      backgroundColor: TutorColors.bg,
      body: DecoratedBox(
        decoration: TutorSurface.paper,
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CanvasHeader(
                title: name,
                onBack: () => Navigator.of(context).maybePop(),
                right: [
                  if (when != null) '${when.day}/${when.month}',
                  if (subject.isNotEmpty) subject,
                ].join(' · '),
                lead: (lead ?? '').isEmpty ? null : lead,
              ),
              if (s == null)
                Expanded(
                  child: Center(
                    child: _error == null
                        ? const CircularProgressIndicator(
                            color: TutorColors.ink,
                          )
                        : TextButton(
                            onPressed: _load,
                            style: TextButton.styleFrom(
                              foregroundColor: TutorColors.ink,
                            ),
                            child: const Text(
                              'Không tải được. Chạm để thử lại.',
                            ),
                          ),
                  ),
                )
              else ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    TutorSurface.gutter,
                    16,
                    TutorSurface.gutter,
                    0,
                  ),
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0x141F2A24)),
                      ),
                    ),
                    child: Row(
                      children: [
                        _TabPill(
                          label: 'Báo cáo',
                          selected: _tab == 0,
                          onTap: () => setState(() => _tab = 0),
                        ),
                        const SizedBox(width: 22),
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

  /// Tab chữ V5.6: tab đang chọn chữ mực, gạch 2 px bên dưới.
  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    child: InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(top: 6, bottom: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? TutorColors.ink : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TutorType.action(
            color: selected ? TutorColors.ink : const Color(0xFF8A8F89),
          ),
        ),
      ),
    ),
  );
}

// ── Mảnh dùng chung ──────────────────────────────────────────────────────────

/// Nhãn nhỏ thường (canvas `.lbl`).
Widget _lbl(String text, {Color color = TutorColors.ink3}) =>
    Text(text, style: TutorType.caption(color: color));

/// Tiêu đề nhóm Bricolage, tuỳ chọn nhãn "Nháp AI" bên phải.
class _SectionHead extends StatelessWidget {
  const _SectionHead(this.text, {this.ai = false});

  final String text;
  final bool ai;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Expanded(child: Text(text, style: TutorType.sectionTitle())),
        if (ai) const CanvasAiDraftTag(),
      ],
    ),
  );
}

/// Chip sage có biểu tượng ("Đã gửi qua Zalo").
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.text, this.icon, this.filled = false});

  final String text;
  final IconData? icon;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final fg = filled ? Colors.white : TutorColors.ink;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: filled ? TutorColors.ink : TutorColors.sage,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TutorType.caption(
                color: fg,
              ).copyWith(fontSize: 11.5, height: 1),
            ),
          ),
        ],
      ),
    );
  }
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

    final (stLabel, stFilled, stIcon) = switch (s.status) {
      'sent' =>
        s.deliveryStatus == 'sent'
            ? ('Đã gửi phụ huynh', false, Icons.check_rounded)
            : ('Đã duyệt · chờ gửi Zalo', false, Icons.schedule_rounded),
      'awaiting_approval' => ('Chờ bạn duyệt', true, null),
      'failed' => ('AI lỗi', true, null),
      _ => ('AI đang viết báo cáo', false, null),
    };

    final sections = [
      ('Nội dung buổi học', _pick(s.zaloContent, s.lessonContent)),
      ('Bài về nhà', _pick(s.zaloHomework, s.homework)),
      ('Nhận xét', _pick(s.zaloNotes, s.tutorNotes)),
    ].where((e) => (e.$2 ?? '').trim().isNotEmpty).toList();

    final processing = s.isAiRunning || s.status == 'processing';
    final failedEmpty = s.isFailed && (s.lessonContent ?? '').isEmpty;
    final exercises = s.sessionMinutes?.exercises ?? const [];

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        TutorSurface.gutter,
        14,
        TutorSurface.gutter,
        40,
      ),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          decoration: TutorSurface.card(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: _StatusChip(
                      text: stLabel,
                      icon: stIcon,
                      filled: stFilled,
                    ),
                  ),
                  const Spacer(),
                  if (!processing && !failedEmpty && sections.isNotEmpty)
                    const CanvasAiDraftTag(),
                ],
              ),
              if (processing)
                const _Note(
                  'AI đang viết báo cáo. Thường mất 1–2 phút — màn này tự cập nhật.',
                )
              else if (failedEmpty)
                _Note(
                  s.errorMessage ?? 'AI chưa tạo được báo cáo từ bản ghi này.',
                )
              else
                for (final (title, body) in sections) ...[
                  const SizedBox(height: 12),
                  _lbl(title),
                  const SizedBox(height: 4),
                  SelectableText(body!.trim(), style: TutorType.body()),
                ],
              if (s.approvedAt != null || s.isSent) _DeliveryState(status: s),
            ],
          ),
        ),
        if (s.isAwaitingApproval || (s.isFailed && !s.isSent)) ...[
          const SizedBox(height: 14),
          CanvasCta(
            label: s.isAwaitingApproval
                ? 'Sửa và gửi phụ huynh'
                : 'Tự viết báo cáo',
            onPressed: onEdit,
          ),
        ],
        if (exercises.isNotEmpty) ...[
          const SizedBox(height: 22),
          const _SectionHead('Bài đã làm', ai: true),
          for (final (i, e) in exercises.indexed)
            _ExerciseRow(exercise: e, first: i == 0),
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

/// Mục phụ huynh nhận: tin Zalo đã duyệt; buổi cũ chưa có thì dùng bản dài.
String? _pick(String? zalo, String? long) =>
    (zalo ?? '').trim().isNotEmpty ? zalo : long;

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Text(text, style: TutorType.rowSub()),
  );
}

/// Trạng thái gửi báo cáo qua Zalo — dòng nhỏ cuối thẻ báo cáo.
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
        TutorColors.ink3,
      ),
      'failed' => (
        Icons.error_outline_rounded,
        '${(s.deliveryError ?? '').trim().isNotEmpty ? s.deliveryError!.trim() : 'Chưa gửi được qua Zalo.'}'
            ' Hãy kiểm tra lại số điện thoại phụ huynh.',
        TutorColors.danger,
      ),
      'pending' when s.deliveryChannel != 'booking' => (
        Icons.schedule_rounded,
        'Đang chờ gửi qua Zalo',
        TutorColors.ink3,
      ),
      _ => null,
    };
    if (v == null) return const SizedBox.shrink();
    final (icon, text, color) = v;
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(border: Border(top: TutorSurface.rule)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TutorType.rowSub(color: color)),
          ),
        ],
      ),
    );
  }
}

/// Hàng bài đã làm: biểu tượng kết quả, dạng bài (+ ghi chú), kết quả bên phải.
class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({required this.exercise, this.first = false});

  final MinutesExerciseDto exercise;
  final bool first;

  IconData get _icon => switch (exercise.result) {
    'Tự làm đúng' => Icons.check_circle_rounded,
    'Đúng sau khi được gợi ý' => Icons.adjust_rounded,
    'Làm sai' => Icons.cancel_outlined,
    _ => Icons.radio_button_unchecked_rounded,
  };

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 13),
    decoration: BoxDecoration(
      border: Border(
        top: first
            ? BorderSide.none
            : const BorderSide(color: Color(0x0F1F2A24)),
      ),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            _icon,
            size: 18,
            color: exercise.result == 'Làm sai'
                ? TutorColors.ink3
                : TutorColors.ink,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(exercise.type, style: TutorType.body()),
              if (exercise.note != null)
                Text(exercise.note!, style: TutorType.rowSub()),
            ],
          ),
        ),
        if (exercise.result != null) ...[
          const SizedBox(width: 10),
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: Text(
                exercise.result!,
                textAlign: TextAlign.right,
                style: TutorType.caption(color: TutorColors.ink3),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

// ── Tóm tắt buổi ─────────────────────────────────────────────────────────────

class _MinutesTab extends StatelessWidget {
  const _MinutesTab({required this.status});

  final AppRecordingStatusDto status;

  static const _bullet = Padding(
    padding: EdgeInsets.only(top: 8),
    child: SizedBox(
      width: 5,
      height: 5,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: TutorColors.ink,
          shape: BoxShape.circle,
        ),
      ),
    ),
  );

  static Widget _icon(IconData icon, Color color) => Padding(
    padding: const EdgeInsets.only(top: 2),
    child: Icon(icon, size: 17, color: color),
  );

  @override
  Widget build(BuildContext context) {
    final m = status.sessionMinutes;
    final processing = status.isAiRunning || status.status == 'processing';
    final summary = (m?.summary ?? '').trim();
    // "Bài đã làm" nằm ở tab Báo cáo (board V56-LessonDetail).
    final empty =
        m == null ||
        (summary.isEmpty &&
            m.sections.isEmpty &&
            m.strengths.isEmpty &&
            m.difficulties.isEmpty &&
            m.usefulNotes.isEmpty &&
            m.teachingNotes.isEmpty &&
            m.keyPoints.isEmpty &&
            m.followUps.isEmpty);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        TutorSurface.gutter,
        14,
        TutorSurface.gutter,
        40,
      ),
      children: [
        // Số liệu đo từ bản ghi (chỉ gia sư thấy) — tự ẩn khi chưa có.
        LessonInsightsCard(
          lessonId: status.recordingId,
          padding: const EdgeInsets.only(bottom: 14),
        ),
        if (empty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: TutorSurface.card(),
            child: Text(
              processing
                  ? 'AI đang tóm tắt buổi học. Thường mất 1–2 phút — màn này tự cập nhật.'
                  : (m?.exercises.isNotEmpty ?? false)
                  ? 'Chưa có tóm tắt buổi. Bài đã làm nằm ở tab Báo cáo.'
                  : 'Chưa có tóm tắt buổi cho bản ghi này.',
              style: TutorType.rowSub(),
            ),
          )
        else ...[
          if (summary.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              decoration: TutorSurface.card(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: _lbl('Tóm tắt')),
                      const CanvasAiDraftTag(),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SelectableText(summary, style: TutorType.body()),
                ],
              ),
            ),
            const SizedBox(height: 22),
          ],
          if (m.sections.isNotEmpty) ...[
            const _SectionHead('Diễn biến buổi học', ai: true),
            for (final (i, s) in m.sections.indexed) ...[
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 6),
                child: Text(
                  '${i + 1}. ${s.title ?? ''}',
                  style: TutorType.rowTitle().copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              for (final d in s.details) _ListItem(leading: _bullet, text: d),
              const SizedBox(height: 6),
            ],
            const SizedBox(height: 14),
          ],
          if (m.strengths.isNotEmpty) ...[
            const _SectionHead('Học sinh đã nắm', ai: true),
            for (final s in m.strengths)
              _ListItem(
                leading: _icon(
                  Icons.check_circle_outline_rounded,
                  TutorColors.ink,
                ),
                text: s,
              ),
            const SizedBox(height: 14),
          ],
          if (m.difficulties.isNotEmpty) ...[
            const _SectionHead('Học sinh còn vướng', ai: true),
            for (final d in m.difficulties)
              _ListItem(
                leading: _icon(Icons.error_outline_rounded, TutorColors.ink3),
                text: d,
              ),
            const SizedBox(height: 14),
          ],
          if (m.usefulNotes.isNotEmpty) ...[
            const _SectionHead('Thông tin hữu ích', ai: true),
            for (final u in m.usefulNotes)
              _ListItem(
                leading: _icon(
                  Icons.lightbulb_outline_rounded,
                  TutorColors.ink,
                ),
                text: u,
              ),
            const SizedBox(height: 14),
          ],
          if (m.teachingNotes.isNotEmpty) ...[
            const _SectionHead('Gợi ý cách dạy'),
            for (final (i, n) in m.teachingNotes.indexed)
              _TeachingNoteCard(note: n, sage: i == 0),
            const SizedBox(height: 14),
          ],
          if (m.keyPoints.isNotEmpty) ...[
            const _SectionHead('Ý chính', ai: true),
            for (final k in m.keyPoints) _ListItem(leading: _bullet, text: k),
            const SizedBox(height: 14),
          ],
          if (m.followUps.isNotEmpty) ...[
            const _SectionHead('Việc cần làm buổi sau', ai: true),
            for (final f in m.followUps)
              _ListItem(
                leading: _icon(
                  Icons.check_box_outline_blank_rounded,
                  TutorColors.ink3,
                ),
                text: f,
              ),
          ],
        ],
      ],
    );
  }
}

/// Gợi ý cách dạy (board V56-Feedback): thẻ có bóng đèn + "Nháp AI"; thẻ đầu
/// là sage nổi ("thử lần sau").
class _TeachingNoteCard extends StatelessWidget {
  const _TeachingNoteCard({required this.note, this.sage = false});

  final TeachingNoteDto note;
  final bool sage;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
    decoration: sage ? TutorSurface.sage() : TutorSurface.card(),
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
            const SizedBox(width: 6),
            Expanded(
              child: _lbl(
                'Gợi ý',
                color: sage ? TutorColors.ink : TutorColors.ink3,
              ),
            ),
            CanvasAiDraftTag(onSage: sage),
          ],
        ),
        const SizedBox(height: 8),
        Text(note.content, style: TutorType.body()),
        if (note.example != null) ...[
          const SizedBox(height: 6),
          Text(
            note.example!,
            style: TutorType.rowSub().copyWith(fontStyle: FontStyle.italic),
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
        Expanded(child: Text(text, style: TutorType.body())),
      ],
    ),
  );
}
