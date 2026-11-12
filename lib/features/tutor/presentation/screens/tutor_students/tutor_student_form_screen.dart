import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/core/theme/tutor_design.dart';
import 'package:tutora/core/utils/input_validators.dart';
import 'package:tutora/features/tutor/data/datasources/recorder_datasource.dart';
import 'package:tutora/features/tutor/data/models/recorder_models.dart';
import 'package:tutora/features/tutor/presentation/providers/recorder_provider.dart';
import 'package:tutora/features/tutor/presentation/widgets/canvas_ui.dart';
import 'package:tutora/features/tutor/presentation/widgets/consent_text_dialog.dart';

/// Thêm / sửa học sinh ngoài nền tảng. Trả về học sinh đã lưu (hoặc null khi
/// gia sư huỷ / xoá học sinh).
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

class _TutorStudentFormScreenState
    extends ConsumerState<TutorStudentFormScreen> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.student?.fullName);
  late final _subject = TextEditingController(text: widget.student?.subject);
  late final _parentName = TextEditingController(
    text: widget.student?.parentName,
  );
  late final _parentPhone = TextEditingController(
    text: widget.student?.parentPhone,
  );
  late final _note = TextEditingController(text: widget.student?.note);
  late int? _grade = widget.student?.grade;
  late bool _consent =
      (widget.student?.hasConsent ?? false) &&
      !(widget.student?.needsReconsent ?? false);
  late final List<RecorderScheduleSlot> _slots = [
    ...?widget.student?.schedule,
  ];

  /// Khoảng áp dụng lịch. Ngày kết thúc do gia sư tự chọn (không tự điền) và
  /// tối đa [_maxMonths] tháng — để lịch lặp không sinh hàng chục buổi thừa.
  late DateTime _from = widget.student?.scheduleFrom ?? _today();
  late DateTime? _until = widget.student?.scheduleUntil;

  static const int _maxMonths = 6;

  static DateTime _addMonths(DateTime d, int months) =>
      DateTime(d.year, d.month + months, d.day);

  String get _rangeHint {
    final until = _until;
    if (until == null) {
      return 'Chọn ngày kết thúc (tối đa $_maxMonths tháng). Hết ngày kết '
          'thúc thì lịch dừng — gia hạn bằng cách sửa ngày.';
    }
    final n = countScheduledLessons(_slots, _from, until);
    return 'Khoảng $n buổi. Hết ngày kết thúc thì lịch dừng — gia hạn bằng '
        'cách sửa ngày.';
  }

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  static String _d(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _pickDate({required bool start}) async {
    final until = _until;
    final lastEnd = _addMonths(_from, _maxMonths);
    var initialEnd = until ?? _addMonths(_from, 1);
    if (initialEnd.isAfter(lastEnd)) initialEnd = lastEnd;
    if (initialEnd.isBefore(_from)) initialEnd = _from;
    final picked = await showDatePicker(
      context: context,
      initialDate: start ? _from : initialEnd,
      firstDate: start ? DateTime(2020) : _from,
      lastDate: start
          ? DateTime(_from.year + 1, _from.month, _from.day)
          : lastEnd,
      helpText: start ? 'Ngày bắt đầu' : 'Ngày kết thúc',
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        // Giữ nguyên độ dài khoá học khi dời ngày bắt đầu.
        if (until != null && !until.isBefore(_from)) {
          _until = picked.add(until.difference(_from));
        }
        _from = picked;
      } else {
        _until = picked;
      }
    });
  }

  bool _saving = false;

  /// Sau lần bấm lưu đầu tiên, ô báo đỏ tự hết lỗi ngay khi gõ lại.
  bool _triedSave = false;

  bool get _editing => widget.student != null;

  @override
  void dispose() {
    for (final c in [_name, _subject, _parentName, _parentPhone, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_triedSave) setState(() => _triedSave = true);
    if (!(_form.currentState?.validate() ?? false)) {
      _snack('Điền đủ các thông tin còn thiếu (ô báo đỏ).');
      return;
    }
    // Bắt buộc có đồng ý của phụ huynh mới thêm được học sinh (server cũng chặn).
    if (!_editing && !_consent) {
      _snack(
        'Cần xác nhận phụ huynh đã đọc và đồng ý nội dung ghi âm trước khi thêm học sinh.',
      );
      return;
    }
    final until = _until;
    if (_slots.isNotEmpty) {
      if (until == null) {
        _snack('Chọn ngày kết thúc cho lịch học.');
        return;
      }
      if (until.isBefore(_from)) {
        _snack('Ngày kết thúc phải sau ngày bắt đầu.');
        return;
      }
      if (until.isAfter(_addMonths(_from, _maxMonths))) {
        _snack(
          'Lịch học tối đa $_maxMonths tháng — gia hạn sau bằng cách sửa ngày.',
        );
        return;
      }
    }
    setState(() => _saving = true);
    final input = RecorderStudentInput(
      fullName: collapseSpaces(_name.text),
      grade: _grade,
      subject: collapseSpaces(_subject.text),
      parentName: collapseSpaces(_parentName.text),
      parentPhone: normalizePhone(_parentPhone.text),
      parentConsent: _consent,
      note: _note.text,
      schedule: _slots,
      scheduleFrom: _slots.isEmpty ? null : _from,
      scheduleUntil: _slots.isEmpty ? null : until,
    );
    try {
      final ds = ref.read(recorderDatasourceProvider);
      final saved = _editing
          ? await ds.updateStudent(widget.student!.studentId, input)
          : await ds.createStudent(input);
      reloadRecorderStudentData(ref);
      if (mounted) Navigator.of(context).pop(saved);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack(_message(e) ?? 'Chưa lưu được. Kiểm tra mạng rồi thử lại.');
    }
  }

  /// Xoá vĩnh viễn — theo yêu cầu xoá dữ liệu của phụ huynh (trang
  /// tutora.vn/policies/data-deletion). Không khôi phục được.
  Future<void> _deletePermanently() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TutorColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TutorSurface.radius),
        ),
        title: const Text('Xoá vĩnh viễn học sinh này?'),
        content: const Text(
          'Toàn bộ bản ghi âm, bản chép lời, báo cáo, lịch học và xác nhận đồng '
          'ý của học sinh sẽ bị xoá và không khôi phục được.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Thôi'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: TutorColors.danger),
            child: const Text('Xoá vĩnh viễn'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(recorderDatasourceProvider)
          .deleteStudentPermanently(widget.student!.studentId);
      reloadRecorderStudentData(ref);
      if (mounted) Navigator.of(context).pop();
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack(_message(e) ?? 'Chưa xoá được học sinh. Thử lại sau.');
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
    ..showSnackBar(
      SnackBar(content: Text(m), behavior: SnackBarBehavior.floating),
    );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TutorColors.bg,
      body: DecoratedBox(
        decoration: TutorSurface.paper,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Form(
                  key: _form,
                  autovalidateMode: _triedSave
                      ? AutovalidateMode.onUserInteraction
                      : AutovalidateMode.disabled,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      TutorSurface.gutter,
                      16,
                      TutorSurface.gutter,
                      24,
                    ),
                    children: [
                      Row(
                        children: [
                          CanvasBackButton(
                            onTap: () => Navigator.of(context).maybePop(),
                          ),
                          const Spacer(),
                          if (_editing)
                            CanvasCircleButton(
                              tooltip: 'Xoá học sinh',
                              onTap: _saving ? null : _deletePermanently,
                              child: const Icon(
                                Icons.delete_outline_rounded,
                                size: 20,
                                color: TutorColors.ink,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _editing ? 'Sửa học sinh' : 'Thêm học sinh',
                        style: TutorType.display(
                          size: 26,
                          weight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const _Label('Học sinh'),
                      _Input(
                        controller: _name,
                        label: 'Họ tên học sinh',
                        textCapitalization: TextCapitalization.words,
                        validator: (v) =>
                            validatePersonName(v, field: 'họ tên học sinh'),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              initialValue: _grade,
                              isExpanded: true,
                              decoration: _decoration('Lớp'),
                              borderRadius: BorderRadius.circular(16),
                              dropdownColor: TutorColors.surface,
                              style: TutorType.body(),
                              icon: const Icon(
                                Icons.expand_more_rounded,
                                color: TutorColors.ink3,
                              ),
                              items: [
                                for (var g = 1; g <= 12; g++)
                                  DropdownMenuItem(
                                    value: g,
                                    child: Text('Lớp $g'),
                                  ),
                              ],
                              onChanged: (v) => setState(() => _grade = v),
                              validator: (v) => v == null ? 'Chọn lớp' : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: _Input(
                              controller: _subject,
                              label: 'Môn (vd. Toán)',
                              validator: validateSubject,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      const _Label('Lịch học hằng tuần'),
                      _ScheduleEditor(
                        slots: _slots,
                        onChanged: () => setState(() {}),
                      ),
                      if (_slots.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _TimeBox(
                                label: 'Từ ngày',
                                value: _d(_from),
                                onTap: () => _pickDate(start: true),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _TimeBox(
                                label: 'Đến ngày',
                                value: _until == null
                                    ? 'Chọn ngày'
                                    : _d(_until!),
                                onTap: () => _pickDate(start: false),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final m in const [1, 2, 3, 6])
                              ActionChip(
                                label: Text('$m tháng'),
                                labelStyle: TutorType.action().copyWith(
                                  fontSize: 13,
                                ),
                                backgroundColor: const Color(0xFFEAEAE4),
                                side: BorderSide.none,
                                shape: const StadiumBorder(),
                                onPressed: () => setState(
                                  () => _until = _addMonths(_from, m),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(_rangeHint, style: TutorType.caption()),
                      ],
                      const SizedBox(height: 22),
                      const _Label('Phụ huynh · nhận báo cáo qua Zalo'),
                      _Input(
                        controller: _parentName,
                        label: 'Tên phụ huynh (vd. Chị Hương)',
                        textCapitalization: TextCapitalization.words,
                        validator: (v) =>
                            validatePersonName(v, field: 'tên phụ huynh'),
                      ),
                      const SizedBox(height: 10),
                      _Input(
                        controller: _parentPhone,
                        label: 'SĐT phụ huynh (có dùng Zalo)',
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp('[0-9+ .]')),
                        ],
                        // Bắt buộc: báo cáo được gửi tới số này qua Zalo.
                        validator: (v) =>
                            validatePhone(v, field: 'số điện thoại phụ huynh'),
                      ),
                      const SizedBox(height: 14),
                      _ConsentCard(
                        value: _consent,
                        onChanged: (v) => setState(() => _consent = v ?? false),
                        onShowText: () =>
                            unawaited(showConsentTextDialog(context)),
                      ),
                      const SizedBox(height: 22),
                      const _Label('Ghi chú'),
                      _Input(
                        controller: _note,
                        label: 'Mục tiêu, lịch học… (không bắt buộc)',
                        maxLines: 3,
                        validator: (v) =>
                            validateOptionalMaxLength(v, noteMaxLength),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  TutorSurface.gutter,
                  8,
                  TutorSurface.gutter,
                  14,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!_editing) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.lock_outline_rounded,
                            size: 16,
                            color: TutorColors.ink3,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Phụ huynh cần đồng ý ghi âm trước buổi đầu.',
                              style: TutorType.caption(
                                color: TutorColors.ink3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    CanvasCta(
                      label: _saving
                          ? 'Đang lưu…'
                          : (_editing ? 'Lưu thay đổi' : 'Thêm học sinh'),
                      onPressed: _saving ? null : _save,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Nền ô nhập sáng (canvas `#FBFAF7`) có viền mực 8%.
const Color _wellFill = Color(0xFFFBFAF7);
const Color _wellLine = Color(0x141F2A24);

InputDecoration _decoration(String label) {
  OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: c, width: w),
  );
  return InputDecoration(
    labelText: label,
    labelStyle: TutorType.body(color: TutorColors.ink3).copyWith(fontSize: 14),
    floatingLabelStyle: TutorType.caption(color: TutorColors.ink3),
    filled: true,
    fillColor: _wellFill,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: border(_wellLine),
    enabledBorder: border(_wellLine),
    focusedBorder: border(TutorColors.ink, 1.3),
    errorBorder: border(TutorColors.danger),
    focusedErrorBorder: border(TutorColors.danger, 1.3),
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
    style: TutorType.body(),
    cursorColor: TutorColors.ink,
    decoration: _decoration(label),
  );
}

/// Nhãn nhỏ đầu nhóm — chữ thường, không giãn (V5.6).
class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: TutorType.caption(color: TutorColors.ink3)),
  );
}

/// Ô xác nhận đồng ý ghi âm: thẻ sáng, sang sage khi đã tick.
class _ConsentCard extends StatelessWidget {
  const _ConsentCard({
    required this.value,
    required this.onChanged,
    required this.onShowText,
  });

  final bool value;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onShowText;

  @override
  Widget build(BuildContext context) => Material(
    color: value ? TutorColors.sage : TutorColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(TutorSurface.radius),
      side: value ? BorderSide.none : const BorderSide(color: TutorColors.line),
    ),
    clipBehavior: Clip.antiAlias,
    child: CheckboxListTile(
      value: value,
      onChanged: onChanged,
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: TutorColors.ink,
      checkColor: Colors.white,
      side: const BorderSide(color: Color(0xFFA3A8A2), width: 1.6),
      checkboxShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
      ),
      contentPadding: const EdgeInsets.fromLTRB(8, 6, 14, 2),
      title: Text(
        'Phụ huynh đã đọc và đồng ý nội dung ghi âm: ghi âm buổi '
        'học, AI tóm tắt, nhận báo cáo qua Zalo',
        style: TutorType.rowTitle().copyWith(fontSize: 14),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bản ghi có giọng của học sinh, nên phải cho phụ huynh '
              'đọc nội dung đồng ý trước khi ghi. Chưa xác nhận thì '
              'không ghi âm được.',
              style: TutorType.caption(color: TutorColors.ink3),
            ),
            TextButton.icon(
              onPressed: onShowText,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                foregroundColor: TutorColors.ink,
                textStyle: TutorType.action().copyWith(fontSize: 13),
              ),
              icon: const Icon(Icons.lock_outline_rounded, size: 15),
              label: const Text('Xem nội dung đồng ý'),
            ),
          ],
        ),
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
      backgroundColor: TutorColors.paperTop,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _SlotSheet(),
    );
    if (added == null || added.isEmpty) return;
    for (final a in added) {
      final dup = slots.any(
        (s) => s.dayOfWeek == a.dayOfWeek && s.start == a.start,
      );
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
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: TutorSurface.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (slots.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 14, bottom: 4),
              child: Text(
                'Chưa có lịch. Thêm các buổi cố định trong tuần để lịch dạy tự hiện trong tab Lịch.',
                style: TutorType.rowSub(),
              ),
            ),
          for (final (i, slot) in [...slots].indexed)
            _SlotRow(
              slot: slot,
              first: i == 0,
              onRemove: () {
                slots.remove(slot);
                onChanged();
              },
            ),
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: slots.isEmpty ? BorderSide.none : TutorSurface.rule,
              ),
            ),
            child: TextButton.icon(
              onPressed: () => _add(context),
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 46),
                foregroundColor: TutorColors.ink,
                textStyle: TutorType.action(),
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Thêm buổi trong tuần'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlotRow extends StatelessWidget {
  const _SlotRow({
    required this.slot,
    required this.first,
    required this.onRemove,
  });

  final RecorderScheduleSlot slot;
  final bool first;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 4),
    decoration: BoxDecoration(
      border: Border(top: first ? BorderSide.none : TutorSurface.rule),
    ),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 30,
          alignment: Alignment.center,
          decoration: TutorSurface.well(),
          child: Text(
            slot.dayLabel,
            style: TutorType.action().copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text('${slot.start} – ${slot.end}', style: TutorType.body()),
        ),
        IconButton(
          tooltip: 'Xoá',
          icon: const Icon(
            Icons.close_rounded,
            size: 18,
            color: TutorColors.ink4,
          ),
          onPressed: onRemove,
        ),
      ],
    ),
  );
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
        final dur =
            (_end.hour * 60 + _end.minute) - (_start.hour * 60 + _start.minute);
        _start = t;
        // Giữ nguyên độ dài buổi khi đổi giờ bắt đầu.
        final endMin = (t.hour * 60 + t.minute + (dur > 0 ? dur : 90)).clamp(
          0,
          23 * 60 + 59,
        );
        _end = TimeOfDay(hour: endMin ~/ 60, minute: endMin % 60);
      } else {
        _end = t;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final valid =
        _days.isNotEmpty &&
        (_end.hour * 60 + _end.minute) > (_start.hour * 60 + _start.minute);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        TutorSurface.gutter,
        20,
        TutorSurface.gutter,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Thêm buổi trong tuần', style: TutorType.sectionTitle()),
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
                  backgroundColor: const Color(0xFFEAEAE4),
                  side: BorderSide.none,
                  shape: const StadiumBorder(),
                  labelStyle: TutorType.action(
                    color: _days.contains(d) ? Colors.white : TutorColors.ink,
                  ),
                  onSelected: (on) =>
                      setState(() => on ? _days.add(d) : _days.remove(d)),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _TimeBox(
                  label: 'Bắt đầu',
                  value: _fmt(_start),
                  onTap: () => _pick(true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TimeBox(
                  label: 'Kết thúc',
                  value: _fmt(_end),
                  onTap: () => _pick(false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          CanvasCta(
            label: 'Thêm vào lịch',
            onPressed: valid
                ? () => Navigator.pop(context, [
                    for (final d in (_days.toList()..sort()))
                      RecorderScheduleSlot(
                        dayOfWeek: d,
                        start: _fmt(_start),
                        end: _fmt(_end),
                      ),
                  ])
                : null,
          ),
        ],
      ),
    );
  }
}

/// Ô chọn ngày / giờ trên nền sáng.
class _TimeBox extends StatelessWidget {
  const _TimeBox({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: _wellFill,
    shape: RoundedRectangleBorder(
      side: const BorderSide(color: _wellLine),
      borderRadius: BorderRadius.circular(14),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TutorType.caption(color: TutorColors.ink3)),
            const SizedBox(height: 2),
            Text(value, style: TutorType.numeral()),
          ],
        ),
      ),
    ),
  );
}
