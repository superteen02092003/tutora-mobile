import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';
import 'package:tutora/core/constants/app_text_styles.dart';

// ── Format helper ────────────────────────────────────────────────────────────

String fmtVnd(int n) {
  if (n >= 1000000) {
    final m = n ~/ 1000;
    return '${m ~/ 1000}.${(m % 1000).toString().padLeft(3, '0')}';
  }
  if (n >= 1000) return '${n ~/ 1000}.000';
  return '$n';
}

// "2026-03-31T02:15:10..." → "Tháng 3, 2026"
String formatJoined(String isoDate) {
  if (isoDate.isEmpty) return '';
  try {
    final dt = DateTime.parse(isoDate);
    return 'Tháng ${dt.month}, ${dt.year}';
  } catch (_) {
    return isoDate;
  }
}

// Avatar

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({required this.name, required this.size, super.key});

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

class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({required this.name, required this.size, super.key});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().split(' ').map((w) => w[0]).take(2).join();
    return Container(
      width: size,
      height: size,
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

// Joined chip

class JoinedChip extends StatelessWidget {
  const JoinedChip({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.cream2,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.line),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(fontSize: 11, color: AppColors.ink3),
      ),
    );
  }
}

// Stat cell (hero stats row)

class ProfileStatCell extends StatelessWidget {
  const ProfileStatCell({
    required this.value,
    required this.label,
    required this.borderRight,
    super.key,
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

// Section label

class ProfileSectionLabel extends StatelessWidget {
  const ProfileSectionLabel(this.text, {super.key});

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

// Section card

class ProfileSectionCard extends StatelessWidget {
  const ProfileSectionCard({required this.children, super.key});

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

// Setting row

class SettingRow extends StatelessWidget {
  const SettingRow({
    required this.icon,
    required this.label,
    this.sub,
    this.onTap,
    this.trailing,
    this.danger = false,
    super.key,
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

    final content = Padding(
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
