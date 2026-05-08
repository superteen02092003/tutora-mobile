import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/utils/format_utils.dart';
import 'package:tutora/features/tutor/data/models/tutor_profile_models.dart';
import 'package:tutora/features/tutor/presentation/providers/tutor_profile_provider.dart';
import 'package:tutora/features/tutor/presentation/widgets/tutor_form_widgets.dart';
import 'package:tutora/shared/widgets/app_toast.dart';

class TutorVerificationProgressScreen extends ConsumerWidget {
  const TutorVerificationProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tutorProfileProvider);
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            TutorScreenHeader(
              title: 'Tiến trình xác minh',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: EdgeInsets.fromLTRB(20, 24, 20, bottomPad + 40),
                      children: [
                        if (state.progress != null) ...[
                          _ProgressHeader(progress: state.progress!),
                          const SizedBox(height: 20),
                          _SectionItem(
                            icon: Icons.play_circle_outline_rounded,
                            title: 'Video giới thiệu',
                            isUpdated: state.progress!.video.isUpdated,
                          ),
                          _SectionItem(
                            icon: Icons.person_outline_rounded,
                            title: 'Thông tin cơ bản',
                            isUpdated: state.progress!.basicInfo.isUpdated,
                            subtitle: state.progress!.basicInfo.headline,
                          ),
                          _SectionItem(
                            icon: Icons.menu_book_outlined,
                            title: 'Giới thiệu & kinh nghiệm',
                            isUpdated: state.progress!.introduction.isUpdated,
                          ),
                          _SectionItem(
                            icon: Icons.workspace_premium_outlined,
                            title: 'Chứng chỉ & bằng cấp',
                            isUpdated: state.progress!.certificates.isUpdated,
                            subtitle:
                                '${state.progress!.certificates.totalCount} chứng chỉ',
                          ),
                          _SectionItem(
                            icon: Icons.badge_outlined,
                            title: 'Xác thực danh tính (CCCD)',
                            isUpdated: state.progress!.identityCard.isUpdated,
                          ),
                          _SectionItem(
                            icon: Icons.attach_money_rounded,
                            title: 'Giá dạy',
                            isUpdated: state.progress!.pricing.isUpdated,
                            subtitle: state.progress!.pricing.hourlyRate > 0
                                ? '${fmtVnd(state.progress!.pricing.hourlyRate)} đ/giờ'
                                : null,
                          ),
                          const SizedBox(height: 24),
                          if (state.progress!.isComplete)
                            _SubmitButton(
                              saving: state.isSaving,
                              onSubmit: () async {
                                final ok = await ref
                                    .read(tutorProfileProvider.notifier)
                                    .submitForReview();
                                if (!context.mounted) return;
                                AppToast.show(
                                  context,
                                  message: ok
                                      ? 'Đã nộp hồ sơ, chờ admin duyệt'
                                      : 'Nộp thất bại, thử lại sau',
                                  type: ok
                                      ? AppToastType.success
                                      : AppToastType.error,
                                );
                              },
                            )
                          else
                            _IncompleteNotice(),
                        ] else
                          Center(
                            child: TextButton.icon(
                              onPressed: () => ref
                                  .read(tutorProfileProvider.notifier)
                                  .load(),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Thử lại'),
                            ),
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

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.progress});
  final TutorVerificationProgressDto progress;

  int get _completedCount {
    return [
      progress.video.isUpdated,
      progress.basicInfo.isUpdated,
      progress.introduction.isUpdated,
      progress.certificates.isUpdated,
      progress.identityCard.isUpdated,
      progress.pricing.isUpdated,
    ].where((v) => v).length;
  }

  @override
  Widget build(BuildContext context) {
    const total = 6;
    final completed = _completedCount;
    final pct = completed / total;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Hoàn thành hồ sơ',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              const Spacer(),
              Text(
                '$completed/$total',
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: progress.isComplete ? AppColors.green : AppColors.ink3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: AppColors.cream2,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress.isComplete ? AppColors.green : AppColors.gold,
              ),
            ),
          ),
          if (progress.isComplete) ...[
            const SizedBox(height: 8),
            Text(
              'Hồ sơ đã đầy đủ — sẵn sàng nộp để admin duyệt',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionItem extends StatelessWidget {
  const _SectionItem({
    required this.icon,
    required this.title,
    required this.isUpdated,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final bool isUpdated;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUpdated
              ? AppColors.green.withValues(alpha: 0.3)
              : AppColors.line,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isUpdated
                  ? AppColors.green.withValues(alpha: 0.1)
                  : AppColors.cream2,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 18,
              color: isUpdated ? AppColors.green : AppColors.ink3,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ink,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: AppColors.ink4,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Icon(
            isUpdated
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 20,
            color: isUpdated ? AppColors.green : AppColors.line,
          ),
        ],
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({required this.saving, required this.onSubmit});
  final bool saving;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: saving ? null : onSubmit,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.green,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                'Nộp hồ sơ để duyệt',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}

class _IncompleteNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: AppColors.ink3,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Hoàn thiện tất cả các mục để có thể nộp hồ sơ xác minh',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink3),
            ),
          ),
        ],
      ),
    );
  }
}
