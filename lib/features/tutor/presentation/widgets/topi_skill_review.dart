import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/core/theme/tutor_design.dart';
import 'package:tutora/features/tutor/data/datasources/app_recording_datasource.dart';
import 'package:tutora/features/tutor/data/datasources/topi_datasource.dart';
import 'package:tutora/features/tutor/data/models/topi_models.dart';
import 'package:tutora/features/tutor/data/models/topi_review_models.dart';
import 'package:tutora/features/tutor/presentation/providers/topi_provider.dart';
import 'package:tutora/features/tutor/presentation/widgets/canvas_ui.dart';
import 'package:tutora/features/tutor/presentation/widgets/topi_ui.dart';
import 'package:url_launcher/url_launcher.dart';

/// Lý do gia sư bác một kỹ năng Topi đề xuất (canvas "Topi skill review", màn D).
const skillRejectReasons = [
  'Bé sơ suất, tự sửa ngay',
  'Câu của tôi, không phải của bé',
  'Bé đã làm được rồi',
  'Chép lời sai',
  'Sai kỹ năng',
];
const skillWrongReason = 'Sai kỹ năng';

/// "Kỹ năng tìm thấy trong buổi": mỗi thay đổi Topi đề xuất, gia sư bấm Đúng
/// hoặc Không đúng (lý do, sửa kỹ năng). Chỉ dòng đã xác nhận mới tính mức và
/// sao. Tự ẩn khi cờ `skills` tắt hoặc buổi chưa có đề xuất.
class TopiSkillReviewSection extends ConsumerStatefulWidget {
  const TopiSkillReviewSection({
    required this.lessonId,
    this.grade,
    this.padding = const EdgeInsets.only(top: 22),
    super.key,
  });

  final String lessonId;
  final int? grade;
  final EdgeInsets padding;

  @override
  ConsumerState<TopiSkillReviewSection> createState() =>
      _TopiSkillReviewSectionState();
}

class _TopiSkillReviewSectionState
    extends ConsumerState<TopiSkillReviewSection> {
  List<SkillReviewItem>? _items;
  final _open = <String>{};
  final _asking = <String>{};
  final _picking = <String>{};
  final _busy = <String>{};
  List<SkillNodeOption>? _nodes;

  bool _loading = false;

  Future<void> _load() async {
    if (_loading) return;
    _loading = true;
    try {
      final items = await ref
          .read(topiDatasourceProvider)
          .getSkillReview(widget.lessonId);
      if (mounted) setState(() => _items = items);
    } on Object {
      if (mounted) setState(() => _items = const []);
    }
  }

  Future<void> _review(
    SkillReviewItem it,
    String verdict, {
    String? reason,
    String? corrected,
  }) async {
    setState(() => _busy.add(it.id));
    try {
      final items = await ref
          .read(topiDatasourceProvider)
          .reviewSkill(
            it.id,
            verdict: verdict,
            reason: reason,
            correctedNode: corrected,
          );
      if (!mounted) return;
      setState(() {
        _items = items;
        _asking.remove(it.id);
        _picking.remove(it.id);
      });
      // Hồ sơ học sinh chỉ tính dòng đã xác nhận: làm mới phần kỹ năng.
      ref.invalidate(lessonTopiProvider(widget.lessonId));
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Chưa lưu được. Kiểm tra mạng rồi thử lại.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
    } finally {
      if (mounted) setState(() => _busy.remove(it.id));
    }
  }

  Future<void> _pickNodes() async {
    if (_nodes != null || widget.grade == null) return;
    try {
      final nodes = await ref
          .read(topiDatasourceProvider)
          .getSkillNodes(widget.grade!);
      if (mounted) setState(() => _nodes = nodes);
    } on Object {
      if (mounted) setState(() => _nodes = const []);
    }
  }

  Future<void> _replay(SkillReviewItem it) async {
    try {
      final url = await ref
          .read(appRecordingDatasourceProvider)
          .audioUrl(widget.lessonId);
      final at = (it.atSec ?? 0).floor();
      // Media fragment: trình phát của trình duyệt nhảy tới giây này.
      await launchUrl(
        Uri.parse('$url#t=${at < 5 ? 0 : at - 5}'),
        mode: LaunchMode.externalApplication,
      );
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Chưa mở được bản ghi âm của buổi này.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(topiFlagsNowProvider).skills) return const SizedBox.shrink();
    // Chỉ gọi API khi cờ skills bật.
    if (_items == null && !_loading) unawaited(_load());
    final items = _items;
    if (items == null || items.isEmpty) return const SizedBox.shrink();
    final pending = items.where((i) => i.isPending).length;

    return Padding(
      padding: widget.padding,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        decoration: TutorSurface.card(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Kỹ năng tìm thấy trong buổi',
                    style: TutorType.sectionTitle(),
                  ),
                ),
                if (pending > 0)
                  Text(
                    '$pending chưa xác nhận',
                    style: TutorType.rowSub(color: TutorColors.warning),
                  )
                else
                  const CanvasAiDraftTag(),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Chỉ dòng bạn xác nhận mới lên mức và có sao.',
              style: TutorType.caption(),
            ),
            for (final it in items) _row(it),
          ],
        ),
      ),
    );
  }

  Widget _row(SkillReviewItem it) {
    final open = _open.contains(it.id);
    final busy = _busy.contains(it.id);
    final asking = _asking.contains(it.id);
    final picking = _picking.contains(it.id);
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.only(top: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: TutorColors.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(it.title, style: TutorType.rowTitle())),
              const SizedBox(width: 8),
              Text(
                _change(it),
                style: TutorType.rowSub(
                  color: it.isRejected
                      ? TutorColors.danger
                      : TutorColors.success,
                ),
              ),
            ],
          ),
          if ((it.exercise ?? '').isNotEmpty || it.context.isNotEmpty)
            InkWell(
              onTap: () => setState(
                () => open ? _open.remove(it.id) : _open.add(it.id),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 40),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        (it.exercise ?? '').isNotEmpty
                            ? 'Trong bài: ${it.exercise}'
                            : 'Đoạn hội thoại',
                        style: TutorType.rowSub(),
                        maxLines: open ? 4 : 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      open ? 'Thu gọn ▴' : 'Xem hội thoại ▾',
                      style: TutorType.rowSub(),
                    ),
                  ],
                ),
              ),
            ),
          if (open) _context(it),
          const SizedBox(height: 8),
          if (it.isPending && !asking)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: busy
                        ? null
                        : () => setState(() => _asking.add(it.id)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: TutorColors.danger,
                      backgroundColor: TutorColors.dangerBg,
                      side: const BorderSide(color: TutorColors.dangerBorder),
                      minimumSize: const Size.fromHeight(44),
                      shape: const StadiumBorder(),
                    ),
                    child: const Text('Không đúng'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: busy ? null : () => _review(it, 'confirmed'),
                    style: FilledButton.styleFrom(
                      backgroundColor: TutorColors.primary,
                      minimumSize: const Size.fromHeight(44),
                      shape: const StadiumBorder(),
                    ),
                    child: const Text('Đúng'),
                  ),
                ),
              ],
            ),
          if (asking && !picking) _reasons(it, busy),
          if (picking) _picker(it, busy),
          if (!it.isPending)
            Row(
              children: [
                Expanded(
                  child: Text(
                    _result(it),
                    style: TutorType.rowSub(
                      color: it.isRejected
                          ? TutorColors.danger
                          : TutorColors.success,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: busy ? null : () => _review(it, 'proposed'),
                  child: const Text('Đổi lại'),
                ),
              ],
            ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _context(SkillReviewItem it) => Container(
    margin: const EdgeInsets.only(top: 4),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: TutorColors.surfaceSunken,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final l in it.context)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 26,
                  child: Text(
                    l.who,
                    style: TutorType.rowSub(
                      color: l.who == 'HS'
                          ? TutorColors.success
                          : TutorColors.ink3,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    l.text,
                    style: TutorType.body().copyWith(
                      fontWeight: l.evidence ? FontWeight.w600 : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (it.hasAudio && it.atSec != null)
          OutlinedButton.icon(
            onPressed: () => _replay(it),
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: Text('Nghe lại · ${_mmss(it.atSec!)}'),
            style: OutlinedButton.styleFrom(
              foregroundColor: TutorColors.ink,
              minimumSize: const Size(0, 40),
              shape: const StadiumBorder(),
            ),
          ),
      ],
    ),
  );

  Widget _reasons(SkillReviewItem it, bool busy) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: TutorColors.dangerBg,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vì sao không đúng? (không bắt buộc)',
          style: TutorType.rowSub(color: TutorColors.danger),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final r in skillRejectReasons)
              ActionChip(
                label: Text(r),
                onPressed: busy
                    ? null
                    : () {
                        if (r == skillWrongReason) {
                          setState(() => _picking.add(it.id));
                          unawaited(_pickNodes());
                        } else {
                          unawaited(_review(it, 'rejected', reason: r));
                        }
                      },
              ),
          ],
        ),
        Row(
          children: [
            TextButton(
              onPressed: busy ? null : () => _review(it, 'rejected'),
              child: const Text('Bỏ qua'),
            ),
            TextButton(
              onPressed: busy
                  ? null
                  : () => setState(() => _asking.remove(it.id)),
              child: const Text('Huỷ'),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _picker(SkillReviewItem it, bool busy) {
    final nodes = (_nodes ?? const <SkillNodeOption>[])
        .where((n) => n.id != it.node)
        .toList();
    // "Gần với bài này": cùng chương (mã nút gần nhau) trước.
    final near = [...nodes]
      ..sort(
        (a, b) => _distance(a.id, it.node).compareTo(_distance(b.id, it.node)),
      );
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: TutorColors.surface,
        border: Border.all(color: TutorColors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Kỹ năng đúng là gì?', style: TutorType.rowTitle()),
          const SizedBox(height: 8),
          if (_nodes == null)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else ...[
            Autocomplete<SkillNodeOption>(
              displayStringForOption: (o) => o.nameVi,
              optionsBuilder: (v) {
                final q = v.text.trim().toLowerCase();
                if (q.isEmpty) return const Iterable.empty();
                return nodes.where((n) => n.nameVi.toLowerCase().contains(q));
              },
              onSelected: (o) => _review(
                it,
                'rejected',
                reason: skillWrongReason,
                corrected: o.id,
              ),
              fieldViewBuilder: (context, c, f, _) => TextField(
                controller: c,
                focusNode: f,
                decoration: const InputDecoration(
                  hintText: 'Tìm kỹ năng, ví dụ: đổi chiều bất đẳng thức',
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text('Gần với bài này', style: TutorType.caption()),
            for (final n in near.take(3))
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(n.nameVi, style: TutorType.body()),
                trailing: Text('Lớp ${n.grade}', style: TutorType.caption()),
                onTap: busy
                    ? null
                    : () => _review(
                        it,
                        'rejected',
                        reason: skillWrongReason,
                        corrected: n.id,
                      ),
              ),
          ],
          Row(
            children: [
              TextButton(
                onPressed: busy
                    ? null
                    : () => _review(
                        it,
                        'rejected',
                        reason: 'Không phải lỗi kỹ năng',
                      ),
                child: const Text('Không phải lỗi kỹ năng nào'),
              ),
              TextButton(
                onPressed: busy
                    ? null
                    : () => setState(() => _picking.remove(it.id)),
                child: const Text('Quay lại'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _change(SkillReviewItem it) {
    final to = TopiLevel.parse(it.toLevel);
    final from = TopiLevel.parse(it.fromLevel);
    final toL = to == null ? it.toLevel : topiLevelLabel(to);
    if (it.firstSeen || from == null) return 'Mới: $toL';
    return '${topiLevelLabel(from)} → $toL';
  }

  static String _result(SkillReviewItem it) {
    if (it.isConfirmed) return '✓ Bạn xác nhận${it.star ? ' · tính sao' : ''}';
    if ((it.correctedNameVi ?? it.correctedNode) != null) {
      return '✎ Đã sửa thành: ${it.correctedNameVi ?? it.correctedNode}';
    }
    final r = (it.reason ?? '').trim();
    return r.isEmpty ? 'Đã bác · không tính' : 'Đã bác · $r';
  }

  static String _mmss(double sec) {
    final s = sec.floor();
    return '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  }

  /// Khoảng cách giữa hai mã nút "N8.03": cùng lớp và số gần nhau thì gần.
  static int _distance(String a, String b) {
    int? n(String id, int i) => int.tryParse(
      id.replaceAll('N', '').split('.').elementAtOrNull(i) ?? '',
    );
    final ga = n(a, 0);
    final gb = n(b, 0);
    final ia = n(a, 1);
    final ib = n(b, 1);
    if (ga == null || gb == null || ia == null || ib == null) return 999;
    return (ga - gb).abs() * 100 + (ia - ib).abs();
  }
}
