import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/core/theme/tutor_design.dart';
import 'package:tutora/features/tutor/data/datasources/recorder_datasource.dart';
import 'package:tutora/features/tutor/data/models/recorder_models.dart';
import 'package:tutora/features/tutor/presentation/providers/recorder_provider.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_students/tutor_student_form_screen.dart';
import 'package:tutora/features/tutor/presentation/widgets/canvas_ui.dart';

/// Khóa học của học sinh: nhãn trạng thái (hết khóa / sắp hết / đến ngày) và
/// khối gia hạn tháng mới cho học sinh đã hết khóa. Gia hạn = sửa khoảng ngày
/// của lịch hằng tuần (giữ nguyên khung giờ); backend sinh lại các buổi.

String _d(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

String _dy(DateTime d) => '${_d(d)}/${d.year}';

DateTime _today() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
}

/// Chữ ngắn cho trạng thái khóa; null khi không cần nói gì (không giới hạn).
String? courseStatusText(RecorderStudentDto s, [DateTime? today]) {
  final until = s.scheduleUntil;
  final left = s.courseDaysLeft(today);
  switch (s.courseStatus(today)) {
    case CourseStatus.open:
      return s.schedule.isEmpty ? 'Chưa đặt lịch' : null;
    case CourseStatus.ended:
      return 'Hết khóa ${_d(until!)}';
    case CourseStatus.endingSoon:
      return left == 0
          ? 'Hết khóa hôm nay'
          : 'Còn $left ngày · hết ${_d(until!)}';
    case CourseStatus.active:
      return 'Học đến ${_d(until!)}';
  }
}

/// Nhãn trạng thái khóa: đậm khi đã hết, xám khi sắp hết, chữ phụ khi đang học.
class CourseStatusLabel extends StatelessWidget {
  const CourseStatusLabel({required this.student, super.key});

  final RecorderStudentDto student;

  @override
  Widget build(BuildContext context) {
    final text = courseStatusText(student);
    if (text == null) return const SizedBox.shrink();
    return switch (student.courseStatus()) {
      CourseStatus.ended => CanvasTag(text, filled: true),
      CourseStatus.endingSoon => CanvasTag(text),
      _ => Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TutorType.caption(),
      ),
    };
  }
}

/// Lưu khóa mới cho [s] từ [from] tới [until]. Trả về thông báo lỗi, hoặc null
/// khi đã lưu.
Future<String?> renewCourse(
  WidgetRef ref,
  RecorderStudentDto s,
  DateTime from,
  DateTime until,
) async {
  try {
    await ref
        .read(recorderDatasourceProvider)
        .updateStudent(s.studentId, s.renewInput(from, until));
    reloadRecorderStudentData(ref);
    return null;
  } on DioException catch (e) {
    final Object? data = e.response?.data;
    final m = data is Map<String, dynamic> ? data['message'] : null;
    return m is String && m.isNotEmpty
        ? m
        : 'Chưa gia hạn được. Kiểm tra mạng rồi thử lại.';
  } on Object {
    return 'Chưa gia hạn được. Kiểm tra mạng rồi thử lại.';
  }
}

/// Khối "Gia hạn tháng mới" cho học sinh đã hết khóa: ba nút nhanh 1 · 2 · 3
/// tháng (bắt đầu từ hôm nay) và "Chọn ngày" (ngày bắt đầu + ngày kết thúc).
class CourseRenewPanel extends ConsumerStatefulWidget {
  const CourseRenewPanel({
    required this.student,
    this.showName = false,
    super.key,
  });

  final RecorderStudentDto student;

  /// Trên trang chủ ghi cả tên học sinh.
  final bool showName;

  @override
  ConsumerState<CourseRenewPanel> createState() => _CourseRenewPanelState();
}

class _CourseRenewPanelState extends ConsumerState<CourseRenewPanel> {
  bool _busy = false;

  RecorderStudentDto get _s => widget.student;

  Future<void> _save(DateTime from, DateTime until) async {
    setState(() => _busy = true);
    final error = await renewCourse(ref, _s, from, until);
    if (!mounted) return;
    setState(() => _busy = false);
    final n = countScheduledLessons(_s.schedule, from, until);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            error ??
                'Đã gia hạn ${_s.fullName}: ${_d(from)} – ${_dy(until)} · $n buổi.',
          ),
        ),
      );
  }

  Future<void> _quick(int months) {
    final from = _today();
    return _save(from, courseEndAfterMonths(from, months));
  }

  Future<void> _pick() async {
    final range = await CourseRenewSheet.show(context, _s);
    if (range == null) return;
    await _save(range.from, range.until);
  }

  @override
  Widget build(BuildContext context) {
    final until = _s.scheduleUntil;
    final noSchedule = _s.schedule.isEmpty;
    final head = [
      if (widget.showName) _s.fullName,
      if (until != null) 'hết khóa ${_dy(until)}' else 'chưa có lịch',
    ].join(' · ');
    return DecoratedBox(
      decoration: TutorSurface.sage(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.showName ? head : 'Khóa đã hết',
                    style: TutorType.rowTitle(),
                  ),
                ),
                if (_busy)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: TutorColors.ink,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              noSchedule
                  ? 'Đặt lại lịch hằng tuần để tiếp tục.'
                  : widget.showName
                  ? 'Gia hạn tháng mới, giữ nguyên lịch hằng tuần.'
                  : '${until == null ? '' : 'Hết ngày ${_dy(until)}. '}'
                        'Gia hạn tháng mới, giữ nguyên lịch hằng tuần.',
              style: TutorType.rowSub(),
            ),
            const SizedBox(height: 12),
            if (noSchedule)
              _Chip(
                label: 'Đặt lịch',
                onTap: _busy
                    ? null
                    : () => unawaited(
                        TutorStudentFormScreen.open(context, student: _s),
                      ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final m in const [1, 2, 3])
                    _Chip(
                      label: '+$m tháng',
                      onTap: _busy ? null : () => unawaited(_quick(m)),
                    ),
                  _Chip(
                    label: 'Chọn ngày',
                    icon: Icons.calendar_today_outlined,
                    onTap: _busy ? null : () => unawaited(_pick()),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.onTap,
    this.icon,
    this.onPaper = false,
    this.selected = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;

  /// Trên nền giấy (bảng chọn ngày) dùng nền sage để không chìm.
  final bool onPaper;

  /// Đang chọn: nền mực, chữ trắng.
  final bool selected;

  @override
  Widget build(BuildContext context) => Material(
    color: selected
        ? TutorColors.ink
        : onPaper
        ? TutorColors.sage
        : TutorColors.surface,
    shape: const StadiumBorder(),
    child: InkWell(
      customBorder: const StadiumBorder(),
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 40),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 15,
                  color: selected ? Colors.white : TutorColors.ink,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TutorType.action(
                  color: selected
                      ? Colors.white
                      : onTap == null
                      ? TutorColors.ink3
                      : TutorColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Bảng "Tháng mới": ngày bắt đầu, ngày kết thúc (tối đa [courseMaxMonths]
/// tháng), nút nhanh 1 · 2 · 3 tháng và số buổi dự kiến.
class CourseRenewSheet extends StatefulWidget {
  const CourseRenewSheet({required this.student, super.key});

  final RecorderStudentDto student;

  static Future<({DateTime from, DateTime until})?> show(
    BuildContext context,
    RecorderStudentDto student,
  ) => showModalBottomSheet<({DateTime from, DateTime until})>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: TutorColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => CourseRenewSheet(student: student),
  );

  @override
  State<CourseRenewSheet> createState() => _CourseRenewSheetState();
}

class _CourseRenewSheetState extends State<CourseRenewSheet> {
  late DateTime _from = _today();
  late DateTime _until = courseEndAfterMonths(_from, 1);

  DateTime get _maxUntil => DateTime(
    _from.year,
    _from.month + courseMaxMonths,
    _from.day,
  );

  Future<void> _pickDate({required bool start}) async {
    final today = _today();
    final picked = await showDatePicker(
      context: context,
      initialDate: start ? _from : _until,
      firstDate: start ? today : _from,
      lastDate: start
          ? DateTime(today.year + 1, today.month, today.day)
          : _maxUntil,
      helpText: start ? 'Ngày bắt đầu' : 'Ngày kết thúc',
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        // Giữ nguyên độ dài khóa khi dời ngày bắt đầu.
        final len = _until.difference(_from);
        _from = picked;
        _until = picked.add(len);
        if (_until.isAfter(_maxUntil)) _until = _maxUntil;
      } else {
        _until = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.student;
    final n = countScheduledLessons(s.schedule, _from, _until);
    final valid = !_until.isBefore(_from) && !_until.isAfter(_maxUntil);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          TutorSurface.gutter,
          18,
          TutorSurface.gutter,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Tháng mới · ${s.fullName}', style: TutorType.sectionTitle()),
            const SizedBox(height: 4),
            Text(
              'Giữ nguyên lịch hằng tuần. Tối đa $courseMaxMonths tháng mỗi lần.',
              style: TutorType.rowSub(),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in const [1, 2, 3])
                  _Chip(
                    label: '$m tháng',
                    onPaper: true,
                    selected: _until == courseEndAfterMonths(_from, m),
                    onTap: () => setState(
                      () => _until = courseEndAfterMonths(_from, m),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            _DateRow(
              label: 'Ngày bắt đầu',
              value: _dy(_from),
              onTap: () => unawaited(_pickDate(start: true)),
            ),
            _DateRow(
              label: 'Ngày kết thúc',
              value: _dy(_until),
              onTap: () => unawaited(_pickDate(start: false)),
            ),
            const SizedBox(height: 10),
            Text(
              valid
                  ? 'Khoảng $n buổi theo lịch hằng tuần.'
                  : 'Ngày kết thúc phải sau ngày bắt đầu, tối đa '
                        '$courseMaxMonths tháng.',
              style: TutorType.caption(),
            ),
            const SizedBox(height: 16),
            CanvasCta(
              label: 'Gia hạn',
              onPressed: valid
                  ? () =>
                        Navigator.of(context).pop((from: _from, until: _until))
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => CanvasRow(
    onTap: onTap,
    child: Row(
      children: [
        Expanded(child: Text(label, style: TutorType.rowSub())),
        Text(value, style: TutorType.rowTitle()),
        const SizedBox(width: 6),
        const CanvasChevron(),
      ],
    ),
  );
}
