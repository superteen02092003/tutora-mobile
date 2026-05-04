import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';

class ChatMoreMenu extends StatelessWidget {
  const ChatMoreMenu({required this.convoName, super.key});

  final String convoName;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                convoName,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink3,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(color: AppColors.line, height: 1),
            _MenuItem(
              icon: Icons.visibility_off_outlined,
              label: 'Ẩn cuộc trò chuyện',
              onTap: () => Navigator.of(context).pop('hide'),
            ),
            const Divider(color: AppColors.line, height: 1, indent: 56),
            _MenuItem(
              icon: Icons.delete_outline_rounded,
              label: 'Xoá cuộc trò chuyện',
              color: AppColors.oxblood,
              onTap: () => Navigator.of(context).pop('delete'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.ink;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: c),
            const SizedBox(width: 16),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: c,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
