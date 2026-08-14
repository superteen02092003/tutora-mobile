import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';

class BookingSectionTitle extends StatelessWidget {
  const BookingSectionTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: GoogleFonts.bricolageGrotesque(
      fontWeight: FontWeight.w700,
      fontSize: 18,
      color: AppColors.ink,
    ),
  );
}

class BookingErrorBanner extends StatelessWidget {
  const BookingErrorBanner({
    required this.message,
    required this.onDismiss,
    super.key,
    this.actionLabel,
    this.onAction,
  });
  final String message;
  final VoidCallback onDismiss;
  final String? actionLabel;
  final VoidCallback? onAction;

  static const _red = Color(0xFFDC2626);

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
    decoration: BoxDecoration(
      color: const Color(0xFFFEF2F2),
      border: Border.all(color: const Color(0xFFFECACA)),
      borderRadius: BorderRadius.circular(AppRadius.md),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline_rounded, size: 20, color: _red),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  height: 1.45,
                  color: _red,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onDismiss,
              child: const Icon(Icons.close_rounded, size: 20, color: _red),
            ),
          ],
        ),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: 10),
          GestureDetector(
            onTap: onAction,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: _red,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actionLabel!,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

class BookingReviewRow extends StatelessWidget {
  const BookingReviewRow(this.label, this.value, {super.key});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.ink3),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ),
      ],
    ),
  );
}

class BookingPriceRow extends StatelessWidget {
  const BookingPriceRow(this.label, this.value, {super.key, this.bold = false});
  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: bold ? 15 : 14,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            color: AppColors.ink2,
          ),
        ),
      ),
      Text(
        value,
        style: GoogleFonts.inter(
          fontSize: bold ? 17 : 14,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
          color: bold ? AppColors.ink : AppColors.ink2,
        ),
      ),
    ],
  );
}

class BookingPrimaryButton extends StatelessWidget {
  const BookingPrimaryButton({
    required this.label,
    required this.onTap,
    super.key,
    this.gold = false,
  });
  final String label;
  final VoidCallback onTap;
  final bool gold;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
      decoration: BoxDecoration(
        color: gold ? AppColors.gold : AppColors.ink,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: gold ? AppColors.ink : AppColors.cream,
        ),
      ),
    ),
  );
}
