import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_text_styles.dart';

class TutorScreenHeader extends StatelessWidget {
  const TutorScreenHeader({
    required this.title,
    required this.onBack,
    super.key,
  });

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 20, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line, width: 0.8)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            color: AppColors.ink,
          ),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.h3(),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

class TutorFormField extends StatelessWidget {
  const TutorFormField({
    required this.label,
    required this.controller,
    super.key,
    this.hint,
    this.validator,
    this.maxLines = 1,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? Function(String?)? validator;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.ink3,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.ink),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.ink4),
            filled: true,
            fillColor: AppColors.paper,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.ink, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.oxblood),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.oxblood,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class TutorReadOnlyField extends StatelessWidget {
  const TutorReadOnlyField({
    required this.label,
    required this.value,
    super.key,
    this.hint = '',
  });

  final String label;
  final String value;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.ink3,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: AppColors.cream2,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.line),
          ),
          child: Text(
            value.isNotEmpty ? value : hint,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: value.isNotEmpty ? AppColors.ink3 : AppColors.ink4,
            ),
          ),
        ),
      ],
    );
  }
}

class TutorSaveButton extends StatelessWidget {
  const TutorSaveButton({
    required this.saving,
    required this.onSave,
    super.key,
    this.label = 'Lưu thay đổi',
  });

  final bool saving;
  final VoidCallback onSave;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: saving ? null : onSave,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.ink,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
