import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/core/router/app_routes.dart';
import 'package:tutora/features/tutor/data/datasources/app_recording_datasource.dart';
import 'package:tutora/features/tutor/data/models/app_recording_models.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_recorder/tutor_report_review_screen.dart';
import 'package:url_launcher/url_launcher.dart';

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

    return Scaffold(
      backgroundColor: TutorColors.bg,
      appBar: AppBar(
        backgroundColor: TutorColors.bg,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        title: Text(
          when == null ? name : '$name · ${when.day}/${when.month}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: TutorColors.ink,
          ),
        ),
      ),
      body: s == null
          ? Center(
              child: _error == null
                  ? const CircularProgressIndicator()
                  : TextButton(
                      onPressed: _load,
                      child: const Text('Không tải được. Chạm để thử lại.'),
                    ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: Row(
                    children: [
                      _TabPill(
                        label: 'Báo cáo',
                        selected: _tab == 0,
                        onTap: () => setState(() => _tab = 0),
                      ),
                      const SizedBox(width: 8),
                      _TabPill(
                        label: 'Tóm tắt buổi',
                        selected: _tab == 1,
                        onTap: () => setState(() => _tab = 1),
                      ),
                    ],
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
                            onShare: _share,
                          )
                        : _MinutesTab(status: s),
                  ),
                ),
              ],
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

  /// Soạn tin báo cáo cho phụ huynh từ các mục đã duyệt.
  String _shareText(AppRecordingStatusDto s) {
    final name = s.studentName.isNotEmpty
        ? s.studentName
        : widget.args.studentName;
    final when = s.startedAt ?? s.scheduledStart;
    final buf = StringBuffer('Báo cáo buổi học của $name');
    if (when != null) buf.write(' — ngày ${_date(when)}');
    for (final (title, body) in [
      ('Nội dung buổi học', s.lessonContent),
      ('Bài tập về nhà', s.homework),
      ('Nhận xét', s.tutorNotes),
    ]) {
      final t = (body ?? '').trim();
      if (t.isEmpty) continue;
      buf.write('\n\n$title:\n$t');
    }
    return buf.toString();
  }

  /// Sao chép báo cáo rồi mở khung chat Zalo với SĐT phụ huynh (zalo.me/{sđt}) —
  /// gia sư chỉ cần dán và gửi.
  Future<void> _share() async {
    final s = _s;
    if (s == null) return;
    await Clipboard.setData(ClipboardData(text: _shareText(s)));
    var phone = (s.parentPhone ?? '').replaceAll(RegExp(r'\D'), '');
    if (phone.startsWith('84') && phone.length >= 11)
      phone = '0${phone.substring(2)}';
    final uri = Uri.parse(
      phone.isNotEmpty ? 'https://zalo.me/$phone' : 'https://zalo.me',
    );
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Đã sao chép báo cáo — dán vào khung chat Zalo rồi gửi.'
              : 'Không mở được Zalo. Báo cáo đã được sao chép.',
        ),
      ),
    );
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

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? TutorColors.ink : TutorColors.surfaceSunken,
    shape: const StadiumBorder(),
    child: InkWell(
      customBorder: const StadiumBorder(),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: selected ? TutorColors.surface : TutorColors.ink3,
          ),
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
    required this.onShare,
  });

  final AppRecordingStatusDto status;
  final String name;
  final VoidCallback onEdit;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final s = status;
    final start = s.startedAt ?? s.scheduledStart;
    final end = s.endedAt;
    final subtitle = [
      if (s.subject != null && s.subject!.isNotEmpty) s.subject!,
      if (s.grade != null) 'Lớp ${s.grade}',
    ].join(' · ');

    final (stLabel, stBg, stFg) = switch (s.status) {
      'sent' =>
        s.deliveryStatus == 'sent'
            ? ('Đã gửi phụ huynh', TutorColors.successBg, TutorColors.success)
            : (
                'Đã duyệt · chờ gửi Zalo',
                TutorColors.accentBg,
                TutorColors.warning,
              ),
      'awaiting_approval' => (
        'Chờ bạn duyệt',
        TutorColors.primaryBg,
        TutorColors.primary,
      ),
      'failed' => ('AI lỗi', TutorColors.primaryBg, TutorColors.primary),
      _ => ('AI đang viết báo cáo', TutorColors.accentBg, TutorColors.warning),
    };

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 40),
      children: [
        Text(
          'Báo cáo buổi học',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            color: TutorColors.primary,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: stBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              stLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: stFg,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
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
          _Section(title: 'Nội dung đã dạy', body: s.lessonContent),
          _Section(title: 'Bài tập về nhà', body: s.homework),
          _Section(title: 'Ghi chú của gia sư', body: s.tutorNotes),
        ],
        if (s.isAwaitingApproval || (s.isFailed && !s.isSent)) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: onEdit,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 48),
                backgroundColor: TutorColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                s.isAwaitingApproval
                    ? 'Sửa & gửi phụ huynh'
                    : 'Tự viết báo cáo',
              ),
            ),
          ),
        ],
        if (s.approvedAt != null || s.isSent) ...[
          const SizedBox(height: 8),
          _DeliveryState(status: s),
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: onShare,
              icon: const Icon(Icons.ios_share_rounded, size: 18),
              label: const Text('Chia sẻ báo cáo'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 48),
                foregroundColor: TutorColors.primary,
                side: const BorderSide(color: TutorColors.primaryBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.rows});

  final List<(IconData, String, String)> rows;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    decoration: BoxDecoration(
      color: TutorColors.surface,
      border: Border.all(color: TutorColors.line),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      children: [
        for (final (icon, k, v) in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(icon, size: 17, color: TutorColors.ink4),
                const SizedBox(width: 10),
                SizedBox(
                  width: 110,
                  child: Text(
                    k,
                    style: const TextStyle(
                      fontSize: 13,
                      color: TutorColors.ink4,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    v,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: TutorColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

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
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: TutorColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            text,
            style: const TextStyle(
              fontSize: 15,
              height: 1.55,
              color: TutorColors.ink2,
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
    decoration: BoxDecoration(
      color: TutorColors.surfaceSunken,
      borderRadius: BorderRadius.circular(10),
    ),
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

/// Trạng thái gửi báo cáo qua Zalo, hiện ngay trên nút "Chia sẻ báo cáo".
class _DeliveryState extends StatelessWidget {
  const _DeliveryState({required this.status});

  final AppRecordingStatusDto status;

  @override
  Widget build(BuildContext context) {
    final s = status;
    final (IconData, String, Color)? v = switch (s.deliveryStatus) {
      'sent' => (
        Icons.check_circle_outline_rounded,
        'Đã gửi qua Zalo',
        TutorColors.success,
      ),
      'failed' => (
        Icons.error_outline_rounded,
        '${(s.deliveryError ?? '').trim().isNotEmpty ? s.deliveryError!.trim() : 'Chưa gửi được qua Zalo.'}'
            ' Bấm "Chia sẻ báo cáo" để tự gửi cho phụ huynh.',
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

  @override
  Widget build(BuildContext context) {
    final m = status.sessionMinutes;
    final processing = status.isAiRunning || status.status == 'processing';
    final summary = (m?.summary ?? '').trim();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 40),
      children: [
        if (m == null || m.isEmpty)
          _Note(
            processing
                ? 'AI đang tóm tắt buổi học. Thường mất 1–2 phút — màn này tự cập nhật.'
                : 'Chưa có tóm tắt buổi cho bản ghi này.',
          )
        else ...[
          if (summary.isNotEmpty) ...[
            const Text(
              'Tóm tắt',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: TutorColors.ink,
              ),
            ),
            const SizedBox(height: 8),
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
          if (m.keyPoints.isNotEmpty) ...[
            const Text(
              'Ý chính',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: TutorColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            for (final k in m.keyPoints)
              _ListItem(
                leading: const Padding(
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
                ),
                text: k,
              ),
            const SizedBox(height: 12),
          ],
          if (m.followUps.isNotEmpty) ...[
            const Text(
              'Việc cần làm buổi sau',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: TutorColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            for (final f in m.followUps)
              _ListItem(
                leading: const Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: Icon(
                    Icons.check_box_outline_blank_rounded,
                    size: 19,
                    color: TutorColors.ink4,
                  ),
                ),
                text: f,
              ),
          ],
        ],
      ],
    );
  }
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
