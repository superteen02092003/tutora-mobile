import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';
import 'package:tutora/core/constants/app_text_styles.dart';
import 'package:tutora/features/auth/presentation/controllers/auth_controller.dart';
import 'package:tutora/mock/student_profile_mock.dart';
import 'package:tutora/shared/widgets/app_logo.dart';

class StudentProfilePage extends ConsumerStatefulWidget {
  const StudentProfilePage({super.key});

  @override
  ConsumerState<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends ConsumerState<StudentProfilePage> {
  bool _notifOn = true;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.only(bottom: bottomPad + AppSpacing.xxl),
          children: [
            _HeroHeader(
              notifOn: _notifOn,
              onNotifToggle: (v) => setState(() => _notifOn = v),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _WalletCard(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const _StudentWalletScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const _SectionLabel('Lịch sử học gần đây'),
                  _RecentHistoryCard(
                    onViewAll: () {},
                  ),
                  const SizedBox(height: 14),
                  const _SectionLabel('Tài khoản'),
                  _SectionCard(
                    children: [
                      _SettingRow(
                        icon: Icons.person_outline_rounded,
                        label: 'Chỉnh thông tin cá nhân',
                        sub: kStudentProfile.email,
                        onTap: () {},
                      ),
                      _SettingRow(
                        icon: Icons.lock_outline_rounded,
                        label: 'Bảo mật & Mật khẩu',
                        onTap: () {},
                      ),
                      _SettingRow(
                        icon: Icons.notifications_outlined,
                        label: 'Thông báo',
                        trailing: Switch(
                          value: _notifOn,
                          onChanged: (v) => setState(() => _notifOn = v),
                          activeThumbColor: AppColors.ink,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    children: [
                      _SettingRow(
                        icon: Icons.menu_book_outlined,
                        label: 'Môn học quan tâm',
                        sub: kStudentProfile.subjects.join(', '),
                        onTap: () {},
                      ),
                      _SettingRow(
                        icon: Icons.language_outlined,
                        label: 'Ngôn ngữ',
                        sub: 'Tiếng Việt',
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    children: [
                      _SettingRow(
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
      ),
    );
  }
}

// Hero header with avatar + stats

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.notifOn, required this.onNotifToggle});

  final bool notifOn;
  final ValueChanged<bool> onNotifToggle;

  @override
  Widget build(BuildContext context) {
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
                  color: AppColors.ink3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _Avatar(name: kStudentProfile.name, size: 62),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kStudentProfile.name,
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                        letterSpacing: -0.01,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${kStudentProfile.grade} · ${kStudentProfile.school}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.ink4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _JoinedChip(label: 'Tham gia ${kStudentProfile.joined}'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            decoration: BoxDecoration(
              color: AppColors.cream2,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              children: [
                _StatCell(
                  value: '${kStudentProfile.totalSessions}',
                  label: 'Buổi học',
                  borderRight: true,
                ),
                _StatCell(
                  value: '${kStudentProfile.totalHours}h',
                  label: 'Tổng giờ',
                  borderRight: true,
                ),
                _StatCell(
                  value: '${kStudentProfile.tutorCount}',
                  label: 'Gia sư',
                  borderRight: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.value,
    required this.label,
    required this.borderRight,
  });

  final String value;
  final String label;
  final bool borderRight;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          border: borderRight
              ? const Border(right: BorderSide(color: AppColors.line))
              : null,
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.ibmPlexMono(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
                height: 1,
              ),
            ),
            const SizedBox(height: 3),
            Text(label, style: AppTextStyles.eyebrow()),
          ],
        ),
      ),
    );
  }
}

// Wallet card (student)

class _WalletCard extends StatelessWidget {
  const _WalletCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final w = kStudentProfile.wallet;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 16,
                  color: AppColors.gold,
                ),
                const SizedBox(width: 8),
                Text(
                  'VÍ HỌC SINH',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ),
                const Spacer(),
                Text(
                  'Chi tiết',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 14,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              '${_fmt(w.balance)} ₫',
              style: GoogleFonts.ibmPlexMono(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.cream,
                letterSpacing: -0.02,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Số dư khả dụng',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${w.escrow ~/ 1000}k ₫',
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Đang giữ escrow',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: Colors.white.withValues(alpha: 0.1),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${kStudentProfile.totalSessions}',
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.cream,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Buổi đã học',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _WalletBtn(
                  label: 'Nạp tiền',
                  icon: Icons.add_rounded,
                  gold: true,
                  onTap: () {},
                ),
                const SizedBox(width: 8),
                _WalletBtn(
                  label: 'Lịch sử',
                  icon: Icons.history_rounded,
                  gold: false,
                  onTap: onTap,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletBtn extends StatelessWidget {
  const _WalletBtn({
    required this.label,
    required this.icon,
    required this.gold,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool gold;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: gold
                ? AppColors.gold.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: gold ? AppColors.gold : AppColors.cream,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: gold ? AppColors.gold : AppColors.cream,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Recent history section

class _RecentHistoryCard extends StatelessWidget {
  const _RecentHistoryCard({required this.onViewAll});

  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final items = kStudentProfile.history.take(3).toList();
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          ...items.asMap().entries.map((e) {
            final i = e.key;
            final h = e.value;
            return Column(
              children: [
                if (i > 0)
                  const Divider(height: 1, indent: 46, color: AppColors.line),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      _InitialsAvatar(name: h.tutorName, size: 36),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              h.subject,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              '${h.tutorName} · ${h.date} · ${h.hours}h',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.ink4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        h.refunded ? 'Hoàn tiền' : '${h.amount ~/ 1000}k ₫',
                        style: GoogleFonts.ibmPlexMono(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: h.refunded ? AppColors.oxblood : AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
          GestureDetector(
            onTap: onViewAll,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: const BoxDecoration(
                color: AppColors.cream2,
                border: Border(top: BorderSide(color: AppColors.line)),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(AppRadius.md),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Xem tất cả',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink3,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 14,
                    color: AppColors.ink4,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Settings primitives

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 6),
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.children});

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
          final i = e.key;
          final child = e.value;
          return Column(
            children: [
              if (i > 0)
                const Divider(height: 1, indent: 46, color: AppColors.line),
              child,
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
    this.trailing,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final String? sub;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = danger ? AppColors.oxblood : AppColors.ink;
    final iconBg = danger ? const Color(0xFFFFDEDE) : AppColors.cream2;

    final Widget content = Padding(
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
            child: Icon(icon, size: 16, color: effectiveColor),
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
                    color: effectiveColor,
                  ),
                  overflow: TextOverflow.ellipsis,
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
          if (trailing != null)
            trailing!
          else if (onTap != null)
            const Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: AppColors.ink4,
            ),
        ],
      ),
    );

    if (onTap != null && trailing == null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: content,
      );
    }
    return content;
  }
}

// Avatar widgets

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.size});

  final String name;
  final int size;

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().split(' ').map((w) => w[0]).take(2).join();
    return Container(
      width: size.toDouble(),
      height: size.toDouble(),
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

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.name, required this.size});

  final String name;
  final int size;

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().split(' ').map((w) => w[0]).take(2).join();
    return Container(
      width: size.toDouble(),
      height: size.toDouble(),
      decoration: BoxDecoration(
        color: AppColors.cream2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: GoogleFonts.inter(
          fontSize: size * 0.32,
          fontWeight: FontWeight.w700,
          color: AppColors.ink3,
        ),
      ),
    );
  }
}

class _JoinedChip extends StatelessWidget {
  const _JoinedChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.cream2,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.line),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(fontSize: 11, color: AppColors.ink3),
      ),
    );
  }
}

// Wallet detail screen

class _StudentWalletScreen extends StatelessWidget {
  const _StudentWalletScreen();

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final w = kStudentProfile.wallet;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(8, 12, 20, 12),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.line, width: 0.8),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                    ),
                    color: AppColors.ink,
                  ),
                  Expanded(
                    child: Text(
                      'Ví của tôi',
                      style: AppTextStyles.h3(),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(14, 14, 14, bottomPad + 40),
                children: [
                  // Balance hero
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.ink,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SỐ DƯ VÍ',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.1,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              _fmt(w.balance),
                              style: GoogleFonts.ibmPlexMono(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                color: AppColors.cream,
                                letterSpacing: -0.02,
                                height: 1,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '₫',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        IntrinsicHeight(
                          child: Row(
                            children: [
                              _WalletDetailStat(
                                value: '${w.escrow ~/ 1000}k ₫',
                                label: 'Đang giữ escrow',
                                gold: true,
                              ),
                              Container(
                                width: 1,
                                color: Colors.white.withValues(alpha: 0.1),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                              ),
                              _WalletDetailStat(
                                value: '${(w.balance + w.escrow) ~/ 1000}k ₫',
                                label: 'Tổng đã nạp',
                                gold: false,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () {},
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            decoration: BoxDecoration(
                              color: AppColors.gold,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.add_rounded,
                                  size: 15,
                                  color: AppColors.ink,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Nạp tiền vào ví',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Escrow explanation
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.paper,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.shield_outlined,
                          size: 18,
                          color: AppColors.ink,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Escrow hoạt động thế nào?',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 6),
                              ...[
                                'Bạn đặt lịch → tiền giữ escrow trong ví',
                                'Buổi học hoàn thành → bạn xác nhận',
                                'Tutora giải ngân cho gia sư',
                                'Huỷ lịch → hoàn tiền tự động',
                              ].asMap().entries.map(
                                (e) => Padding(
                                  padding: const EdgeInsets.only(bottom: 5),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '0${e.key + 1}',
                                        style: GoogleFonts.ibmPlexMono(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.gold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          e.value,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: AppColors.ink3,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Transaction list
                  const _WalletSectionLabel('Lịch sử giao dịch'),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.paper,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Column(
                      children: kStudentProfile.transactions
                          .asMap()
                          .entries
                          .map((e) {
                            final i = e.key;
                            final tx = e.value;
                            return Column(
                              children: [
                                if (i > 0)
                                  const Divider(
                                    height: 1,
                                    indent: 60,
                                    color: AppColors.line,
                                  ),
                                _TxRow(tx: tx),
                              ],
                            );
                          })
                          .toList(),
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

class _WalletDetailStat extends StatelessWidget {
  const _WalletDetailStat({
    required this.value,
    required this.label,
    required this.gold,
  });

  final String value;
  final String label;
  final bool gold;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.ibmPlexMono(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: gold ? AppColors.gold : AppColors.cream,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.45),
          ),
        ),
      ],
    );
  }
}

class _WalletSectionLabel extends StatelessWidget {
  const _WalletSectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 6),
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

class _TxRow extends StatelessWidget {
  const _TxRow({required this.tx});

  final StudentTxMock tx;

  (Color, IconData) get _icon => switch (tx.type) {
    StudentTxType.topup => (
      const Color(0xFFD5EDD9),
      Icons.arrow_upward_rounded,
    ),
    StudentTxType.escrow => (const Color(0xFFFFF3CD), Icons.shield_outlined),
    StudentTxType.refund => (
      const Color(0xFFD5E8F5),
      Icons.arrow_downward_rounded,
    ),
  };

  Color get _iconFg => switch (tx.type) {
    StudentTxType.topup => const Color(0xFF1D5C2D),
    StudentTxType.escrow => const Color(0xFF7A5900),
    StudentTxType.refund => const Color(0xFF0D3F6B),
  };

  @override
  Widget build(BuildContext context) {
    final (bg, icon) = _icon;
    final isPos = tx.amount > 0;
    final amountK = tx.amount.abs() ~/ 1000;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 14, color: _iconFg),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '${tx.date} · ${tx.method}',
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 11,
                    color: AppColors.ink4,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isPos ? '+' : ''}${isPos ? amountK : '-$amountK'}k ₫',
            style: GoogleFonts.ibmPlexMono(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isPos ? const Color(0xFF1D5C2D) : AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

// Helpers

String _fmt(int n) {
  if (n >= 1000000) {
    final m = n ~/ 1000;
    return '${m ~/ 1000}.${(m % 1000).toString().padLeft(3, '0')}';
  }
  if (n >= 1000) return '${n ~/ 1000}.000';
  return '$n';
}
