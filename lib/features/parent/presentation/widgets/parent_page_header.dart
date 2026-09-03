import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';

/// Header màn con của phụ huynh: back + tiêu đề giữa, nền trong suốt.
class ParentPageHeader extends StatelessWidget {
  const ParentPageHeader({
    required this.title,
    super.key,
    this.onBack,
    this.action,
  });

  final String title;
  final VoidCallback? onBack;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 60),
            child: Semantics(
              header: true,
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.bricolageGrotesque(
                  fontWeight: FontWeight.w800,
                  fontSize: 19,
                  color: AppColors.ink,
                ),
              ),
            ),
          ),
          Positioned(
            left: 4,
            child: IconButton(
              onPressed: onBack ?? () => Navigator.of(context).pop(),
              tooltip: 'Quay lại',
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              color: AppColors.ink,
            ),
          ),
          if (action != null)
            Positioned(
              right: 4,
              child: SizedBox(
                width: 48,
                height: 48,
                child: Center(child: action),
              ),
            ),
        ],
      ),
    );
  }
}
