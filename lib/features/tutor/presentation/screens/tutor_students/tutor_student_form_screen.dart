import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/features/tutor/data/datasources/recorder_datasource.dart';
import 'package:tutora/features/tutor/data/models/recorder_models.dart';
import 'package:tutora/features/tutor/presentation/providers/recorder_provider.dart';
import 'package:tutora/features/tutor/presentation/providers/tutor_lesson_provider.dart';

/// Thêm / sửa học sinh ngoài nền tảng. Trả về học sinh đã lưu (hoặc null khi
/// gia sư huỷ / ẩn học sinh).
class TutorStudentFormScreen extends ConsumerStatefulWidget {
  const TutorStudentFormScreen({this.student, super.key});

  final RecorderStudentDto? student;

  static Future<RecorderStudentDto?> open(
    BuildContext context, {
    RecorderStudentDto? student,
  }) => Navigator.of(context, rootNavigator: true).push<RecorderStudentDto>(
    MaterialPageRoute(builder: (_) => TutorStudentFormScreen(student: student)),
  );

  @override
  ConsumerState<TutorStudentFormScreen> createState() =>
      _TutorStudentFormScreenState();
}

class _TutorStudentFormScreenState extends ConsumerState<TutorStudentFormScreen> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.student?.fullName);
  late final _subject = TextEditingController(text: widget.student?.subject);
  late final _parentName = TextEditingController(text: widget.student?.parentName);
  late final _parentPhone = TextEditingController(text: widget.student?.parentPhone);
  late final _note = TextEditingController(text: widget.student?.note);
  late int? _grade = widget.student?.grade;
  late bool _consent = widget.student?.hasConsent ?? false;
  late final List<RecorderScheduleSlot> _slots = [
    ...?widget.student?.schedule,
  ];

  /// Khoảng áp dụng lịch. Mặc định: từ hôm nay tới hết 3 tháng — để lịch lặp
  /// không kéo dài vô hạn (và không sinh hàng chục buổi thừa).
  late DateTime _from = widget.student?.scheduleFrom ?? _today();
  late DateTime _until = widget.student?.scheduleUntil ??
      DateTime(_from.year, _from.month + 3, _from.day);

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  static String _d(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _pickDate({required bool start}) async {
    final first = start ? DateTime(2020) : _from;
    final picked = await showDatePicker(
      context: context,
      initialDate: start ? _from : _until,
      firstDate: first,
      lastDate: DateTime(_from.year + 1, _from.month, _from.day),
      helpText: start ? 'Ngày bắt đầu' : 'Ngày kết thúc',
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        final span = _until.difference(_from);
        _from = picked;
        // Giữ nguyên độ dài khoá học khi dời ngày bắt đầu.
        _until = picked.add(span.isNegative ? const Duration(days: 90) : span);
      } else {
        _until = picked;
      }
    });
  }
  bool _saving = false;

  bool get _editing => widget.student != null;

  @override
  void dispose() {
    for (final c in [_name, _subject, _parentName, _parentPhone, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final input = RecorderStudentInput(
      fullName: _name.text.trim(),
      grade: _grade,
      subject: _subject.text,
      parentName: _parentName.text,
      parentPhone: _parentPhone.text.replaceAll(RegExp(r'[\s.]'), ''),
      parentConsent: _consent,
      note: _note.text,
      schedule: _slots,
      scheduleFrom: _slots.isEmpty ? null : _from,
      scheduleUntil: _slots.isEmpty ? null : _until,
    );
    try {
      final ds = ref.read(recorderDatasourceProvider);
      final saved = _editing
          ? await ds.updateStudent(widget.student!.studentId, input)
          : await ds.createStudent(input);
      ref
        ..invalidate(recorderStudentsProvider)
        ..invalidate(tutorAgendaLessonsProvider)
        ..invalidate(recorderTodayLessonsProvider)
        ..invalidate(recorderStudentLessonsProvider);
      if (mounted) Navigator.of(context).pop(saved);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack(_message(e) ?? 'Chưa lưu được. Kiểm tra mạng rồi thử lại.');
    }
  }

  Future<void> _archive() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ẩn học sinh này?'),
        content: const Text(
          'Học sinh sẽ không còn trong danh sách. Các báo cáo đã gửi vẫn được giữ.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Thôi')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ẩn')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ref.read(recorderDatasourceProvider).archiveStudent(widget.student!.studentId);
      ref.invalidate(recorderStudentsProvider);
      if (mounted) Navigator.of(context).pop();
    } on Object catch (e) {
      _snack(_message(e) ?? 'Chưa ẩn được học sinh.');
    }
  }

  static String? _message(Object e) {
    if (e is DioException && e.response?.data is Map) {
      final m = (e.response!.data as Map)['message'];
      if (m is String && m.isNotEmpty) return m;
    }
    return null;
  }

  void _snack(String m) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(m), behavior: SnackBarBehavior.floating));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TutorColors.bg,
      appBar: AppBar(
        backgroundColor: TutorColors.bg,
        surfaceTintColor: Colors.transparent,
        title: Text(_editing ? 'Sửa học sinh' : 'Thêm học sinh'),
        actions: [
          if (_editing)
            IconButton(
              tooltip: 'Ẩn học sinh',
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: _saving ? null : _archive,
            ),
        ],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            const _Label('HỌC SINH'),
            _Input(
              controller: _name,
              label: 'Họ tên học sinh',
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập tên học sinh' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _grade,
                    isExpanded: true,
                    decoration: _decoration('Lớp'),
                    items: [
                      for (var g = 1; g <= 12; g++)
                        DropdownMenuItem(value: g, child: Text('Lớp $g')),
                    ],
                    onChanged: (v) => setState(() => _grade = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _Input(controller: _subject, label: 'Môn (vd. Toán)'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const _Label('LỊCH HỌC HẰNG TUẦN'),
            _ScheduleEditor(
              slots: _slots,
              onChanged: () => setState(() {}),
            ),
            if (_slots.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _TimeBox(
                      label: 'Từ ngày',
                      value: _d(_from),
                      onTap: () => _pickDate(start: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TimeBox(
                      label: 'Đến ngày',
                      value: _d(_until),
                      onTap: () => _pickDate(start: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Khoảng ${countScheduledLessons(_slots, _from, _until)} buổi. '
                'Hết ngày kết thúc thì lịch dừng — gia hạn bằng cách sửa ngày.',
                style: const TextStyle(fontSize: 12, color: TutorColors.ink4, height: 1.35),
              ),
            ],
            const SizedBox(height: 24),
            const _Label('PHỤ HUYNH · NHẬN BÁO CÁO QUA ZALO'),
            _Input(
              controller: _parentName,
              label: 'Tên phụ huynh (vd. Chị Hương)',
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            _Input(
              controller: _parentPhone,
              label: 'SĐT phụ huynh (có dùng Zalo)',
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+ .]'))],
              validator: (v) {
                final p = (v ?? '').replaceAll(RegExp(r'[\s.]'), '');
                if (p.isEmpty) return null;
                return RegExp(r'^(\+?84|0)\d{9,10}$').hasMatch(p)
                    ? null
                    : 'Số điện thoại chưa đúng';
              },
            ),
            const SizedBox(height: 14),
            Material(
              color: _consent ? TutorColors.successBg : TutorColors.surface,
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  color: _consent ? TutorColors.successBorder : TutorColors.line,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: CheckboxListTile(
                value: _consent,
                onChanged: (v) => setState(() => _consent = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: TutorColors.success,
                title: const Text(
                  'Phụ huynh đã đồng ý cho ghi âm buổi học và nhận báo cáo qua Zalo',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: TutorColors.ink),
                ),
                subtitle: const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    'Bản ghi có giọng của học sinh, nên cần phụ huynh đồng ý trước. '
                    'Tutora sẽ gửi tin xác nhận cho phụ huynh.',
                    style: TextStyle(fontSize: 12, color: TutorColors.ink4, height: 1.35),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const _Label('GHI CHÚ'),
            _Input(controller: _note, label: 'Mục tiêu, lịch học… (không bắt buộc)', maxLines: 3),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 52),
                backgroundColor: TutorColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                _saving ? 'Đang lưu…' : (_editing ? 'Lưu thay đổi' : 'Thêm học sinh'),
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

InputDecoration _decoration(String label) {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: TutorColors.line),
  );
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: TutorColors.surface,
    border: border,
    enabledBorder: border,
    focusedBorder: border.copyWith(
      borderSide: const BorderSide(color: TutorColors.ink, width: 1.2),
    ),
  );
}

class _Input extends StatelessWidget {
  const _Input({
    required this.controller,
    required this.label,
    this.validator,
    this.keyboardType,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.sentences,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final int maxLines;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    validator: validator,
    keyboardType: keyboardType,
    inputFormatters: inputFormatters,
    textCapitalization: textCapitalization,
    maxLines: maxLines,
    decoration: _decoration(label),
  );
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        color: TutorColors.ink4,
      ),
    ),
  );
}

/// Danh sách khung giờ trong tuần + nút thêm. Sửa trực tiếp [slots].
class _ScheduleEditor extends StatelessWidget {
  const _ScheduleEditor({required this.slots, required this.onChanged});

  final List<RecorderScheduleSlot> slots;
  final VoidCallback onChanged;

  Future<void> _add(BuildContext context) async {
    final added = await showModalBottomSheet<List<RecorderScheduleSlot>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: TutorColors.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _SlotSheet(),
    );
    if (added == null || added.isEmpty) return;
    for (final a in added) {
      final dup = slots.any((s) => s.dayOfWeek == a.dayOfWeek && s.start == a.start);
      if (!dup) slots.add(a);
    }
    slots.sort((a, b) {
      final d = a.dayOfWeek.compareTo(b.dayOfWeek);
      return d != 0 ? d : a.start.compareTo(b.start);
    });
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: TutorColors.surface,
        border: Border.all(color: TutorColors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          if (slots.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: Text(
                'Chưa có lịch. Thêm các buổi cố định trong tuần để lịch dạy tự hiện trong tab Lịch.',
                style: TextStyle(fontSize: 13, color: TutorColors.ink3, height: 1.35),
              ),
            ),
          for (final slot in [...slots])
            ListTile(
              dense: true,
              leading: Container(
                width: 36,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: TutorColors.surfaceSunken,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(slot.dayLabel,
                    style: const TextStyle(fontWeight: FontWeight.w700, color: TutorColors.ink)),
              ),
              title: Text('${slot.start} – ${slot.end}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: TutorColors.ink)),
              trailing: IconButton(
                tooltip: 'Xoá',
                icon: const Icon(Icons.close_rounded, size: 18, color: TutorColors.ink4),
                onPressed: () {
                  slots.remove(slot);
                  onChanged();
                },
              ),
            ),
          TextButton.icon(
            onPressed: () => _add(context),
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 44),
              foregroundColor: TutorColors.primary,
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Thêm buổi trong tuần'),
          ),
        ],
      ),
    );
  }
}

/// Chọn các thứ trong tuần + giờ bắt đầu/kết thúc → nhiều khung giờ cùng lúc.
class _SlotSheet extends StatefulWidget {
  const _SlotSheet();

  @override
  State<_SlotSheet> createState() => _SlotSheetState();
}

class _SlotSheetState extends State<_SlotSheet> {
  final Set<int> _days = {};
  TimeOfDay _start = const TimeOfDay(hour: 19, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 20, minute: 30);

  static String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pick(bool start) async {
    final t = await showTimePicker(
      context: context,
      initialTime: start ? _start : _end,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (t == null) return;
    setState(() {
      if (start) {
        final dur = (_end.hour * 60 + _end.minute) - (_start.hour * 60 + _start.minute);
        _start = t;
        // Giữ nguyên độ dài buổi khi đổi giờ bắt đầu.
        final endMin = (t.hour * 60 + t.minute + (dur > 0 ? dur : 90)).clamp(0, 23 * 60 + 59);
        _end = TimeOfDay(hour: endMin ~/ 60, minute: endMin % 60);
      } else {
        _end = t;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final valid = _days.isNotEmpty &&
        (_end.hour * 60 + _end.minute) > (_start.hour * 60 + _start.minute);
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Thêm buổi trong tuần',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: TutorColors.ink)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var d = 1; d <= 7; d++)
                FilterChip(
                  label: Text(RecorderScheduleSlot.dayLabels[d - 1]),
                  selected: _days.contains(d),
                  showCheckmark: false,
                  selectedColor: TutorColors.ink,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _days.contains(d) ? TutorColors.surface : TutorColors.ink,
                  ),
                  onSelected: (on) => setState(() => on ? _days.add(d) : _days.remove(d)),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _TimeBox(label: 'Bắt đầu', value: _fmt(_start), onTap: () => _pick(true))),
              const SizedBox(width: 12),
              Expanded(child: _TimeBox(label: 'Kết thúc', value: _fmt(_end), onTap: () => _pick(false))),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: valid
                  ? () => Navigator.pop(context, [
                        for (final d in (_days.toList()..sort()))
                          RecorderScheduleSlot(dayOfWeek: d, start: _fmt(_start), end: _fmt(_end)),
                      ])
                  : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 48),
                backgroundColor: TutorColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Thêm vào lịch'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeBox extends StatelessWidget {
  const _TimeBox({required this.label, required this.value, required this.onTap});

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: TutorColors.surface,
    shape: RoundedRectangleBorder(
      side: const BorderSide(color: TutorColors.line),
      borderRadius: BorderRadius.circular(12),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: TutorColors.ink4)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: TutorColors.ink)),
          ],
        ),
      ),
    ),
  );
}
