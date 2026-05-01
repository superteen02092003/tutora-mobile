import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';

class AuthInput extends StatefulWidget {
  const AuthInput({
    required this.label,
    required this.controller,
    super.key,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.hint,
    this.errorText,
    this.enabled = true,
    this.onSubmitted,
    this.onChanged,
    this.suffix,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final String? hint;
  final String? errorText;
  final bool enabled;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final Widget? suffix;

  @override
  State<AuthInput> createState() => _AuthInputState();
}

class _AuthInputState extends State<AuthInput> {
  late final FocusNode _focus;
  late bool _obscure;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
    _focus = FocusNode()..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;
    final focused = _focus.hasFocus;

    var suffixIcon = widget.suffix;
    if (widget.obscureText) {
      suffixIcon = IconButton(
        icon: Icon(
          _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          size: 18,
          color: AppColors.ink4,
        ),
        onPressed: () => setState(() => _obscure = !_obscure),
      );
    }

    final radius = BorderRadius.circular(AppRadius.md);

    return TextField(
      controller: widget.controller,
      focusNode: _focus,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      obscureText: _obscure,
      enabled: widget.enabled,
      onSubmitted: widget.onSubmitted,
      onChanged: widget.onChanged,
      style: GoogleFonts.inter(fontSize: 14, color: AppColors.ink),
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.ink3),
        floatingLabelStyle: GoogleFonts.inter(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
          color: hasError
              ? AppColors.oxblood
              : focused
              ? AppColors.ink
              : AppColors.ink3,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        hintText: widget.hint,
        hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.ink4),
        filled: true,
        fillColor: AppColors.paper,
        contentPadding: const EdgeInsets.fromLTRB(14, 20, 14, 12),
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: AppColors.ink, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: AppColors.oxblood),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: AppColors.oxblood, width: 1.5),
        ),
        errorText: hasError ? widget.errorText : null,
        errorStyle: GoogleFonts.inter(fontSize: 11, color: AppColors.oxblood),
        suffixIcon: suffixIcon,
      ),
    );
  }
}
