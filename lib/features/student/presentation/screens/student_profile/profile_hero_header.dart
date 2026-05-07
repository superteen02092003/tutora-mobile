import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/features/student/data/models/profile_models.dart';
import 'package:tutora/features/student/presentation/providers/profile_provider.dart';
import 'package:tutora/features/student/presentation/screens/student_profile/profile_primitives.dart';
import 'package:tutora/shared/widgets/app_logo.dart';
import 'package:tutora/shared/widgets/app_toast.dart';

class ProfileHeroHeader extends ConsumerWidget {
  const ProfileHeroHeader({required this.profile, super.key});

  final StudentProfileDto profile;

  Future<void> _pickAndUpload(
    BuildContext context,
    WidgetRef ref,
    ImageSource source,
  ) async {
    Navigator.of(context).pop();
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 800,
    );
    if (file == null) return;

    if (!context.mounted) return;
    final ok = await ref.read(profileProvider.notifier).uploadAvatar(file.path);
    if (!context.mounted) return;

    AppToast.show(
      context,
      message: ok
          ? 'Cập nhật ảnh đại diện thành công'
          : 'Cập nhật thất bại, thử lại sau',
      type: ok ? AppToastType.success : AppToastType.error,
    );
  }

  void _showAvatarPicker(BuildContext context, WidgetRef ref) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: AppColors.paper,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Ảnh đại diện',
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 16),
                _PickerOption(
                  icon: Icons.camera_alt_outlined,
                  label: 'Chụp ảnh',
                  onTap: () => _pickAndUpload(context, ref, ImageSource.camera),
                ),
                const Divider(height: 1, color: AppColors.line),
                _PickerOption(
                  icon: Icons.photo_library_outlined,
                  label: 'Chọn từ thư viện',
                  onTap: () =>
                      _pickAndUpload(context, ref, ImageSource.gallery),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUploading = ref.watch(profileProvider).isUploadingAvatar;
    return Container(
      color: AppColors.cream,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppLogo(size: 14),
              const Spacer(),
              GestureDetector(
                onTap: () => AppToast.show(context, message: 'Đang phát triển'),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.paper,
                    border: Border.all(color: AppColors.line),
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 16,
                    color: AppColors.ink3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              GestureDetector(
                onTap: isUploading
                    ? null
                    : () => _showAvatarPicker(context, ref),
                child: Stack(
                  children: [
                    _AvatarWidget(profile: profile, size: 62),
                    if (isUploading)
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(62 / 3),
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.45),
                            alignment: Alignment.center,
                            child: const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: AppColors.ink,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.cream,
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            size: 11,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.fullName,
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                        letterSpacing: -0.01,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      profile.address.isNotEmpty
                          ? profile.address
                          : profile.email,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.ink4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    JoinedChip(
                      label: 'Tham gia ${formatJoined(profile.createdAt)}',
                    ),
                  ],
                ),
              ),
            ],
          ),
          // api required for real stats
          // const SizedBox(height: 18),
          // Container(
          //   decoration: BoxDecoration(
          //     color: AppColors.cream2,
          //     borderRadius: BorderRadius.circular(AppRadius.md),
          //     border: Border.all(color: AppColors.line),
          //   ),
          //   child: Row(
          //     children: [
          //       ProfileStatCell(value: '${profile.totalSessions}', label: 'Buổi học', borderRight: true),
          //       ProfileStatCell(value: '${profile.totalHours}h', label: 'Tổng giờ', borderRight: true),
          //       ProfileStatCell(value: '${profile.tutorCount}', label: 'Gia sư', borderRight: false),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }
}

class _AvatarWidget extends StatelessWidget {
  const _AvatarWidget({required this.profile, required this.size});

  final StudentProfileDto profile;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (profile.avatarUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 3),
        child: Image.network(
          profile.avatarUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          loadingBuilder: (_, child, progress) => progress == null
              ? child
              : ProfileAvatar(name: profile.fullName, size: size),
          errorBuilder: (_, _, _) =>
              ProfileAvatar(name: profile.fullName, size: size),
        ),
      );
    }
    return ProfileAvatar(name: profile.fullName, size: size);
  }
}

class _PickerOption extends StatelessWidget {
  const _PickerOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.cream2,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: AppColors.ink2),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
