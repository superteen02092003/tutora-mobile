import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_text_styles.dart';
import 'package:tutora/core/utils/format_utils.dart';
import 'package:tutora/features/auth/presentation/controllers/auth_controller.dart';
import 'package:tutora/features/tutor/presentation/providers/tutor_profile_provider.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_profile/tutor_certificates_screen.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_profile/tutor_change_password_screen.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_profile/tutor_edit_intro_screen.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_profile/tutor_edit_personal_info_screen.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_profile/tutor_edit_pricing_screen.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_profile/tutor_verification_progress_screen.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_schedule/tutor_availability_screen.dart';
import 'package:tutora/features/tutor/presentation/shell/tutor_shell.dart';
import 'package:tutora/features/tutor/presentation/widgets/settings_section.dart';
import 'package:tutora/shared/widgets/app_toast.dart';
import 'package:tutora/shared/widgets/web_only_banner.dart';

class TutorProfileScreen extends ConsumerStatefulWidget {
  const TutorProfileScreen({super.key});

  @override
  ConsumerState<TutorProfileScreen> createState() => _TutorProfileScreenState();
}

class _TutorProfileScreenState extends ConsumerState<TutorProfileScreen>
    with TutorScrollToTopMixin {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      listenScrollToTop(context, 4, _scrollController);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
                // Wallet shortcut
                _WalletBanner(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          const WebOnlyScreen(title: 'Ví & tài chính'),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

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
                    SettingRow(
                      icon: Icons.menu_book_outlined,
                      label: 'Giới thiệu & kinh nghiệm',
                      sub: 'Thông tin về trình độ, kinh nghiệm giảng dạy, v.v.',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const TutorEditIntroScreen(),
                        ),
                      ),
                    ),
                    SettingRow(
                      icon: Icons.attach_money_rounded,
                      label: 'Giá dạy',
                      sub: (state.progress?.pricing.hourlyRate ?? 0) > 0
                          ? '${fmtVnd(state.progress!.pricing.hourlyRate)} đ/giờ'
                          : 'Chưa cập nhật',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const TutorEditPricingScreen(),
                        ),
                      ),
                    ),
                    SettingRow(
                      icon: Icons.workspace_premium_outlined,
                      label: 'Chứng chỉ & bằng cấp',
                      sub:
                          '${state.progress?.certificates.totalCount ?? 0} chứng chỉ',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const TutorCertificatesScreen(),
                        ),
                      ),
                    ),
                    SettingRow(
                      icon: Icons.verified_outlined,
                      label: 'Tiến trình xác minh',
                      sub: (state.progress?.isComplete ?? false)
                          ? 'Đã hoàn thành hồ sơ'
                          : 'Chưa hoàn thiện',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              const TutorVerificationProgressScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Booking & đánh giá (web-only)
                const SectionLabel('Yêu cầu & đánh giá'),
                SectionCard(
                  children: [
                    SettingRow(
                      icon: Icons.event_available_outlined,
                      label: 'Yêu cầu đặt lịch',
                      sub: 'Xem trên web để chấp nhận hoặc từ chối',
                      trailing: const _WebBadge(),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const WebOnlyScreen(
                            title: 'Yêu cầu đặt lịch',
                          ),
                        ),
                      ),
                    ),
                    SettingRow(
                      icon: Icons.star_outline_rounded,
                      label: 'Đánh giá từ phụ huynh',
                      sub: 'Xem trên web để xem và trả lời đánh giá',
                      trailing: const _WebBadge(),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const WebOnlyScreen(
                            title: 'Đánh giá của tôi',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Lịch dạy
                const SectionLabel('Lịch dạy'),
                SectionCard(
                  children: [
                    SettingRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Khung giờ rảnh',
                      sub: 'Cài đặt ngày & giờ có thể dạy',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const TutorAvailabilityScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Tài chính
                const SectionLabel('Tài chính'),
                SectionCard(
                  children: [
                    SettingRow(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Tài khoản ngân hàng',
                      onTap: () => AppToast.show(
                        context,
                        message: 'Đang phát triển',
                      ),
                    ),
                    SettingRow(
                      icon: Icons.south_rounded,
                      label: 'Lịch sử rút tiền',
                      trailing: const _WebBadge(),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const WebOnlyScreen(
                            title: 'Lịch sử rút tiền',
                          ),
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

                SectionCard(
                  children: [
                    SettingRow(
                      icon: Icons.logout_rounded,
                      label: 'Đăng xuất',
                      danger: true,
                      onTap: () =>
                          ref.read(authControllerProvider.notifier).logout(),
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

  void _showAvatarPicker(BuildContext context, WidgetRef widgetRef) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        useRootNavigator: true,
        backgroundColor: AppColors.paper,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (sheetCtx) => SafeArea(
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
                  onTap: () {
                    Navigator.of(sheetCtx).pop();
                    unawaited(
                      _pickAndUpload(context, widgetRef, ImageSource.camera),
                    );
                  },
                ),
                const Divider(height: 1, color: AppColors.line),
                _PickerOption(
                  icon: Icons.photo_library_outlined,
                  label: 'Chọn từ thư viện',
                  onTap: () {
                    Navigator.of(sheetCtx).pop();
                    unawaited(
                      _pickAndUpload(context, widgetRef, ImageSource.gallery),
                    );
                  },
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tôi', style: AppTextStyles.h2()),
              // placeholder for settings icon
              const SizedBox(width: 36),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: isUploading
                    ? null
                    : () => _showAvatarPicker(context, ref),
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

// Wallet banner shortcut
class _WalletBanner extends StatelessWidget {
  const _WalletBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.account_balance_wallet_outlined,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Ví gia sư',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white54,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _WebBadge extends StatelessWidget {
  const _WebBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.cream2,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.laptop_rounded, size: 11, color: AppColors.ink3),
          const SizedBox(width: 3),
          Text(
            'Web',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.ink3,
            ),
          ),
        ],
      ),
    );
  }
}
