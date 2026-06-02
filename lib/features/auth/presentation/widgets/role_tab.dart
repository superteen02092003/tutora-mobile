import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';

enum AuthRole { student, tutor, parent }

extension AuthRoleX on AuthRole {
  String get label => switch (this) {
    AuthRole.student => 'Học sinh',
    AuthRole.tutor => 'Gia sư',
    AuthRole.parent => 'Phụ huynh',
  };

  String get apiValue => switch (this) {
    AuthRole.student => 'Student',
    AuthRole.tutor => 'Tutor',
    AuthRole.parent => 'Parent',
  };
}

class RoleTab extends StatelessWidget {
  const RoleTab({required this.active, required this.onChanged, super.key});

  final AuthRole active;
  final ValueChanged<AuthRole> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.cream2,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        children: AuthRole.values
            .map(
              (role) => _RoleChip(
                label: role.label,
                isActive: active == role,
                onTap: () => onChanged(role),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isActive ? AppColors.ink : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isActive ? AppColors.cream : AppColors.ink3,
            ),
          ),
        ),
      ),
    );
  }
}
