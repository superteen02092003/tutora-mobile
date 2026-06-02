import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';
import 'package:tutora/core/constants/app_text_styles.dart';
import 'package:tutora/core/router/app_routes.dart';
import 'package:tutora/core/storage/secure_storage.dart';
import 'package:tutora/core/utils/jwt_utils.dart';
import 'package:tutora/features/auth/presentation/controllers/auth_controller.dart';
import 'package:tutora/features/parent/data/models/parent_models.dart';
import 'package:tutora/features/parent/presentation/providers/parent_provider.dart';
import 'package:tutora/features/parent/presentation/shell/parent_shell.dart';
import 'package:tutora/features/student/presentation/screens/change_password_screen.dart';
import 'package:tutora/shared/widgets/app_logo.dart';
import 'package:tutora/shared/widgets/app_toast.dart';

class ParentProfilePage extends ConsumerStatefulWidget {
  const ParentProfilePage({super.key});

  @override
  ConsumerState<ParentProfilePage> createState() => _ParentProfilePageState();
}

class _ParentProfilePageState extends ConsumerState<ParentProfilePage>
    with ParentScrollToTopMixin {
  final _scrollController = ScrollController();
  JwtClaims? _claims;

  @override
  void initState() {
    super.initState();
    unawaited(_loadClaims());
    unawaited(
      Future.microtask(
        () => ref.read(parentStudentsProvider.notifier).load(),
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      listenScrollToTop(context, 2, _scrollController);
    });
  }

  Future<void> _loadClaims() async {
    final token = await ref.read(secureStorageProvider).getAccessToken();
    if (token != null && mounted) {
      setState(() => _claims = parseJwt(token));
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _confirmLogout() {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: AppColors.paper,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
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
                  'Đăng xuất?',
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Bạn sẽ cần đăng nhập lại để sử dụng ứng dụng.',
                  style: AppTextStyles.bodySmall(),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.oxblood,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      unawaited(
                        ref.read(authControllerProvider.notifier).logout(),
                      );
                    },
                    child: Text(
                      'Đăng xuất',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Huỷ',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.ink3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final students = ref.watch(parentStudentsProvider);
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final name = _claims?.name ?? '';
    final email = _claims?.email ?? '';

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: ListView(
          controller: _scrollController,
          padding: EdgeInsets.only(bottom: bottomPad + AppSpacing.xxl),
          children: [
            _ProfileHeader(name: name, email: email),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionLabel('Con của tôi'),
                  const SizedBox(height: 6),
                  _ChildrenCard(
                    students: students.students,
                    isLoading: students.isLoading,
                  ),
                  const SizedBox(height: 14),

                  const _SectionLabel('Tiện ích'),
                  const SizedBox(height: 6),
                  _SettingsCard(
                    children: [
                      _SettingRow(
                        icon: Icons.calendar_month_outlined,
                        label: 'Lịch học tổng hợp',
                        sub: 'Toàn bộ lịch học của các con',
                        onTap: () => context.push(AppRoutes.parentCalendar),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  const _SectionLabel('Tài khoản'),
                  const SizedBox(height: 6),
                  _SettingsCard(
                    children: [
                      _SettingRow(
                        icon: Icons.lock_outline_rounded,
                        label: 'Bảo mật & Mật khẩu',
                        onTap: () => context.push(
                          '/parent/change-password',
                          extra: ChangePasswordScreen.new,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _SettingsCard(
                    children: [
                      _SettingRow(
                        icon: Icons.logout_rounded,
                        label: 'Đăng xuất',
                        danger: true,
                        onTap: _confirmLogout,
                      ),
                    ],
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

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.name, required this.email});
  final String name;
  final String email;

  @override
  Widget build(BuildContext context) {
    final initials = name
        .trim()
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0] : '')
        .take(2)
        .join();

    return Container(
      color: AppColors.cream,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              AppLogo(size: 14),
              Spacer(),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(62 / 3),
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink2,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isNotEmpty ? name : 'Phụ huynh',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                        letterSpacing: -0.01,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      email,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.ink4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cream2,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Text(
                        'Phụ huynh',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.ink3,
                        ),
                      ),
                    ),
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

class _ChildrenCard extends StatelessWidget {
  const _ChildrenCard({required this.students, required this.isLoading});
  final List<ParentStudentDto> students;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.line),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.ink),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          ...students.asMap().entries.map((e) {
            final i = e.key;
            final s = e.value;
            return Column(
              children: [
                if (i > 0)
                  const Divider(height: 1, indent: 46, color: AppColors.line),
                _StudentRow(student: s),
              ],
            );
          }),
          const Divider(height: 1, indent: 46, color: AppColors.line),
          _AddStudentRow(),
        ],
      ),
    );
  }
}

class _StudentRow extends StatelessWidget {
  const _StudentRow({required this.student});
  final ParentStudentDto student;

  @override
  Widget build(BuildContext context) {
    final initials = student.fullName
        .trim()
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0] : '')
        .take(2)
        .join();

    return InkWell(
      onTap: () => context.push(
        AppRoutes.parentStudentDetail.replaceFirst(':id', student.studentId),
      ),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink2,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.fullName,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.ink,
                    ),
                  ),
                  if (student.gradeLevel != null || student.school != null)
                    Text(
                      [
                        if (student.gradeLevel != null) student.gradeLevel!,
                        if (student.school != null) student.school!,
                      ].join(' · '),
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: AppColors.ink4,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: AppColors.ink4,
            ),
          ],
        ),
      ),
    );
  }
}

class _AddStudentRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        AppToast.show(
          context,
          message: 'Tính năng thêm con sẽ sớm ra mắt',
          type: AppToastType.info,
        );
      },
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.cream2,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.add_rounded,
                size: 16,
                color: AppColors.ink3,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Thêm con',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.ink3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.12,
          color: AppColors.ink4,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: children.asMap().entries.map((e) {
          return Column(
            children: [
              if (e.key > 0)
                const Divider(height: 1, indent: 46, color: AppColors.line),
              e.value,
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.label,
    this.sub,
    this.onTap,
    this.danger = false,
  });
  final IconData icon;
  final String label;
  final String? sub;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.oxblood : AppColors.ink;
    final iconBg = danger ? const Color(0xFFFFDEDE) : AppColors.cream2;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                  if (sub != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      sub!,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: AppColors.ink4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onTap != null)
              const Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: AppColors.ink4,
              ),
          ],
        ),
      ),
    );
  }
}
