import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/core/theme/tutor_design.dart';
import 'package:tutora/features/tutor/data/models/recorder_insights_models.dart';
import 'package:tutora/features/tutor/data/models/recorder_models.dart';
import 'package:tutora/features/tutor/data/models/tutor_lesson_models.dart';
import 'package:tutora/features/tutor/presentation/providers/recorder_insights_provider.dart';
import 'package:tutora/features/tutor/presentation/providers/recorder_provider.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_schedule/lesson_attendance.dart';
import 'package:tutora/features/tutor/presentation/widgets/canvas_ui.dart';
import 'package:tutora/shared/widgets/app_toast.dart';

// Đổi lịch một buổi (board V56-QuickLog "Sửa buổi học"):
// - buổi recorder → dời ngay (`moveLesson`), có "Áp dụng cho" khi buổi thuộc
//   lịch hằng tuần;
// - buổi booking → gửi đề xuất đổi lịch, phụ huynh phải đồng ý.

/// Kết quả người dùng chọn trong [LessonMoveSheet].
class LessonMoveChoice {
  const LessonMoveChoice({
    required this.start,
    required this.end,
    this.scope = RecorderMoveScope.thisLesson,
    this.reason,
  });

  final DateTime start;
  final DateTime end;
  final RecorderMoveScope scope;

  /// Lý do (chỉ đề xuất đổi lịch buổi booking).
  final String? reason;
}

/// Thời gian tối thiểu trước giờ học để đề xuất đổi lịch buổi booking.
const bookedRescheduleLead = Duration(hours: 2);

const _weekdays = [
  'Thứ Hai',
  'Thứ Ba',
  'Thứ Tư',
  'Thứ Năm',
  'Thứ Sáu',
  'Thứ Bảy',
  'Chủ Nhật',
];

String _two(int n) => n.toString().padLeft(2, '0');
String _hm(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}';
String _hmTod(TimeOfDay t) => '${_two(t.hour)}:${_two(t.minute)}';
String _dayText(DateTime d) =>
    '${_weekdays[d.weekday - 1]} ${d.day}/${d.month}';

String _duration(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return '$m phút';
  return m == 0 ? '$h giờ' : '$h giờ $m phút';
}

/// Form đổi lịch: ngày, giờ bắt đầu / kết thúc, phạm vi (khi buổi thuộc lịch
/// hằng tuần). [onSubmit] trả về true khi lưu xong → sheet tự đóng với `true`.
class LessonMoveSheet extends StatefulWidget {
  const LessonMoveSheet({
    required this.studentName,
    required this.start,
    required this.end,
    required this.onSubmit,
    this.subtitle = '',
    this.weekly = false,
    this.proposal = false,
    this.now,
    super.key,
  });

  final String studentName;
  final String subtitle;

  /// Giờ hiện tại của buổi.
  final DateTime start;
  final DateTime end;

  /// Buổi sinh ra từ lịch hằng tuần → hiện "Áp dụng cho".
  final bool weekly;

  /// Buổi booking: chỉ gửi đề xuất (giữ nguyên thời lượng, có ô lý do).
  final bool proposal;

  final Future<bool> Function(LessonMoveChoice choice) onSubmit;

  /// Đồng hồ (để test).
  final DateTime Function()? now;

  @override
  State<LessonMoveSheet> createState() => _LessonMoveSheetState();
}

class _LessonMoveSheetState extends State<LessonMoveSheet> {
  late DateTime _day = DateTime(
    widget.start.year,
    widget.start.month,
    widget.start.day,
  );
  late TimeOfDay _from = TimeOfDay.fromDateTime(widget.start);
  late TimeOfDay _to = TimeOfDay.fromDateTime(widget.end);
  RecorderMoveScope _scope = RecorderMoveScope.thisLesson;
  final _reason = TextEditingController();
  String? _error;
  bool _busy = false;

  DateTime _at(TimeOfDay t) =>
      DateTime(_day.year, _day.month, _day.day, t.hour, t.minute);

  int get _minutes => widget.end.difference(widget.start).inMinutes;

  DateTime get _start => _at(_from);

  /// Đề xuất: giữ nguyên thời lượng buổi.
  DateTime get _end =>
      widget.proposal ? _start.add(Duration(minutes: _minutes)) : _at(_to);

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _pickDay() async {
    final today = DateUtils.dateOnly((widget.now ?? DateTime.now)());
    final picked = await showDatePicker(
      context: context,
      initialDate: _day.isBefore(today) ? today : _day,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      helpText: 'Chọn ngày học',
      cancelText: 'Thôi',
      confirmText: 'Chọn',
    );
    if (picked != null) {
      setState(() {
        _day = picked;
        _error = null;
      });
    }
  }

  Future<void> _pickTime({required bool start}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: start ? _from : _to,
      helpText: start ? 'Giờ bắt đầu' : 'Giờ kết thúc',
      cancelText: 'Thôi',
      confirmText: 'Chọn',
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      _error = null;
      if (start) {
        // Đổi giờ bắt đầu → giữ nguyên thời lượng.
        final len = _at(_to).difference(_at(_from));
        _from = picked;
        if (len.inMinutes > 0) {
          final e = _at(_from).add(len);
          _to = TimeOfDay(hour: e.hour, minute: e.minute);
        }
      } else {
        _to = picked;
      }
    });
  }

  String? _validate() {
    final now = (widget.now ?? DateTime.now)();
    final start = _start;
    final end = _end;
    if (!end.isAfter(start)) return 'Giờ kết thúc phải sau giờ bắt đầu.';
    if (end.day != start.day) return 'Buổi học phải kết thúc trong ngày.';
    if (!start.isAfter(now)) return 'Chọn một thời điểm chưa qua.';
    if (start == widget.start &&
        end == widget.end &&
        _scope == RecorderMoveScope.thisLesson) {
      return 'Chọn ngày hoặc giờ khác với hiện tại.';
    }
    return null;
  }

  Future<void> _save() async {
    if (_busy) return;
    final error = _validate();
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = await widget.onSubmit(
      LessonMoveChoice(
        start: _start,
        end: _end,
        scope: widget.weekly ? _scope : RecorderMoveScope.thisLesson,
        reason: widget.proposal ? _reason.text.trim() : null,
      ),
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final origDay = DateUtils.dateOnly(widget.start);
    final dayChanged = _day != origDay;
    final start = _start;
    final end = _end;
    final len = end.difference(start).inMinutes;
    final initial = widget.studentName.trim().isEmpty
        ? '?'
        : widget.studentName.trim()[0].toUpperCase();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SheetHandle(),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.proposal
                          ? 'Đề xuất đổi lịch'
                          : 'Đổi lịch buổi học',
                      style: TutorType.display(size: 20),
                    ),
                  ),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => Navigator.of(context).pop(false),
                    child: Text('Huỷ', style: TutorType.rowSub()),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Học sinh', style: TutorType.caption()),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBFAF7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: TutorColors.surfaceSunken,
                        shape: BoxShape.circle,
                      ),
                      child: Text(initial, style: TutorType.rowTitle()),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.studentName, style: TutorType.body()),
                          Text(
                            [
                              if (widget.subtitle.isNotEmpty) widget.subtitle,
                              'học 1-1',
                            ].join(' · '),
                            style: TutorType.rowSub(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBFAF7),
                  borderRadius: BorderRadius.circular(TutorSurface.radius),
                ),
                child: Column(
                  children: [
                    _KvRow(
                      key: const Key('move-date'),
                      label: 'Ngày',
                      value: dayChanged
                          ? '${_dayText(origDay)} → ${_dayText(_day)}'
                          : _dayText(_day),
                      strong: dayChanged,
                      first: true,
                      onTap: _busy ? null : _pickDay,
                    ),
                    _KvRow(
                      key: const Key('move-start'),
                      label: 'Bắt đầu',
                      value: _hmTod(_from),
                      onTap: _busy ? null : () => _pickTime(start: true),
                    ),
                    _KvRow(
                      key: const Key('move-end'),
                      label: 'Kết thúc',
                      value: len > 0
                          ? '${_hm(end)} · ${_duration(len)}'
                          : _hm(end),
                      onTap: widget.proposal || _busy
                          ? null
                          : () => _pickTime(start: false),
                    ),
                  ],
                ),
              ),
              if (widget.weekly && !widget.proposal) ...[
                const SizedBox(height: 14),
                Text(
                  'Buổi này nằm trong lịch lặp. Áp dụng cho:',
                  style: TutorType.caption(),
                ),
                const SizedBox(height: 6),
                _ScopeOption(
                  key: const Key('move-scope-this'),
                  label: 'Chỉ buổi này',
                  selected: _scope == RecorderMoveScope.thisLesson,
                  onTap: () =>
                      setState(() => _scope = RecorderMoveScope.thisLesson),
                ),
                const SizedBox(height: 6),
                _ScopeOption(
                  key: const Key('move-scope-following'),
                  label: 'Buổi này và các buổi sau',
                  selected: _scope == RecorderMoveScope.following,
                  onTap: () =>
                      setState(() => _scope = RecorderMoveScope.following),
                ),
              ],
              if (widget.proposal) ...[
                const SizedBox(height: 14),
                TextField(
                  key: const Key('move-reason'),
                  controller: _reason,
                  maxLength: 300,
                  maxLines: 2,
                  minLines: 1,
                  decoration: const InputDecoration(
                    labelText: 'Lý do (không bắt buộc)',
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Phụ huynh cần đồng ý. Lịch chỉ đổi khi phụ huynh chấp nhận '
                  'đề xuất.',
                  style: TutorType.caption(),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  key: const Key('move-error'),
                  style: TutorType.rowSub(color: TutorColors.danger),
                ),
              ],
              const SizedBox(height: 18),
              CanvasCta(
                key: const Key('move-save'),
                label: _busy
                    ? 'Đang lưu…'
                    : widget.proposal
                    ? 'Gửi đề xuất'
                    : 'Lưu thay đổi',
                onPressed: _busy ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KvRow extends StatelessWidget {
  const _KvRow({
    required this.label,
    required this.value,
    this.onTap,
    this.strong = false,
    this.first = false,
    super.key,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool strong;
  final bool first;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      constraints: const BoxConstraints(minHeight: 46),
      decoration: BoxDecoration(
        border: Border(top: first ? BorderSide.none : TutorSurface.rule),
      ),
      child: Row(
        children: [
          Text(label, style: TutorType.rowSub()),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TutorType.rowTitle().copyWith(
                fontWeight: strong ? FontWeight.w600 : null,
              ),
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 4),
            const CanvasChevron(),
          ],
        ],
      ),
    ),
  );
}

class _ScopeOption extends StatelessWidget {
  const _ScopeOption({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: Material(
      color: selected ? TutorColors.sage : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: selected
            ? BorderSide.none
            : const BorderSide(color: TutorColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? Colors.white : null,
                  border: Border.all(
                    color: selected ? TutorColors.ink : const Color(0xFFA3A8A2),
                    width: selected ? 5 : 1.6,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(label, style: TutorType.body())),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Mở [LessonMoveSheet]. Trả về true khi đã lưu.
Future<bool> showLessonMoveSheet(
  BuildContext context, {
  required String studentName,
  required DateTime start,
  required DateTime end,
  required Future<bool> Function(LessonMoveChoice) onSubmit,
  String subtitle = '',
  bool weekly = false,
  bool proposal = false,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: TutorColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => LessonMoveSheet(
      studentName: studentName,
      subtitle: subtitle,
      start: start,
      end: end,
      weekly: weekly,
      proposal: proposal,
      onSubmit: onSubmit,
    ),
  );
  return saved ?? false;
}

/// Buổi có khớp một khung giờ trong lịch hằng tuần của học sinh không.
bool isFromWeeklySchedule(
  RecorderLessonDto? lesson,
  List<RecorderScheduleSlot> schedule,
  DateTime start,
) {
  if (lesson != null && lesson.isMoved) return false;
  final hm = _hm(start);
  return schedule.any((s) => s.dayOfWeek == start.weekday && s.start == hm);
}

/// "Đổi lịch" cho buổi recorder chưa diễn ra. Trả về true khi đã dời.
Future<bool> moveRecorderLesson(
  BuildContext context,
  WidgetRef ref,
  TutorLessonDto lesson, {
  RecorderLessonDto? recorder,
}) async {
  final start = lesson.startDt?.toLocal();
  final end = lesson.endDt?.toLocal();
  final id = lesson.recorderLessonId;
  if (id == null || start == null || end == null) return false;
  if ((lesson.recorderStatus ?? 'scheduled') != 'scheduled' ||
      !start.isAfter(DateTime.now())) {
    AppToast.show(
      context,
      message: 'Chỉ đổi lịch được buổi chưa diễn ra.',
      type: AppToastType.warning,
    );
    return false;
  }
  final students = await ref
      .read(recorderStudentsProvider.future)
      .catchError((Object _) => const <RecorderStudentDto>[]);
  final schedule =
      students
          .where((s) => s.studentId == lesson.recorderStudentId)
          .firstOrNull
          ?.schedule ??
      const <RecorderScheduleSlot>[];
  if (!context.mounted) return false;
  final actions = ref.read(recorderLessonActionsProvider);
  return showLessonMoveSheet(
    context,
    studentName: lesson.studentName,
    subtitle: lesson.subjectName,
    start: start,
    end: end,
    weekly: isFromWeeklySchedule(recorder, schedule, start),
    onSubmit: (c) async {
      try {
        await actions.moveLesson(id, c.start, c.end, c.scope);
        if (context.mounted) {
          AppToast.show(
            context,
            message: c.scope == RecorderMoveScope.following
                ? 'Đã đổi lịch buổi này và các buổi sau'
                : 'Đã dời buổi sang ${_dayText(c.start)} · ${_hm(c.start)}',
            type: AppToastType.success,
          );
        }
        return true;
      } on Object catch (e) {
        if (context.mounted) {
          AppToast.show(
            context,
            message: apiErrorMessage(e, 'Chưa đổi được lịch. Thử lại sau.'),
            type: AppToastType.error,
          );
        }
        return false;
      }
    },
  );
}

/// "Đổi lịch" cho buổi booking: gửi đề xuất cho phụ huynh (≥ 2 giờ trước giờ
/// học). Trả về true khi đã gửi.
Future<bool> proposeBookedReschedule(
  BuildContext context,
  WidgetRef ref,
  TutorLessonDto lesson,
) async {
  final start = lesson.startDt?.toLocal();
  final end = lesson.endDt?.toLocal();
  if (start == null || end == null || lesson.lessonId == 0) return false;
  if (start.difference(DateTime.now()) < bookedRescheduleLead) {
    AppToast.show(
      context,
      message: 'Chỉ đề xuất đổi lịch được trước giờ học ít nhất 2 tiếng.',
      type: AppToastType.warning,
    );
    return false;
  }
  final actions = ref.read(recorderLessonActionsProvider);
  return showLessonMoveSheet(
    context,
    studentName: lesson.studentName,
    subtitle: lesson.subjectName,
    start: start,
    end: end,
    proposal: true,
    onSubmit: (c) async {
      try {
        await actions.proposeReschedule(
          lesson.lessonId,
          c.start,
          reason: c.reason,
        );
        if (context.mounted) {
          AppToast.show(
            context,
            message: 'Đã gửi đề xuất đổi lịch. Chờ phụ huynh đồng ý.',
            type: AppToastType.success,
          );
        }
        return true;
      } on Object catch (e) {
        if (context.mounted) {
          AppToast.show(
            context,
            message: apiErrorMessage(e, 'Chưa gửi được đề xuất. Thử lại sau.'),
            type: AppToastType.error,
          );
        }
        return false;
      }
    },
  );
}

/// Giải thích vì sao không huỷ được một buổi booking.
Future<void> explainBookedCancel(BuildContext context) => showDialog<void>(
  context: context,
  builder: (ctx) => AlertDialog(
    backgroundColor: TutorColors.surface,
    title: Text(
      'Không huỷ được buổi này',
      style: TutorType.display(size: 20),
    ),
    content: Text(
      'Buổi học đặt qua TopTutor không huỷ riêng từng buổi được. Hãy dùng '
      '"Đổi lịch" để đề xuất giờ khác với phụ huynh, hoặc liên hệ TopTutor '
      'nếu cần dừng lớp.',
      style: TutorType.rowSub(),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(ctx).pop(),
        child: Text('Đã hiểu', style: TutorType.action()),
      ),
    ],
  ),
);
