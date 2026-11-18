import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/tutor_colors.dart';

/// Ô nhập màn đăng nhập — design V5.6: ô lõm sáng `#FBFAF7`, viền mực 8%,
/// bo 14, viền xanh rêu khi đang nhập.
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

  /// Nền ô nhập (giếng sáng).
  static const Color fill = Color(0xFFFBFAF7);

  /// Viền mực 8%.
  static const Color border = Color(0x141F2A24);

  /// Góc ô nhập.
  static const double radius = 14;

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

  OutlineInputBorder _border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(AuthInput.radius),
        borderSide: BorderSide(color: color, width: width),
      );

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;
    final focused = _focus.hasFocus;

    var suffixIcon = widget.suffix;
    if (widget.obscureText) {
      suffixIcon = IconButton(
        tooltip: _obscure ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
        icon: Icon(
          _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          size: 18,
          color: TutorColors.ink4,
        ),
        onPressed: () => setState(() => _obscure = !_obscure),
      );
    }

    return TextField(
      controller: widget.controller,
      focusNode: _focus,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      obscureText: _obscure,
      enabled: widget.enabled,
      onSubmitted: widget.onSubmitted,
      onChanged: widget.onChanged,
      cursorColor: TutorColors.ink,
      style: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: TutorColors.ink,
      ),
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: GoogleFonts.inter(fontSize: 14, color: TutorColors.ink3),
        floatingLabelStyle: GoogleFonts.inter(
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
          color: hasError
              ? TutorColors.danger
              : focused
              ? TutorColors.ink
              : TutorColors.ink3,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        hintText: widget.hint,
        hintStyle: GoogleFonts.inter(fontSize: 14, color: TutorColors.ink4),
        filled: true,
        fillColor: AuthInput.fill,
        contentPadding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
        border: _border(AuthInput.border),
        enabledBorder: _border(AuthInput.border),
        disabledBorder: _border(AuthInput.border),
        focusedBorder: _border(TutorColors.ink, 1.5),
        errorBorder: _border(TutorColors.danger),
        focusedErrorBorder: _border(TutorColors.danger, 1.5),
        errorText: hasError ? widget.errorText : null,
        errorStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: TutorColors.danger,
        ),
        suffixIcon: suffixIcon,
      ),
    );
  }
}
