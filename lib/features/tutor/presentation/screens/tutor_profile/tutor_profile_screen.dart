import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_text_styles.dart';
import 'package:tutora/features/auth/presentation/controllers/auth_controller.dart';
import 'package:tutora/features/tutor/data/datasources/tutor_profile_datasource.dart';
import 'package:tutora/features/tutor/presentation/providers/tutor_booking_provider.dart';
import 'package:tutora/features/tutor/presentation/providers/tutor_dispute_provider.dart';
import 'package:tutora/features/tutor/presentation/providers/tutor_profile_provider.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_bookings/tutor_booking_requests_screen.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_disputes/tutor_disputes_screen.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_feedbacks/tutor_feedbacks_screen.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_profile/tutor_change_password_screen.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_profile/tutor_edit_personal_info_screen.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_wallet/tutor_bank_account_screen.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_wallet/tutor_wallet_screen.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_wallet/tutor_withdrawals_screen.dart';
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
                      builder: (_) => const TutorWalletScreen(),
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
                  ],
                ),
                const SizedBox(height: 14),

                // Booking & đánh giá
                const SectionLabel('Yêu cầu & đánh giá'),
                SectionCard(
                  children: [
                    const _AcceptingBookingsRow(),
                    SettingRow(
                      icon: Icons.event_available_outlined,
                      label: 'Yêu cầu đặt lịch',
                      sub: 'Nhận hoặc từ chối yêu cầu từ phụ huynh',
                      trailing: const _PendingBookingBadge(),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const TutorBookingRequestsScreen(),
                        ),
                      ),
                    ),
                    SettingRow(
                      icon: Icons.star_outline_rounded,
                      label: 'Đánh giá từ phụ huynh',
                      sub: 'Trả lời đánh giá trên web',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const TutorFeedbacksScreen(),
                        ),
                      ),
                    ),
                    SettingRow(
                      icon: Icons.gavel_rounded,
                      label: 'Khiếu nại',
                      sub: 'Phản hồi khiếu nại về buổi dạy của bạn',
                      trailing: const _OpenDisputeBadge(),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const TutorDisputesScreen(),
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
                      icon: Icons.account_balance_outlined,
                      label: 'Tài khoản ngân hàng',
                      sub: 'Nơi nhận tiền khi rút',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const TutorBankAccountScreen(),
                        ),
                      ),
                    ),
                    SettingRow(
                      icon: Icons.south_rounded,
                      label: 'Lịch sử rút tiền',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const TutorWithdrawalsScreen(),
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

/// Công tắc tạm dừng nhận yêu cầu đặt lịch mới.
///
/// Khi tắt, gia sư bị ẩn khỏi marketplace — nói rõ điều đó ở phụ đề vì đây là
/// hệ quả không hiển nhiên từ chữ "tạm dừng".
class _AcceptingBookingsRow extends ConsumerStatefulWidget {
  const _AcceptingBookingsRow();

  @override
  ConsumerState<_AcceptingBookingsRow> createState() =>
      _AcceptingBookingsRowState();
}

class _AcceptingBookingsRowState extends ConsumerState<_AcceptingBookingsRow> {
  bool _saving = false;

  Future<void> _toggle({required bool value}) async {
    setState(() => _saving = true);
    try {
      await ref
          .read(tutorProfileDatasourceProvider)
          .setAcceptingBookings(accepting: value);
      if (!mounted) return;
      ref.invalidate(tutorSelfProfileProvider);
      AppToast.show(
        context,
        message: value
            ? 'Đã mở nhận yêu cầu đặt lịch.'
            : 'Đã tạm dừng. Bạn sẽ không hiện trong tìm kiếm.',
        type: AppToastType.success,
      );
    } catch (_) {
      if (mounted) {
        AppToast.show(
          context,
          message: 'Không đổi được trạng thái. Thử lại sau.',
          type: AppToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(tutorSelfProfileProvider);
    final accepting = profile.valueOrNull?.isAcceptingBookings ?? true;
    final ready = profile.hasValue && !_saving;

    return SettingRow(
      icon: accepting
          ? Icons.toggle_on_rounded
          : Icons.pause_circle_outline_rounded,
      label: 'Nhận yêu cầu mới',
      sub: accepting
          ? 'Đang hiện trong tìm kiếm của phụ huynh'
          : 'Đang tạm dừng, bạn bị ẩn khỏi tìm kiếm',
      trailing: Switch(
        value: accepting,
        onChanged: ready ? (v) => _toggle(value: v) : null,
      ),
    );
  }
}

/// Badge số việc cần xử lý ở cuối một hàng cài đặt. Khi không có việc nào thì
/// hiện mũi tên thường — badge chỉ xuất hiện lúc thật sự cần gia sư hành động.
class _CountBadge extends StatelessWidget {
  const _CountBadge(this.count);

  final int count;

  @override
  Widget build(BuildContext context) {
    if (count == 0) {
      return const Icon(
        Icons.chevron_right_rounded,
        size: 18,
        color: AppColors.ink4,
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.oxblood,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.paper,
        ),
      ),
    );
  }
}

class _OpenDisputeBadge extends ConsumerWidget {
  const _OpenDisputeBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      _CountBadge(ref.watch(openDisputeCountProvider));
}

class _PendingBookingBadge extends ConsumerWidget {
  const _PendingBookingBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      _CountBadge(ref.watch(pendingBookingsProvider).length);
}
