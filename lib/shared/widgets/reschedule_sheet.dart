import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';
import 'package:tutora/core/constants/app_text_styles.dart';
import 'package:tutora/shared/widgets/class_widgets.dart';

/// Kết quả người dùng chọn ở sheet đổi lịch.
typedef RescheduleChoice = ({DateTime start, String? reason});

/// Khoảng cách tối thiểu giữa giờ đề xuất và hiện tại
const kRescheduleCutoff = Duration(hours: 2);

/// Sheet đề xuất dời một buổi học sang giờ khác.

Future<RescheduleChoice?> showRescheduleSheet(
  BuildContext context, {
  required DateTime currentStart,
  required DateTime currentEnd,
}) {
  return showModalBottomSheet<RescheduleChoice>(
    context: context,
    // Phủ lên cả bottom bar của shell, không mở trong nested navigator.
    useRootNavigator: true,
    backgroundColor: AppColors.paper,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) =>
        _RescheduleSheet(currentStart: currentStart, currentEnd: currentEnd),
  );
}

class _RescheduleSheet extends StatefulWidget {
  const _RescheduleSheet({
    required this.currentStart,
    required this.currentEnd,
  });
  final DateTime currentStart;
  final DateTime currentEnd;

  @override
  State<_RescheduleSheet> createState() => _RescheduleSheetState();
}

class _RescheduleSheetState extends State<_RescheduleSheet> {
  late DateTime _date;
  late TimeOfDay _time;
  final _reasonCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final start = widget.currentStart;
    // Mặc định gợi ý cùng giờ, lùi sang ngày mai để tránh chọn quá khứ.
    final base = start.isAfter(DateTime.now())
        ? start
        : DateTime.now().add(const Duration(days: 1));
    _date = DateTime(base.year, base.month, base.day);
    _time = TimeOfDay(hour: start.hour, minute: start.minute);
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  DateTime get _picked =>
      DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);

  /// Giờ mới phải ở tương lai và cách hiện tại tối thiểu bằng cutoff của BE —
  /// đề xuất sát giờ sẽ bị từ chối ở server.
  bool get _valid => _picked.isAfter(DateTime.now().add(kRescheduleCutoff));

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final duration = widget.currentEnd.difference(widget.currentStart);
    final newEnd = _picked.add(duration);

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + safeBottom + 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Đề xuất đổi lịch',
              style: GoogleFonts.bricolageGrotesque(
                fontWeight: FontWeight.w800,
                fontSize: 21,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Gia sư sẽ nhận đề xuất và phản hồi. Buổi học chỉ đổi khi gia sư đồng ý.',
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: AppColors.ink3,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            _CurrentSlot(start: widget.currentStart, end: widget.currentEnd),
            const SizedBox(height: 14),
            Text('GIỜ HỌC MỚI', style: AppTextStyles.eyebrow()),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _PickerTile(
                    icon: Icons.calendar_today_rounded,
                    label: 'Ngày',
                    value: DateFormat('EEE, dd/MM', 'vi_VN').format(_date),
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _PickerTile(
                    icon: Icons.schedule_rounded,
                    label: 'Giờ bắt đầu',
                    value: _time.format(context),
                    onTap: _pickTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.cream2,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: AppColors.ink3,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Buổi mới: ${DateFormat('dd/MM · HH:mm').format(_picked)} – ${DateFormat('HH:mm').format(newEnd)}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('LÝ DO (KHÔNG BẮT BUỘC)', style: AppTextStyles.eyebrow()),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonCtrl,
              maxLines: 3,
              maxLength: 300,
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink),
              decoration: InputDecoration(
                hintText: 'Ví dụ: hôm đó mình có lịch thi ở trường…',
                hintStyle: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.ink4,
                ),
                filled: true,
                fillColor: AppColors.cream,
                counterText: '',
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: const BorderSide(color: AppColors.line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: const BorderSide(color: AppColors.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: const BorderSide(color: AppColors.ink),
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (!_valid)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Giờ học mới phải cách hiện tại ít nhất 2 giờ.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
              ),
            PrimaryButton(
              label: 'Gửi đề xuất',
              icon: Icons.send_rounded,
              enabled: _valid,
              onTap: () => Navigator.of(context).pop((
                start: _picked,
                reason: _reasonCtrl.text.trim().isEmpty
                    ? null
                    : _reasonCtrl.text.trim(),
              )),
            ),
            const SizedBox(height: 8),
            SecondaryButton(
              label: 'Giữ nguyên lịch cũ',
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(now) ? now : _date,
      firstDate: now,
      lastDate: now.add(const Duration(days: 120)),
      locale: const Locale('vi'),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.oxblood),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.oxblood),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) setState(() => _time = picked);
  }
}

class _CurrentSlot extends StatelessWidget {
  const _CurrentSlot({required this.start, required this.end});
  final DateTime start;
  final DateTime end;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_busy_rounded, size: 15, color: AppColors.ink3),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('LỊCH HIỆN TẠI', style: AppTextStyles.eyebrow()),
                const SizedBox(height: 3),
                Text(
                  '${DateFormat('EEEE, dd/MM', 'vi_VN').format(start)} · '
                  '${DateFormat('HH:mm').format(start)} – ${DateFormat('HH:mm').format(end)}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
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

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: AppColors.ink),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label.toUpperCase(), style: AppTextStyles.eyebrow()),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
