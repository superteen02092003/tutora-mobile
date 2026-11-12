import 'package:flutter/material.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/core/theme/tutor_design.dart';

/// Ô nhập dùng chung cho các form gia sư — design V5.6: nhãn nhỏ thường phía
/// trên, ô nhập trên nền sáng (light well) có viền mực 8%, bo 14.

/// Nền ô nhập sáng (canvas `#FBFAF7`).
const Color _wellFill = Color(0xFFFBFAF7);
const Color _wellLine = Color(0x141F2A24);

OutlineInputBorder _border(Color color, [double width = 1]) =>
    OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: width),
    );

class TutorFormField extends StatelessWidget {
  const TutorFormField({
    required this.label,
    required this.controller,
    super.key,
    this.hint,
    this.validator,
    this.maxLines = 1,
    this.keyboardType,
    this.readOnly = false,
    this.onTap,
    this.suffixIcon,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? Function(String?)? validator;
  final int maxLines;
  final TextInputType? keyboardType;

  /// Ô chỉ chọn (vd. ngày sinh qua lịch) — không gõ tay, mở picker qua [onTap].
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TutorType.caption(color: TutorColors.ink3)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          maxLines: maxLines,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          style: TutorType.body().copyWith(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TutorType.body(
              color: TutorColors.ink4,
            ).copyWith(fontSize: 14),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: _wellFill,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            border: _border(_wellLine),
            enabledBorder: _border(_wellLine),
            focusedBorder: _border(TutorColors.ink, 1.4),
            errorBorder: _border(TutorColors.danger),
            focusedErrorBorder: _border(TutorColors.danger, 1.4),
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
        Text(label, style: TutorType.caption(color: TutorColors.ink3)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: TutorColors.surfaceSunken,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            value.isNotEmpty ? value : hint,
            style: TutorType.body(
              color: value.isNotEmpty ? TutorColors.ink3 : TutorColors.ink4,
            ).copyWith(fontSize: 14),
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
      height: 48,
      child: FilledButton(
        onPressed: saving ? null : onSave,
        style: FilledButton.styleFrom(
          backgroundColor: TutorColors.primary,
          disabledBackgroundColor: TutorColors.surfaceSunken,
          shape: const StadiumBorder(),
        ),
        child: saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: TutorColors.ink,
                ),
              )
            : Text(
                label,
                style: TutorType.action(
                  color: Colors.white,
                ).copyWith(fontSize: 15),
              ),
      ),
    );
  }
}
