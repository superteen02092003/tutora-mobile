import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_text_styles.dart';
import 'package:tutora/core/constants/legal_links.dart';
import 'package:tutora/features/auth/presentation/controllers/auth_controller.dart';
import 'package:tutora/features/tutor/presentation/providers/tutor_profile_provider.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_profile/tutor_change_password_screen.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_profile/tutor_delete_account_sheet.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_profile/tutor_edit_personal_info_screen.dart';
import 'package:tutora/features/tutor/presentation/widgets/settings_section.dart';
import 'package:tutora/shared/widgets/app_toast.dart';

class TutorProfileScreen extends ConsumerStatefulWidget {
  const TutorProfileScreen({super.key});

  @override
  ConsumerState<TutorProfileScreen> createState() => _TutorProfileScreenState();
}

class _TutorProfileScreenState extends ConsumerState<TutorProfileScreen> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _openLink(String url) => unawaited(_launchLink(url));

  Future<void> _launchLink(String url) async {
    final opened = await openExternalUrl(url);
    if (!opened && mounted) {
      AppToast.show(
        context,
        message: 'Không mở được liên kết.',
        type: AppToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tutorProfileProvider);
    final bottomPad = MediaQuery.of(context).padding.bottom;

    if (state.isLoading && state.user == null) {
      return const Scaffold(
        backgroundColor: AppColors.cream,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.user == null) {
      return Scaffold(
        backgroundColor: AppColors.cream,
        body: Center(
          child: TextButton.icon(
            onPressed: () => ref.read(tutorProfileProvider.notifier).load(),
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
          ),
        ),
      );
    }

    final user = state.user!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F0),
      body: Column(
        children: [
          const _TutorProfileHeader(),
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: EdgeInsets.fromLTRB(14, 14, 14, bottomPad + 100),
              children: [
                // Hồ sơ gia sư
                const SectionLabel('Hồ sơ gia sư'),
                SectionCard(
                  children: [
                    SettingRow(
                      icon: Icons.person_outline_rounded,
                      label: 'Thông tin cá nhân',
                      sub: user.email,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const TutorEditPersonalInfoScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Bảo mật
                const SectionLabel('Bảo mật'),
                SectionCard(
                  children: [
                    SettingRow(
                      icon: Icons.lock_outline_rounded,
                      label: 'Đổi mật khẩu',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const TutorChangePasswordScreen(),
                        ),
                      ),
                    ),
                    SettingRow(
                      icon: Icons.notifications_outlined,
                      label: 'Thông báo',
                      trailing: Switch(
                        value: state.notifOn,
                        onChanged: (v) {
                          ref
                              .read(tutorProfileProvider.notifier)
                              .setNotif(value: v);
                          AppToast.show(
                            context,
                            message: v
                                ? 'Đã bật thông báo'
                                : 'Đã tắt thông báo',
                            type: AppToastType.success,
                          );
                        },
                        activeThumbColor: AppColors.ink,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Pháp lý — Google Play yêu cầu link chính sách ngay trong app.
                const SectionLabel('Pháp lý'),
                SectionCard(
                  children: [
                    SettingRow(
                      icon: Icons.description_outlined,
                      label: 'Điều khoản sử dụng',
                      onTap: () => _openLink(LegalLinks.terms),
                    ),
                    SettingRow(
                      icon: Icons.privacy_tip_outlined,
                      label: 'Chính sách quyền riêng tư',
                      onTap: () => _openLink(LegalLinks.privacy),
                    ),
                    SettingRow(
                      icon: Icons.delete_outline_rounded,
                      label: 'Yêu cầu xoá dữ liệu',
                      onTap: () => _openLink(LegalLinks.dataDeletion),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                SectionCard(
                  children: [
                    SettingRow(
                      icon: Icons.logout_rounded,
                      label: 'Đăng xuất',
                      danger: true,
                      onTap: () =>
                          ref.read(authControllerProvider.notifier).logout(),
                    ),
                    SettingRow(
                      icon: Icons.person_remove_outlined,
                      label: 'Xoá tài khoản',
                      danger: true,
                      onTap: () => unawaited(showDeleteAccountSheet(context)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Header with avatar upload
class _TutorProfileHeader extends ConsumerWidget {
  const _TutorProfileHeader();

  Future<void> _pickAndUpload(
    BuildContext context,
    WidgetRef widgetRef,
    ImageSource source,
  ) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 800,
    );
    if (file == null) return;
    if (!context.mounted) return;

    final ok = await widgetRef
        .read(tutorProfileProvider.notifier)
        .uploadAvatar(file.path);
    if (!context.mounted) return;
    AppToast.show(
      context,
      message: ok
          ? 'Cập nhật ảnh đại diện thành công'
          : 'Cập nhật thất bại, thử lại sau',
      type: ok ? AppToastType.success : AppToastType.error,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tutorProfileProvider);
    final user = state.user;
    final top = MediaQuery.of(context).padding.top;
    final isUploading = state.isUploadingAvatar;

    return Container(
      color: AppColors.cream,
      padding: EdgeInsets.fromLTRB(20, top + 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                color: AppColors.ink,
                tooltip: 'Quay lại',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 36,
                  height: 36,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(child: Text('Tôi', style: AppTextStyles.h2())),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: isUploading
                    ? null
                    // Chỉ chọn từ thư viện ảnh — không dùng camera nên app
                    // không cần xin quyền CAMERA.
                    : () => unawaited(
                        _pickAndUpload(context, ref, ImageSource.gallery),
                      ),
                child: Stack(
                  children: [
                    _AvatarWidget(
                      name: user?.fullName ?? '',
                      avatarUrl: user?.avatarUrl,
                      size: 62,
                    ),
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
                      user?.fullName ?? '',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                        letterSpacing: -0.01,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      user?.email ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.ink4,
                      ),
                    ),
                    if (state.progress?.basicInfo.subjects.isNotEmpty ??
                        false) ...[
                      const SizedBox(height: 4),
                      Text(
                        state.progress!.basicInfo.subjects
                            .map((s) => s.subjectName)
                            .join(' · '),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.ink4,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AvatarWidget extends StatelessWidget {
  const _AvatarWidget({
    required this.name,
    required this.size,
    this.avatarUrl,
  });

  final String name;
  final String? avatarUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 3),
        child: Image.network(
          avatarUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          loadingBuilder: (_, child, progress) =>
              progress == null ? child : _Fallback(name: name, size: size),
          errorBuilder: (_, _, _) => _Fallback(name: name, size: size),
        ),
      );
    }
    return _Fallback(name: name, size: size);
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.name, required this.size});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().split(' ').map((w) => w[0]).take(2).join();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(size / 3),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: GoogleFonts.inter(
          fontSize: size * 0.32,
          fontWeight: FontWeight.w700,
          color: AppColors.ink2,
        ),
      ),
    );
  }
}
