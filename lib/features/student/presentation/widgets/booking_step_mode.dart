import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';
import 'package:tutora/features/student/presentation/widgets/booking_constants.dart';
import 'package:tutora/features/student/presentation/widgets/booking_form.dart';
import 'package:tutora/features/student/presentation/widgets/booking_shared.dart';
import 'package:tutora/features/tutor_search/data/models/tutor_detail_models.dart';

/// Bước 2 — tự chọn giờ rảnh hoặc lấy nguyên gói cố định của gia sư.
class BookingStepMode extends StatelessWidget {
  const BookingStepMode({
    required this.form,
    required this.profile,
    required this.onChanged,
    super.key,
  });

  final BookingForm form;
  final TutorFullProfileDto profile;
  final ValueChanged<BookingForm> onChanged;

  @override
  Widget build(BuildContext context) {
    final packages = profile.fixedPackages;
    final hasPackages = packages.isNotEmpty;
    final isManual = form.bookingMode == BookingMode.manual;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BookingSectionTitle('Cách đặt lịch'),
        const SizedBox(height: 10),
        _ModeCard(
          icon: Icons.touch_app_rounded,
          iconColor: const Color(0xFF3D6B4A),
          title: 'Tự chọn lịch',
          subtitle: 'Bạn chọn ngày và giờ trong lịch rảnh của gia sư.',
          selected: isManual,
          onTap: () => onChanged(
            form.copyWith(bookingMode: BookingMode.manual, clearPackage: true),
          ),
        ),
        const SizedBox(height: 10),
        _ModeCard(
          icon: Icons.workspace_premium_rounded,
          iconColor: const Color(0xFF8A5A2B),
          title: 'Chọn gói cố định',
          subtitle: hasPackages
              ? 'Lấy nguyên lịch gia sư đã sắp sẵn, không cần chọn từng buổi.'
              : 'Gia sư này chưa tạo gói cố định nào.',
          selected: !isManual,
          disabled: !hasPackages,
          onTap: hasPackages
              ? () => onChanged(form.copyWith(bookingMode: BookingMode.package))
              : null,
        ),

        if (!isManual && hasPackages) ...[
          const SizedBox(height: 24),
          const BookingSectionTitle('Chọn gói'),
          const SizedBox(height: 10),
          ...packages.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PackageCard(
                package: p,
                selected: form.selectedPackage?.packageId == p.packageId,
                onTap: () => onChanged(form.copyWith(selectedPackage: p)),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.disabled = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool selected;
  final bool disabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: disabled ? 0.55 : 1,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.ink.withValues(alpha: 0.04)
                : Colors.white,
            border: Border.all(
              color: selected ? AppColors.ink : AppColors.line,
              width: selected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: selected ? AppColors.ink : AppColors.cream2,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: selected ? AppColors.gold : iconColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        height: 1.45,
                        color: AppColors.ink3,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 10),
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.gold,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 15,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Thẻ gói cố định — hiện đủ buổi trong tuần trước khi chọn.
class _PackageCard extends StatelessWidget {
  const _PackageCard({
    required this.package,
    required this.selected,
    required this.onTap,
  });

  final TutorPackageDto package;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // fixedSlots lưu UTC — phải quy về giờ local, nếu không ở VN sẽ lệch 7 tiếng.
    final slots =
        package.fixedSlots
            .map(
              (s) => fixedSlotToLocal(
                isoDayOfWeek: s.dayOfWeek,
                startUtc: s.startTime,
                endUtc: s.endTime,
              ),
            )
            .toList()
          ..sort((a, b) {
            final d = a.dayOfWeek.compareTo(b.dayOfWeek);
            return d != 0
                ? d
                : toMins(a.startTime).compareTo(toMins(b.startTime));
          });

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.ink.withValues(alpha: 0.04)
              : Colors.white,
          border: Border.all(
            color: selected ? AppColors.ink : AppColors.line,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    package.name?.trim().isNotEmpty ?? false
                        ? package.name!.trim()
                        : 'Gói cố định',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                if (selected)
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.gold,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 15,
                      color: AppColors.ink,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${slots.length} buổi mỗi tuần',
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.ink3),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: slots
                  .map(
                    (s) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cream2,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Text(
                        '${kDayNames[s.dayOfWeek]} · '
                        '${s.startTime}–${s.endTime}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
