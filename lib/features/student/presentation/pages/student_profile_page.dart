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
import 'package:tutora/shared/widgets/app_logo.dart';
import 'package:tutora/shared/widgets/status_chip.dart';
import 'package:tutora/shared/widgets/user_avatar.dart';

class StudentProfilePage extends ConsumerWidget {
  const StudentProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<String?>(
      future: ref.read(secureStorageProvider).getAccessToken(),
      builder: (context, snap) {
        final claims = snap.hasData && snap.data != null
            ? parseJwt(snap.data!)
            : null;
        return _ProfileContent(
          name: claims?.name ?? '',
          email: claims?.email ?? '',
        );
      },
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.name, required this.email});

  final String name;
  final String email;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const _TopBar(),
                  _ProfileHero(name: name, email: email),
                  const _StatsRow(),
                  const SizedBox(height: AppSpacing.md),
                  const _MenuSection(),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, bottomInset + 16),
              child: const _LogoutButton(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Top bar ────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          const AppLogo(size: 13),
          const Spacer(),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.paper,
              border: Border.all(color: AppColors.line),
            ),
            child: const Icon(
              Icons.settings_outlined,
              size: 16,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Profile hero ───────────────────────────────────────────────────────────
class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.name, required this.email});

  final String name;
  final String email;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        children: [
          UserAvatar(name: name.isNotEmpty ? name : 'Học sinh', size: 88),
          const SizedBox(height: 14),
          Text(
            name.isNotEmpty ? name : 'Học sinh',
            style: GoogleFonts.bricolageGrotesque(
              fontWeight: FontWeight.w800,
              fontSize: 24,
              color: AppColors.ink,
            ),
          ),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(email, style: AppTextStyles.bodySmall()),
          ],
          const SizedBox(height: 10),
          const StatusChip(label: 'Học sinh', tone: ChipTone.ox),
        ],
      ),
    );
  }
}

// ── Stats row ──────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(value: '14', label: 'Buổi học'),
          ),
          SizedBox(width: 8),
          Expanded(
            child: _StatCard(value: '37', label: 'Bài quét'),
          ),
          SizedBox(width: 8),
          Expanded(
            child: _StatCard(value: '3', label: 'Gia sư'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.bricolageGrotesque(
              fontWeight: FontWeight.w800,
              fontSize: 22,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.eyebrow()),
        ],
      ),
    );
  }
}

// ── Menu section ───────────────────────────────────────────────────────────
class _MenuSection extends StatelessWidget {
  const _MenuSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text('TÀI KHOẢN', style: AppTextStyles.eyebrow()),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.line),
          ),
          child: const Column(
            children: [
              _MenuItem(
                icon: Icons.person_outline_rounded,
                label: 'Thông tin cá nhân',
                isFirst: true,
              ),
              _MenuDivider(),
              _MenuItem(
                icon: Icons.receipt_long_outlined,
                label: 'Lịch sử thanh toán',
              ),
              _MenuDivider(),
              _MenuItem(
                icon: Icons.notifications_outlined,
                label: 'Cài đặt thông báo',
              ),
              _MenuDivider(),
              _MenuItem(
                icon: Icons.help_outline_rounded,
                label: 'Trợ giúp & hỗ trợ',
                isLast: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    this.isFirst = false,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(AppRadius.lg) : Radius.zero,
        bottom: isLast ? const Radius.circular(AppRadius.lg) : Radius.zero,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.ink2),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(label, style: AppTextStyles.label()),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: AppColors.ink3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuDivider extends StatelessWidget {
  const _MenuDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 46),
      child: Divider(height: 1, color: AppColors.line),
    );
  }
}

// ── Logout button ──────────────────────────────────────────────────────────
class _LogoutButton extends ConsumerWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () async {
        await ref.read(secureStorageProvider).clearTokens();
        if (context.mounted) context.go(AppRoutes.login);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.logout_rounded,
              size: 16,
              color: AppColors.oxblood,
            ),
            const SizedBox(width: 8),
            Text(
              'Đăng xuất',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.oxblood,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
