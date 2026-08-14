import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/router/app_routes.dart';
import 'package:tutora/features/student/presentation/providers/profile_provider.dart';
import 'package:tutora/features/student/presentation/providers/student_access_provider.dart';
import 'package:tutora/features/student/presentation/screens/student_profile/profile_primitives.dart';
import 'package:tutora/shared/widgets/app_toast.dart';

class ProfileSettingsSection extends ConsumerWidget {
  const ProfileSettingsSection({
    required this.onEditInfo,
    required this.onChangePassword,
    required this.onLogout,
    super.key,
  });

  final VoidCallback onEditInfo;
  final VoidCallback onChangePassword;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifOn = ref.watch(profileProvider).notifOn;
    final isParentManaged = ref.watch(isParentManagedProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ProfileSectionLabel('Tài khoản'),
        ProfileSectionCard(
          children: [
            SettingRow(
              icon: Icons.person_outline_rounded,
              label: 'Chỉnh thông tin cá nhân',
              sub: ref.watch(profileProvider).profile?.email,
              onTap: onEditInfo,
            ),
            SettingRow(
              icon: Icons.lock_outline_rounded,
              label: 'Bảo mật & Mật khẩu',
              onTap: onChangePassword,
            ),
            SettingRow(
              icon: Icons.notifications_outlined,
              label: 'Thông báo',
              trailing: Switch(
                value: notifOn,
                onChanged: (v) {
                  ref.read(profileProvider.notifier).setNotif(value: v);
                  AppToast.show(
                    context,
                    message: v ? 'Đã bật thông báo' : 'Đã tắt thông báo',
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
        ProfileSectionCard(
          children: [
            if (!isParentManaged)
              SettingRow(
                icon: Icons.receipt_long_outlined,
                label: 'Booking của tôi',
                sub: 'Xem lịch sử đặt gia sư',
                onTap: () => context.push(AppRoutes.studentBookings),
              ),
            SettingRow(
              icon: Icons.auto_stories_outlined,
              label: 'Lịch sử giải toán',
              sub: 'Các bài đã hỏi Tutora',
              onTap: () => context.push(AppRoutes.studentSolveHistory),
            ),
            SettingRow(
              icon: Icons.menu_book_outlined,
              label: 'Môn học quan tâm',
              onTap: () {},
            ),
          ],
        ),
        const SizedBox(height: 14),
        ProfileSectionCard(
          children: [
            SettingRow(
              icon: Icons.logout_rounded,
              label: 'Đăng xuất',
              danger: true,
              onTap: onLogout,
            ),
          ],
        ),
      ],
    );
  }
}
