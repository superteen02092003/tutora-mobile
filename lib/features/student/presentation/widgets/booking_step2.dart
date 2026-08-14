import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';
import 'package:tutora/core/constants/app_text_styles.dart';
import 'package:tutora/features/student/presentation/widgets/booking_form.dart';
import 'package:tutora/features/student/presentation/widgets/booking_shared.dart';

class BookingStep2 extends StatelessWidget {
  const BookingStep2({required this.form, required this.onChanged, super.key});

  final BookingForm form;
  final ValueChanged<BookingForm> onChanged;

  // Hệ thống mới chỉ dạy online ngay trong app (Agora); 2 hình thức còn lại
  // để đó cho thấy lộ trình nhưng chưa bấm được.
  static const List<({String key, IconData icon, String label, bool enabled})>
  _modes = [
    (
      key: 'online',
      icon: Icons.videocam_rounded,
      label: 'Học Online',
      enabled: true,
    ),
    (
      key: 'offline',
      icon: Icons.home_rounded,
      label: 'Học tại nhà',
      enabled: false,
    ),
    (
      key: 'hybrid',
      icon: Icons.swap_horiz_rounded,
      label: 'Kết hợp',
      enabled: false,
    ),
  ];

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const BookingSectionTitle('Hình thức học'),
      const SizedBox(height: 8),
      ..._modes.map((m) {
        final sel = form.teachingMode == m.key;
        final off = !m.enabled;
        return GestureDetector(
          onTap: off
              ? null
              : () => onChanged(form.copyWith(teachingMode: m.key)),
          child: Opacity(
            opacity: off ? 0.5 : 1,
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: sel
                    ? AppColors.ink.withValues(alpha: 0.04)
                    : AppColors.paper,
                border: Border.all(
                  color: sel ? AppColors.ink : AppColors.line,
                  width: sel ? 1.5 : 1,
                ),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: sel ? AppColors.ink : AppColors.cream,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      m.icon,
                      size: 20,
                      color: sel ? AppColors.gold : AppColors.ink3,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      m.label,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  if (off)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cream2,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Text(
                        'Chưa hỗ trợ',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink3,
                        ),
                      ),
                    )
                  else if (sel)
                    Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.gold,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 13,
                        color: AppColors.ink,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }),
      if (form.needsLocation) ...[
        const SizedBox(height: 8),
        const BookingSectionTitle('Địa điểm học'),
        const SizedBox(height: 8),
        _LocationField(
          label: 'Tỉnh / Thành phố *',
          hint: 'VD: Hồ Chí Minh',
          value: form.locationCity,
          onChanged: (v) => onChanged(form.copyWith(locationCity: v)),
        ),
        const SizedBox(height: 10),
        _LocationField(
          label: 'Quận / Huyện *',
          hint: 'VD: Quận 1',
          value: form.locationDistrict,
          onChanged: (v) => onChanged(form.copyWith(locationDistrict: v)),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _LocationField(
                label: 'Phường / Xã',
                hint: 'VD: Phường Bến Nghé',
                value: form.locationWard,
                onChanged: (v) => onChanged(form.copyWith(locationWard: v)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _LocationField(
                label: 'Địa chỉ chi tiết',
                hint: 'VD: 123 Nguyễn Huệ',
                value: form.locationDetail,
                onChanged: (v) => onChanged(form.copyWith(locationDetail: v)),
              ),
            ),
          ],
        ),
      ],
    ],
  );
}

class _LocationField extends StatelessWidget {
  const _LocationField({
    required this.label,
    required this.hint,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final String hint;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: AppTextStyles.eyebrow()),
      const SizedBox(height: 4),
      TextFormField(
        initialValue: value,
        onChanged: onChanged,
        style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.ink4),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: const BorderSide(color: AppColors.line),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: const BorderSide(color: AppColors.line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: const BorderSide(color: AppColors.ink),
          ),
        ),
      ),
    ],
  );
}
