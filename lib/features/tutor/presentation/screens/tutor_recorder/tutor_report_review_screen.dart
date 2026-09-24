import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/features/tutor/data/datasources/app_recording_datasource.dart';
import 'package:tutora/features/tutor/data/models/app_recording_models.dart';
import 'package:tutora/features/tutor/data/models/recorder_models.dart';
import 'package:tutora/features/tutor/presentation/providers/recorder_provider.dart';
import 'package:tutora/features/tutor/presentation/widgets/ai_feedback_sheet.dart';

/// Tham số mở màn xem báo cáo.
class ReportReviewArgs {
  const ReportReviewArgs({
    required this.recordingId,
    this.studentName = '',
    this.subtitle = '',
  });

  final String recordingId;
  final String studentName;
  final String subtitle;
}

/// Giới hạn mỗi mục của tin Zalo gửi phụ huynh.
const _zaloMax = 200;

/// Giá trị đổ sẵn vào ô: tin Zalo AI viết; buổi cũ chưa có thì rút gọn bản dài.
String _prefill(String? zalo, String? long) {
  final z = (zalo ?? '').trim();
  return z.isNotEmpty ? z : _shortForZalo(long);
}

/// Rút gọn bản dài thành một mục ≤ [_zaloMax] ký tự: bỏ ký hiệu markdown và
/// gạch đầu dòng, gộp khoảng trắng, cắt ở cuối câu hoặc giữa hai từ.
String _shortForZalo(String? text) {
  final marker = RegExp(r'^(?:[-*•]|\d+\.)\s+');
  final flat = (text ?? '')
      .split('\n')
      .map((l) => l.trim().replaceFirst(marker, ''))
      .join(' ')
      .replaceAll(RegExp(r'[#*`$]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  final chars = flat.characters;
  if (chars.length <= _zaloMax) return flat;
  final head = chars.take(_zaloMax).toString();
  final end = head.lastIndexOf(RegExp('[.!?;]'));
  if (end >= 100) return head.substring(0, end + 1);
  final cut = chars.take(_zaloMax - 1).toString();
  final space = cut.lastIndexOf(' ');
  return '${(space > 0 ? cut.substring(0, space) : cut).trimRight()}…';
}

/// Màn "Nội dung buổi" (prototype Note): chờ AI → sửa → xem trước → gửi.
class TutorReportReviewScreen extends ConsumerStatefulWidget {
  const TutorReportReviewScreen({required this.args, super.key});

  final ReportReviewArgs args;

  @override
  ConsumerState<TutorReportReviewScreen> createState() =>
      _TutorReportReviewScreenState();
}

class _TutorReportReviewScreenState
    extends ConsumerState<TutorReportReviewScreen> {
  AppRecordingStatusDto? _status;
  Object? _loadError;
  Timer? _poll;

  final _content = TextEditingController();
  final _homework = TextEditingController();
  final _notes = TextEditingController();

  /// Đã đổ bản nháp AI vào ô chưa — chỉ đổ một lần, không đè chữ gia sư đã sửa.
  bool _filled = false;

  /// Gia sư tự viết khi AI hỏng.
  bool _manual = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
    _poll = Timer.periodic(const Duration(seconds: 4), (_) {
      final s = _status;
      if (s == null || s.isAiRunning || s.status == 'processing') {
        unawaited(_load());
      }
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _content.dispose();
    _homework.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final s = await ref
          .read(appRecordingDatasourceProvider)
          .status(widget.args.recordingId);
      if (!mounted) return;
      setState(() {
        _status = s;
        _loadError = null;
        if (!_filled && (s.isAwaitingApproval || s.isSent)) {
          _content.text = _prefill(s.zaloContent, s.lessonContent);
          _homework.text = _prefill(s.zaloHomework, s.homework);
          _notes.text = _prefill(s.zaloNotes, s.tutorNotes);
          _filled = true;
        }
      });
      if (!(s.isAiRunning || s.status == 'processing')) _poll?.cancel();
    } on Object catch (e) {
      if (mounted) setState(() => _loadError = e);
    }
  }

  String get _name {
    final n = _status?.studentName ?? '';
    return n.isNotEmpty ? n : widget.args.studentName;
  }

  void _openPreview() {
    final content = _content.text.trim();
    final homework = _homework.text.trim();
    final notes = _notes.text.trim();
    if (content.isEmpty) {
      _snack('Hãy viết nội dung buổi học trước khi gửi.');
      return;
    }
    if ([content, homework, notes].any((v) => v.characters.length > _zaloMax)) {
      _snack('Mỗi mục tối đa $_zaloMax ký tự.');
      return;
    }
    final s = _status!;
    unawaited(
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => _PreviewScreen(
            status: s,
            studentName: _name,
            subtitle: widget.args.subtitle,
            content: content,
            homework: homework,
            notes: notes,
          ),
        ),
      ),
    );
  }

  void _snack(String m) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(m), behavior: SnackBarBehavior.floating),
    );

  @override
  Widget build(BuildContext context) {
    final s = _status;
    final editable =
        s != null && (s.isAwaitingApproval || (_manual && s.isFailed));

    Widget body;
    if (s == null) {
      body = _loadError != null
          ? _StateCard.error(
              title: 'Không tải được báo cáo',
              text: 'Kiểm tra mạng rồi thử lại.',
              action: 'Thử lại',
              onAction: _load,
            )
          : const Padding(
              padding: EdgeInsets.only(top: 60),
              child: Center(child: CircularProgressIndicator()),
            );
    } else if (s.isSent) {
      body = _StateCard.done(
        title: 'Đã duyệt báo cáo',
        text: s.deliveryChannel == 'zns' && s.deliveryStatus != 'sent'
            ? 'Tin Zalo cho phụ huynh đang chờ gửi.'
            : 'Phụ huynh đã nhận báo cáo buổi này.',
      );
    } else if (s.isFailed && !_manual) {
      body = _StateCard.error(
        title: 'Chưa tạo được báo cáo',
        text:
            s.errorMessage ??
            'AI chưa xử lý được bản ghi. Bản ghi vẫn được giữ.',
        action: 'Tự viết báo cáo',
        onAction: () => setState(() => _manual = true),
      );
    } else if (!editable) {
      body = const _StateCard.pending();
    } else {
      body = _Editor(
        content: _content,
        homework: _homework,
        notes: _notes,
        aiWritten: !_manual,
      );
    }

    return Scaffold(
      backgroundColor: TutorColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                children: [
                  const _TitleBar(title: 'Nội dung buổi'),
                  const SizedBox(height: 20),
                  _InfoStrip(
                    name: _name,
                    subtitle: widget.args.subtitle,
                    durationSec: s?.durationSec ?? 0,
                  ),
                  const SizedBox(height: 20),
                  body,
                  // Nội dung do AI viết → cho gia sư báo sai (yêu cầu của Google Play).
                  if (s != null && ((editable && !_manual) || s.isSent)) ...[
                    const SizedBox(height: 12),
                    AiFeedbackButton(recordingId: widget.args.recordingId),
                  ],
                ],
              ),
            ),
            if (editable)
              _BottomBar(
                primary: 'Xem trước tin gửi phụ huynh',
                onPrimary: _openPreview,
                secondary: 'Để sau, gửi sau',
                onSecondary: () => Navigator.of(context).maybePop(),
              )
            else if (s != null && !s.isFailed)
              _BottomBar(
                primary: 'Về trang chủ',
                onPrimary: () => Navigator.of(context).maybePop(),
                outlined: true,
              ),
          ],
        ),
      ),
    );
  }
}

// ── Xem trước + gửi (prototype XemTruoc) ─────────────────────────────────────

class _PreviewScreen extends ConsumerStatefulWidget {
  const _PreviewScreen({
    required this.status,
    required this.studentName,
    required this.subtitle,
    required this.content,
    required this.homework,
    required this.notes,
  });

  final AppRecordingStatusDto status;
  final String studentName;
  final String subtitle;
  final String content;
  final String homework;
  final String notes;

  @override
  ConsumerState<_PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends ConsumerState<_PreviewScreen> {
  bool _sending = false;

  bool get _offPlatform => widget.status.studentId != null;

  Future<void> _send() async {
    setState(() => _sending = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final r = await ref
          .read(appRecordingDatasourceProvider)
          .approve(
            widget.status.recordingId,
            lessonContent: widget.content,
            homework: widget.homework.isEmpty ? null : widget.homework,
            tutorNotes: widget.notes.isEmpty ? null : widget.notes,
            zaloContent: widget.content,
            zaloHomework: widget.homework,
            zaloNotes: widget.notes,
          );
      ref.invalidate(recorderPendingReviewsProvider);
      if (r.studentId != null) {
        ref.invalidate(recorderStudentLessonsProvider(r.studentId!));
      }
      navigator.popUntil((route) => route.isFirst);
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            r.deliveryChannel == 'zns' && r.deliveryStatus != 'sent'
                ? 'Đã duyệt. Tin Zalo sẽ gửi cho phụ huynh khi kênh ZNS sẵn sàng.'
                : 'Đã gửi báo cáo cho phụ huynh.',
          ),
        ),
      );
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      final msg = e is DioException && e.response?.data is Map
          ? ((e.response!.data as Map)['message'] as String?)
          : null;
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(msg ?? 'Chưa gửi được. Kiểm tra mạng rồi thử lại.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    RecorderStudentDto? student;
    if (_offPlatform) {
      final list = ref.watch(recorderStudentsProvider).valueOrNull ?? const [];
      for (final s in list) {
        if (s.studentId == widget.status.studentId) student = s;
      }
    }
    final parentName = student?.parentName?.isNotEmpty ?? false
        ? student!.parentName!
        : 'Phụ huynh của ${widget.studentName}';
    final now = DateTime.now();
    final date =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: TutorColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                children: [
                  const _TitleBar(title: 'Xem trước'),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: TutorColors.surfaceSunken,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ZaloCard(
                          title: 'Báo cáo buổi học $date',
                          lines: [
                            (
                              'Học sinh',
                              [
                                widget.studentName,
                                widget.subtitle,
                              ].where((p) => p.isNotEmpty).join(' · '),
                            ),
                            ('Nội dung', widget.content),
                            (
                              'Bài tập',
                              widget.homework.isEmpty
                                  ? 'Không có'
                                  : widget.homework,
                            ),
                            (
                              'Ghi chú',
                              widget.notes.isEmpty ? 'Không có' : widget.notes,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 1),
                              child: Icon(
                                Icons.info_outline_rounded,
                                size: 14,
                                color: TutorColors.ink4,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Đây là những gì $parentName sẽ nhận trên Zalo.',
                                style: _t(
                                  12,
                                  FontWeight.w500,
                                  TutorColors.ink4,
                                  h: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _RecipientCard(
                    name: parentName,
                    phone: student?.parentPhone,
                    channel: _offPlatform
                        ? 'Gửi qua tin giao dịch Zalo OA'
                        : 'Gửi qua báo cáo buổi học trên Tutora',
                    showZalo:
                        _offPlatform &&
                        (student?.parentPhone?.isNotEmpty ?? false),
                  ),
                  if (_offPlatform &&
                      (student?.parentPhone?.isEmpty ?? true)) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Chưa có SĐT phụ huynh — báo cáo được lưu nhưng chưa gửi Zalo được. Thêm số trong hồ sơ học sinh.',
                      style: _t(
                        12,
                        FontWeight.w500,
                        TutorColors.primary,
                        h: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            _BottomBar(
              primary: _sending ? 'Đang gửi…' : 'Gửi cho phụ huynh',
              onPrimary: _sending ? null : _send,
              caption: 'Sửa và gửi lại được sau khi gửi',
            ),
          ],
        ),
      ),
    );
  }
}

// ── Mảnh giao diện ───────────────────────────────────────────────────────────

TextStyle _t(double size, FontWeight w, Color c, {double? h, double ls = 0}) =>
    TextStyle(
      fontSize: size,
      fontWeight: w,
      color: c,
      height: h,
      letterSpacing: ls,
    );

class _TitleBar extends StatelessWidget {
  const _TitleBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Semantics(
          button: true,
          label: 'Quay lại',
          child: Material(
            color: TutorColors.surface,
            shape: const CircleBorder(
              side: BorderSide(color: TutorColors.line),
            ),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.of(context).maybePop(),
              child: const SizedBox(
                width: 38,
                height: 38,
                child: Icon(
                  Icons.chevron_left_rounded,
                  size: 22,
                  color: TutorColors.ink,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(title, style: _t(26, FontWeight.w700, TutorColors.ink, ls: -0.5)),
      ],
    );
  }
}

class _InfoStrip extends StatelessWidget {
  const _InfoStrip({
    required this.name,
    required this.subtitle,
    required this.durationSec,
  });

  final String name;
  final String subtitle;
  final int durationSec;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final parts = [
      if (subtitle.isNotEmpty) subtitle,
      '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}',
      if (durationSec > 0) '${(durationSec / 60).round()} phút',
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: TutorColors.surfaceSunken,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _Avatar(name: name, size: 30),
          const SizedBox(width: 9),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: name,
                    style: _t(13, FontWeight.w600, TutorColors.ink),
                  ),
                  TextSpan(text: ' · ${parts.join(' · ')}'),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: _t(13, FontWeight.w400, TutorColors.ink3, h: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.name,
    this.size = 32,
    this.fontSize = 12,
    this.dark = false,
  });

  final String name;
  final double size;
  final double fontSize;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final t = name.trim();
    final initial = t.isEmpty
        ? '?'
        : t.split(' ').last.characters.first.toUpperCase();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: dark ? TutorColors.ink : TutorColors.surface,
        shape: BoxShape.circle,
        border: dark ? null : Border.all(color: TutorColors.line),
      ),
      child: Text(
        initial,
        style: _t(
          fontSize,
          FontWeight.w700,
          dark ? TutorColors.surface : TutorColors.ink,
        ),
      ),
    );
  }
}

class _Editor extends StatelessWidget {
  const _Editor({
    required this.content,
    required this.homework,
    required this.notes,
    required this.aiWritten,
  });

  final TextEditingController content;
  final TextEditingController homework;
  final TextEditingController notes;
  final bool aiWritten;

  @override
  Widget build(BuildContext context) {
    final title = _t(15, FontWeight.w700, TutorColors.ink, ls: -0.1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text('Nội dung buổi học', style: title)),
            if (aiWritten)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: TutorColors.accentBg,
                  border: Border.all(color: TutorColors.accentBorder),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.auto_awesome_outlined,
                      size: 11,
                      color: TutorColors.warning,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'AI viết sẵn',
                      style: _t(12, FontWeight.w500, TutorColors.warning),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'AI đã viết sẵn — bạn có thể sửa trước khi gửi. Phụ huynh nhận đúng '
          'nội dung này qua Zalo, mỗi mục tối đa $_zaloMax ký tự.',
          style: _t(12, FontWeight.w500, TutorColors.ink4, h: 1.3),
        ),
        const SizedBox(height: 10),
        _Field(controller: content, minLines: 4, label: 'Nội dung buổi học'),
        const SizedBox(height: 20),
        Text('Bài tập về nhà', style: title),
        const SizedBox(height: 10),
        _Field(controller: homework, minLines: 2, label: 'Bài tập về nhà'),
        const SizedBox(height: 20),
        Text('Nhận xét', style: title),
        const SizedBox(height: 10),
        _Field(controller: notes, minLines: 2, label: 'Nhận xét'),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.minLines,
    required this.label,
  });

  final TextEditingController controller;
  final int minLines;
  final String label;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: TutorColors.line),
    );
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: null,
      maxLength: _zaloMax,
      // Không cắt chữ AI viết dài hơn giới hạn — hiện bộ đếm đỏ để gia sư tự rút gọn.
      maxLengthEnforcement: MaxLengthEnforcement.none,
      keyboardType: TextInputType.multiline,
      textCapitalization: TextCapitalization.sentences,
      style: _t(15, FontWeight.w400, TutorColors.ink, h: 1.55),
      decoration: InputDecoration(
        filled: true,
        fillColor: TutorColors.surface,
        hintText: label,
        contentPadding: const EdgeInsets.all(15),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: TutorColors.ink, width: 1.2),
        ),
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard.pending()
    : title = 'Đang tạo báo cáo',
      text =
          'Bạn cứ đi, xong sẽ có thông báo. Thường mất 1–2 phút cho buổi 90 phút.',
      action = null,
      onAction = null,
      tone = _Tone.pending;

  const _StateCard.error({
    required this.title,
    required this.text,
    this.action,
    this.onAction,
  }) : tone = _Tone.error;

  const _StateCard.done({required this.title, required this.text})
    : action = null,
      onAction = null,
      tone = _Tone.done;

  final String title;
  final String text;
  final String? action;
  final VoidCallback? onAction;
  final _Tone tone;

  @override
  Widget build(BuildContext context) {
    final (bg, border, fg, icon) = switch (tone) {
      _Tone.pending => (
        TutorColors.surfaceSunken,
        Colors.transparent,
        TutorColors.ink,
        Icons.auto_awesome_outlined,
      ),
      _Tone.error => (
        TutorColors.primaryBg,
        TutorColors.primaryBorder,
        TutorColors.primary,
        Icons.error_outline_rounded,
      ),
      _Tone.done => (
        TutorColors.successBg,
        TutorColors.successBorder,
        TutorColors.success,
        Icons.check_circle_outline_rounded,
      ),
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 17,
                color: tone == _Tone.pending ? TutorColors.warning : fg,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: _t(13, FontWeight.w600, fg))),
              if (tone == _Tone.pending)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: TutorColors.warning,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            text,
            style: _t(
              12,
              FontWeight.w500,
              tone == _Tone.pending ? TutorColors.ink3 : fg,
              h: 1.4,
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 36,
              child: FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  backgroundColor: TutorColors.primary,
                  foregroundColor: TutorColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  action!,
                  style: _t(13.5, FontWeight.w600, TutorColors.surface),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

enum _Tone { pending, error, done }

class _ZaloCard extends StatelessWidget {
  const _ZaloCard({required this.title, required this.lines});

  final String title;
  final List<(String, String)> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: TutorColors.surface,
        border: Border.all(color: TutorColors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: TutorColors.line)),
            ),
            child: Row(
              children: [
                const _Avatar(name: 'T', size: 26, fontSize: 11, dark: true),
                const SizedBox(width: 9),
                Text('Tutora', style: _t(13, FontWeight.w600, TutorColors.ink)),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: TutorColors.surfaceSunken,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Official Account',
                    style: _t(12, FontWeight.w500, TutorColors.ink4),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: _t(15, FontWeight.w600, TutorColors.ink, ls: -0.1),
                ),
                const SizedBox(height: 11),
                for (final (k, v) in lines) ...[
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '$k: ',
                          style: _t(13, FontWeight.w400, TutorColors.ink4),
                        ),
                        TextSpan(text: v),
                      ],
                    ),
                    style: _t(13, FontWeight.w400, TutorColors.ink3, h: 1.45),
                  ),
                  const SizedBox(height: 7),
                ],
                const SizedBox(height: 4),
                const Divider(height: 1, color: TutorColors.line),
                const SizedBox(height: 11),
                Text(
                  'Xem thông tin Tutora',
                  style: _t(13, FontWeight.w600, TutorColors.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecipientCard extends StatelessWidget {
  const _RecipientCard({
    required this.name,
    required this.channel,
    this.phone,
    this.showZalo = false,
  });

  final String name;
  final String? phone;
  final String channel;
  final bool showZalo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TutorColors.surface,
        border: Border.all(color: TutorColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _Avatar(name: name),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: _t(15, FontWeight.w600, TutorColors.ink, ls: -0.1),
                    ),
                    Text(
                      phone == null || phone!.isEmpty
                          ? 'Phụ huynh'
                          : 'Phụ huynh · $phone',
                      style: _t(13, FontWeight.w400, TutorColors.ink3, h: 1.35),
                    ),
                  ],
                ),
              ),
              if (showZalo)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: TutorColors.successBg,
                    border: Border.all(color: TutorColors.successBorder),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_rounded,
                        size: 12,
                        color: TutorColors.success,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Zalo',
                        style: _t(12, FontWeight.w500, TutorColors.success),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: TutorColors.line),
          const SizedBox(height: 12),
          Text(
            channel,
            style: _t(12, FontWeight.w500, TutorColors.ink4, h: 1.3),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.primary,
    required this.onPrimary,
    this.secondary,
    this.onSecondary,
    this.caption,
    this.outlined = false,
  });

  final String primary;
  final VoidCallback? onPrimary;
  final String? secondary;
  final VoidCallback? onSecondary;
  final String? caption;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      decoration: const BoxDecoration(
        color: TutorColors.bg,
        border: Border(top: BorderSide(color: TutorColors.line)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 52,
            child: outlined
                ? OutlinedButton(
                    onPressed: onPrimary,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 52),
                      shape: shape,
                      side: const BorderSide(color: TutorColors.line),
                    ),
                    child: Text(
                      primary,
                      style: _t(13.5, FontWeight.w600, TutorColors.ink),
                    ),
                  )
                : FilledButton(
                    onPressed: onPrimary,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 52),
                      backgroundColor: TutorColors.primary,
                      disabledBackgroundColor: TutorColors.primary.withValues(
                        alpha: 0.5,
                      ),
                      shape: shape,
                    ),
                    child: Text(
                      primary,
                      style: _t(13.5, FontWeight.w600, TutorColors.surface),
                    ),
                  ),
          ),
          if (secondary != null) ...[
            const SizedBox(height: 6),
            SizedBox(
              height: 40,
              child: TextButton(
                onPressed: onSecondary,
                style: TextButton.styleFrom(minimumSize: const Size(0, 40)),
                child: Text(
                  secondary!,
                  style: _t(13.5, FontWeight.w600, TutorColors.ink3),
                ),
              ),
            ),
          ],
          if (caption != null) ...[
            const SizedBox(height: 9),
            Text(
              caption!,
              textAlign: TextAlign.center,
              style: _t(12, FontWeight.w500, TutorColors.ink4, h: 1.3),
            ),
          ],
        ],
      ),
    );
  }
}
