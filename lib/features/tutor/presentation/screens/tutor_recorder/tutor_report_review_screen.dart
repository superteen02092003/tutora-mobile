import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/core/theme/tutor_design.dart';
import 'package:tutora/features/tutor/data/datasources/app_recording_datasource.dart';
import 'package:tutora/features/tutor/data/models/app_recording_models.dart';
import 'package:tutora/features/tutor/data/models/recorder_models.dart';
import 'package:tutora/features/tutor/presentation/providers/recorder_provider.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_recorder/topi_before_lesson_screen.dart';
import 'package:tutora/features/tutor/presentation/widgets/ai_feedback_sheet.dart';
import 'package:tutora/features/tutor/presentation/widgets/canvas_ui.dart';
import 'package:tutora/features/tutor/presentation/widgets/lesson_insights_card.dart';
import 'package:tutora/features/tutor/presentation/widgets/topi_tips_card.dart';

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

String _dm(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

String _hm(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// Màn "Báo cáo của …" (V5.6 board V56-Review): chờ AI → sửa → xem trước → gửi.
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

  /// Bản nháp AI lúc đổ vào ô — chỉ để hiện "Bạn đã sửa" khi chữ khác đi.
  final _drafts = <TextEditingController, String>{};

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
          for (final c in [_content, _homework, _notes]) {
            _drafts[c] = c.text;
          }
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
            aiDrafted: !_manual,
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
    final sent = s != null && s.isSent;

    Widget body;
    String? kicker;
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
              child: Center(
                child: CircularProgressIndicator(color: TutorColors.ink),
              ),
            );
    } else if (s.isSent) {
      body = _SentState(
        status: s,
        name: _name,
        text: s.deliveryChannel == 'zns' && s.deliveryStatus != 'sent'
            ? 'Tin Zalo cho phụ huynh đang chờ gửi.'
            : 'Phụ huynh đã nhận báo cáo buổi này.',
      );
    } else if (s.isFailed && !_manual) {
      kicker = 'Chưa có báo cáo';
      body = _StateCard.error(
        title: 'Chưa tạo được báo cáo',
        text:
            s.errorMessage ??
            'AI chưa xử lý được bản ghi. Bản ghi vẫn được giữ.',
        action: 'Tự viết báo cáo',
        onAction: () => setState(() => _manual = true),
      );
    } else if (!editable) {
      kicker = 'AI đang viết';
      body = const _StateCard.pending();
    } else {
      kicker = _manual ? 'Bạn tự viết' : 'Cần bạn duyệt';
      body = _Editor(
        content: _content,
        homework: _homework,
        notes: _notes,
        drafts: _drafts,
        aiWritten: !_manual,
      );
    }

    return Scaffold(
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
                  children: [
                    _TopBar(right: editable ? 'Bước 1/2' : null),
                    if (!sent) ...[
                      const SizedBox(height: 16),
                      _Heading(
                        kicker: kicker,
                        title: _name.isEmpty
                            ? 'Nội dung buổi'
                            : 'Báo cáo của $_name',
                        meta: _meta(s?.durationSec ?? 0),
                      ),
                    ],
                    SizedBox(height: sent ? 30 : 18),
                    body,
                    // Nội dung do AI viết → cho gia sư báo sai (yêu cầu của Google Play).
                    if (s != null && ((editable && !_manual) || s.isSent)) ...[
                      const SizedBox(height: 8),
                      AiFeedbackButton(recordingId: widget.args.recordingId),
                    ],
                    // V56-Review "Kế hoạch buổi sau" → T9; tự ẩn khi cờ `plan`
                    // tắt hoặc chưa có kế hoạch.
                    TopiNextPlanRow(
                      args: BeforeLessonArgs(
                        lessonId: widget.args.recordingId,
                        studentName: _name,
                      ),
                      padding: const EdgeInsets.only(top: 12),
                    ),
                    // Topi T13 "Dành cho bạn" — tự ẩn khi cờ `tips` tắt.
                    TopiTipsCard(lessonId: widget.args.recordingId),
                    // Số liệu đo từ bản ghi — cũng chỉ gia sư thấy; tự ẩn khi
                    // chưa có.
                    LessonInsightsCard(
                      lessonId: widget.args.recordingId,
                      kicker: 'Buổi học qua bản ghi · chỉ bạn thấy',
                      padding: const EdgeInsets.only(top: 20),
                    ),
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
                  outlined: !s.isSent,
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// "Toán · Lớp 8 · 09/11 · 86 phút".
  String _meta(int durationSec) => [
    if (widget.args.subtitle.isNotEmpty) widget.args.subtitle,
    _dm(DateTime.now()),
    if (durationSec > 0) '${(durationSec / 60).round()} phút',
  ].join(' · ');
}

// ── Xem trước + gửi (bước 2) ─────────────────────────────────────────────────

class _PreviewScreen extends ConsumerStatefulWidget {
  const _PreviewScreen({
    required this.status,
    required this.studentName,
    required this.subtitle,
    required this.content,
    required this.homework,
    required this.notes,
    required this.aiDrafted,
  });

  final AppRecordingStatusDto status;
  final String studentName;
  final String subtitle;
  final String content;
  final String homework;
  final String notes;

  /// Bản do AI soạn (không phải gia sư tự viết) → gắn nhãn "Nháp AI".
  final bool aiDrafted;

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
    final date = _dm(DateTime.now());

    return Scaffold(
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
                  children: [
                    const _TopBar(right: 'Bước 2/2'),
                    const SizedBox(height: 16),
                    _Heading(
                      kicker: 'Xem trước tin gửi phụ huynh',
                      title: 'Phụ huynh nhận được',
                      meta: 'Đây là những gì $parentName sẽ nhận trên Zalo.',
                    ),
                    const SizedBox(height: 18),
                    _ZaloCard(
                      title: 'Báo cáo buổi học $date',
                      aiDrafted: widget.aiDrafted,
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
                    const SizedBox(height: 22),
                    Text('Người nhận', style: TutorType.sectionTitle()),
                    const SizedBox(height: 10),
                    _RecipientCard(
                      name: parentName,
                      phone: student?.parentPhone,
                      channel: _offPlatform
                          ? 'Gửi qua tin giao dịch Zalo OA'
                          : 'Gửi qua báo cáo buổi học trên TopTutor',
                      showZalo:
                          _offPlatform &&
                          (student?.parentPhone?.isNotEmpty ?? false),
                    ),
                    if (_offPlatform &&
                        (student?.parentPhone?.isEmpty ?? true)) ...[
                      const SizedBox(height: 12),
                      const _Notice(
                        'Chưa có SĐT phụ huynh — báo cáo được lưu nhưng chưa gửi Zalo được. Thêm số trong hồ sơ học sinh.',
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
      ),
    );
  }
}

// ── Mảnh giao diện ───────────────────────────────────────────────────────────

/// Hàng đầu màn: nút tròn quay lại, nhãn bước bên phải.
class _TopBar extends StatelessWidget {
  const _TopBar({this.right});

  final String? right;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      CanvasBackButton(onTap: () => Navigator.of(context).maybePop()),
      const Spacer(),
      if (right != null) Text(right!, style: TutorType.rowSub()),
    ],
  );
}

/// Nhãn nhỏ · tiêu đề Bricolage · dòng phụ.
class _Heading extends StatelessWidget {
  const _Heading({required this.title, this.kicker, this.meta});

  final String? kicker;
  final String title;
  final String? meta;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (kicker != null) ...[
        Text(kicker!, style: TutorType.caption(color: TutorColors.ink3)),
        const SizedBox(height: 4),
      ],
      Text(title, style: TutorType.display(size: 26)),
      if (meta != null && meta!.isNotEmpty) ...[
        const SizedBox(height: 6),
        Text(meta!, style: TutorType.rowSub()),
      ],
    ],
  );
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.name,
    this.size = 38,
    this.fontSize = 13,
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
        color: dark ? TutorColors.ink : TutorColors.surfaceSunken,
        shape: BoxShape.circle,
      ),
      child: Text(
        initial,
        style: TutorType.action(
          color: dark ? Colors.white : TutorColors.ink,
        ).copyWith(fontSize: fontSize, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Nhãn sage "✓ Bạn đã sửa" khi gia sư đã đổi bản nháp AI.
class _EditedChip extends StatelessWidget {
  const _EditedChip();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: TutorColors.sage,
      borderRadius: BorderRadius.circular(11),
    ),
    child: Text(
      '✓ Bạn đã sửa',
      style: TutorType.caption(
        color: TutorColors.ink,
      ).copyWith(fontSize: 11.5, height: 1),
    ),
  );
}

class _Editor extends StatelessWidget {
  const _Editor({
    required this.content,
    required this.homework,
    required this.notes,
    required this.drafts,
    required this.aiWritten,
  });

  final TextEditingController content;
  final TextEditingController homework;
  final TextEditingController notes;
  final Map<TextEditingController, String> drafts;
  final bool aiWritten;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          aiWritten
              ? 'AI đã viết sẵn — bạn có thể sửa trước khi gửi. Phụ huynh nhận '
                    'đúng nội dung này qua Zalo, mỗi mục tối đa $_zaloMax ký tự.'
              : 'Phụ huynh nhận đúng nội dung này qua Zalo, mỗi mục tối đa '
                    '$_zaloMax ký tự.',
          style: TutorType.rowSub(),
        ),
        const SizedBox(height: 14),
        _FieldCard(
          heading: 'Nội dung buổi học',
          controller: content,
          draft: aiWritten ? drafts[content] : null,
          minLines: 4,
          label: 'Nội dung buổi học',
        ),
        const SizedBox(height: 12),
        _FieldCard(
          heading: 'Bài tập về nhà',
          controller: homework,
          draft: aiWritten ? drafts[homework] : null,
          minLines: 2,
          label: 'Bài tập về nhà',
        ),
        const SizedBox(height: 12),
        _FieldCard(
          heading: 'Nhận xét của bạn',
          controller: notes,
          draft: aiWritten ? drafts[notes] : null,
          minLines: 2,
          label: 'Nhận xét',
        ),
      ],
    );
  }
}

/// Thẻ mức 1: nhãn + "Nháp AI" (hoặc "Bạn đã sửa") + ô sửa không viền.
class _FieldCard extends StatelessWidget {
  const _FieldCard({
    required this.heading,
    required this.controller,
    required this.minLines,
    required this.label,
    this.draft,
  });

  final String heading;
  final TextEditingController controller;
  final int minLines;
  final String label;

  /// Bản nháp AI ban đầu; null khi gia sư tự viết (không gắn nhãn).
  final String? draft;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
    decoration: TutorSurface.card(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                heading,
                style: TutorType.caption(color: TutorColors.ink3),
              ),
            ),
            if (draft != null)
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (_, v, _) => v.text.trim() != draft!.trim()
                    ? const _EditedChip()
                    : const CanvasAiDraftTag(),
              ),
          ],
        ),
        const SizedBox(height: 8),
        _Field(controller: controller, minLines: minLines, label: label),
      ],
    ),
  );
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
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: null,
      maxLength: _zaloMax,
      // Không cắt chữ AI viết dài hơn giới hạn — hiện bộ đếm đỏ để gia sư tự rút gọn.
      maxLengthEnforcement: MaxLengthEnforcement.none,
      keyboardType: TextInputType.multiline,
      textCapitalization: TextCapitalization.sentences,
      cursorColor: TutorColors.ink,
      style: TutorType.body(),
      decoration: InputDecoration(
        isDense: true,
        filled: false,
        hintText: label,
        hintStyle: TutorType.body(color: TutorColors.ink4),
        counterStyle: TutorType.caption(),
        contentPadding: EdgeInsets.zero,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
      ),
    );
  }
}

/// Trạng thái chờ AI / lỗi: thẻ mức 1, ô biểu tượng, chữ, nút viên thuốc.
class _StateCard extends StatelessWidget {
  const _StateCard.pending()
    : title = 'Đang tạo báo cáo',
      text =
          'Bạn cứ đi, xong sẽ có thông báo. Thường mất 1–2 phút cho buổi 90 phút.',
      action = null,
      onAction = null,
      pending = true;

  const _StateCard.error({
    required this.title,
    required this.text,
    this.action,
    this.onAction,
  }) : pending = false;

  final String title;
  final String text;
  final String? action;
  final VoidCallback? onAction;
  final bool pending;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: TutorSurface.card(),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: TutorSurface.well(),
                child: pending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.8,
                          color: TutorColors.ink,
                        ),
                      )
                    : const Icon(
                        Icons.error_outline_rounded,
                        size: 18,
                        color: TutorColors.ink,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TutorType.rowTitle()),
                    const SizedBox(height: 2),
                    Text(text, style: TutorType.rowSub()),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (action != null) ...[
          const SizedBox(height: 14),
          CanvasCta(label: action!, onPressed: onAction),
        ],
        if (pending) ...[
          const SizedBox(height: 26),
          const Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: EdgeInsets.only(right: 8),
              child: CanvasHand('Nghỉ chút đã nhé', size: 18),
            ),
          ),
        ],
      ],
    );
  }
}

/// Đã duyệt (board V56-Sent): vòng tích, tiêu đề lớn, thẻ khoá–giá trị.
class _SentState extends StatelessWidget {
  const _SentState({
    required this.status,
    required this.name,
    required this.text,
  });

  final AppRecordingStatusDto status;
  final String name;
  final String text;

  @override
  Widget build(BuildContext context) {
    final s = status;
    final day = s.startedAt ?? s.scheduledStart;
    final channel = switch (s.deliveryChannel) {
      'zns' => 'Zalo',
      'booking' => 'TopTutor',
      _ => null,
    };
    final delivery = switch (s.deliveryStatus) {
      'sent' => 'Đã gửi',
      'pending' => 'Đang chờ gửi',
      'failed' => 'Chưa gửi được',
      _ => null,
    };
    final rows = <(String, String)>[
      (
        day == null ? 'Báo cáo buổi học' : 'Báo cáo buổi ${_dm(day)}',
        'Đã duyệt',
      ),
      if (name.isNotEmpty) ('Học sinh', name),
      if (channel != null) ('Kênh', channel),
      if (delivery != null) ('Trạng thái gửi', delivery),
      if (s.approvedAt != null)
        ('Duyệt lúc', '${_hm(s.approvedAt!)} · ${_dm(s.approvedAt!)}'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: TutorColors.ink,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 22,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Đã duyệt báo cáo',
          style: TutorType.display(size: 32, height: 1.05),
        ),
        const SizedBox(height: 8),
        Text(text, style: TutorType.rowSub()),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: TutorSurface.card(),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++)
                _KvRow(label: rows[i].$1, value: rows[i].$2, first: i == 0),
            ],
          ),
        ),
        const SizedBox(height: 26),
        const Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: EdgeInsets.only(right: 8),
            child: CanvasHand('Xong một buổi rồi!'),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

/// Hàng "Nhãn ...... giá trị" có kẻ mảnh phía trên (trừ hàng đầu).
class _KvRow extends StatelessWidget {
  const _KvRow({required this.label, required this.value, this.first = false});

  final String label;
  final String value;
  final bool first;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 11),
    decoration: BoxDecoration(
      border: Border(top: first ? BorderSide.none : TutorSurface.rule),
    ),
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
          value,
          style: TutorType.rowTitle().copyWith(fontSize: 13.5),
        ),
      ],
    ),
  );
}

/// Ô nhắc trung tính (không phải mẹo nên không có bóng đèn).
class _Notice extends StatelessWidget {
  const _Notice(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: TutorColors.sage,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 1),
          child: Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: TutorColors.ink,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: TutorType.rowSub(color: TutorColors.ink)),
        ),
      ],
    ),
  );
}

/// Bản xem trước tin Zalo OA — thẻ mức 1.
class _ZaloCard extends StatelessWidget {
  const _ZaloCard({
    required this.title,
    required this.lines,
    required this.aiDrafted,
  });

  final String title;
  final List<(String, String)> lines;
  final bool aiDrafted;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: TutorSurface.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              border: Border(bottom: TutorSurface.rule),
            ),
            child: Row(
              children: [
                const _Avatar(name: 'T', size: 26, fontSize: 11, dark: true),
                const SizedBox(width: 9),
                Text('TopTutor', style: TutorType.action()),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Official Account',
                    overflow: TextOverflow.ellipsis,
                    style: TutorType.caption(),
                  ),
                ),
                const Spacer(),
                if (aiDrafted) const CanvasAiDraftTag(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title, style: TutorType.body()),
                const SizedBox(height: 10),
                for (final (k, v) in lines) ...[
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '$k: ',
                          style: TutorType.rowSub(color: TutorColors.ink4),
                        ),
                        TextSpan(text: v),
                      ],
                    ),
                    style: TutorType.rowSub(color: TutorColors.ink),
                  ),
                  const SizedBox(height: 7),
                ],
                const SizedBox(height: 4),
                const Divider(height: 1, color: TutorColors.line),
                const SizedBox(height: 11),
                Text(
                  'Xem thông tin TopTutor',
                  style: TutorType.rowSub(
                    color: TutorColors.ink,
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
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: TutorSurface.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _Avatar(name: name),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: TutorType.rowTitle()),
                    Text(
                      phone == null || phone!.isEmpty
                          ? 'Phụ huynh'
                          : 'Phụ huynh · $phone',
                      style: TutorType.rowSub(),
                    ),
                  ],
                ),
              ),
              if (showZalo) const CanvasTag('✓ Zalo'),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: TutorColors.line),
          const SizedBox(height: 10),
          Text(channel, style: TutorType.caption(color: TutorColors.ink3)),
        ],
      ),
    );
  }
}

/// Thanh dưới: nút viên thuốc chính (hoặc sage), liên kết chữ phụ, chú thích.
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

  /// Nút phụ (nền sage) thay cho nút chính xanh rêu.
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TutorSurface.gutter,
        10,
        TutorSurface.gutter,
        16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CanvasCta(label: primary, onPressed: onPrimary, secondary: outlined),
          if (secondary != null && onSecondary != null) ...[
            const SizedBox(height: 4),
            CanvasGhostLink(label: secondary!, onTap: onSecondary!),
          ],
          if (caption != null) ...[
            const SizedBox(height: 10),
            Text(
              caption!,
              textAlign: TextAlign.center,
              style: TutorType.caption(color: TutorColors.ink3),
            ),
          ],
        ],
      ),
    );
  }
}
