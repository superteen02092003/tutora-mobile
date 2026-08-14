import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';

/// Kiểu nhấn của nút chính — chỉ đổi màu nền, không đổi bố cục.
enum AppConfirmTone { neutral, danger }

/// Modal xác nhận dùng chung mọi role. Trả `true` nút chính, `false` nút phụ,
/// `null` khi vuốt bỏ.
class AppConfirmSheet {
  AppConfirmSheet._();

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    String? cancelLabel,
    AppConfirmTone tone = AppConfirmTone.neutral,
    bool dismissible = true,

    /// Để `false` khi gọi từ trong một bottom sheet khác — dùng root navigator
    /// lúc đó sẽ đẩy modal xuống dưới sheet cha và không nhìn thấy gì.
    bool useRootNavigator = true,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: useRootNavigator,
      isDismissible: dismissible,
      enableDrag: dismissible,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ConfirmSheet(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        tone: tone,
      ),
    );
  }
}

class _ConfirmSheet extends StatelessWidget {
  const _ConfirmSheet({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.tone,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String? cancelLabel;
  final AppConfirmTone tone;

  @override
  Widget build(BuildContext context) {
    final confirmBg = switch (tone) {
      AppConfirmTone.neutral => AppColors.ink,
      AppConfirmTone.danger => AppColors.error,
    };

    return SafeArea(
      top: false,
      child: Padding(
        // Đẩy sheet lên khi có bàn phím để nút không bị che.
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                title,
                style: GoogleFonts.bricolageGrotesque(
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                  height: 1.2,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  height: 1.55,
                  color: AppColors.ink3,
                ),
              ),
              const SizedBox(height: 22),
              _SheetButton(
                label: confirmLabel,
                background: confirmBg,
                foreground: AppColors.cream,
                border: confirmBg,
                onTap: () => Navigator.of(context).pop(true),
              ),
              if (cancelLabel != null) ...[
                const SizedBox(height: 10),
                _SheetButton(
                  label: cancelLabel!,
                  background: AppColors.paper,
                  foreground: AppColors.ink,
                  border: AppColors.line,
                  onTap: () => Navigator.of(context).pop(false),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetButton extends StatelessWidget {
  const _SheetButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.border,
    required this.onTap,
  });

  final String label;
  final Color background;
  final Color foreground;
  final Color border;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: foreground,
          ),
        ),
      ),
    );
  }
}
