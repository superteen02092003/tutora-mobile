import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_text_styles.dart';

/// Full-screen placeholder for features only available on web.
class WebOnlyScreen extends StatelessWidget {
  const WebOnlyScreen({required this.title, this.description, super.key});

  final String title;
  final String? description;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 16, 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                      color: AppColors.ink,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(child: Text(title, style: AppTextStyles.h3())),
                ],
              ),
            ),
            const Expanded(child: _WebOnlyContent()),
          ],
        ),
      ),
    );
  }
}

/// Inline card for embedding inside a screen (e.g. inside a list).
class WebOnlyCard extends StatelessWidget {
  const WebOnlyCard({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.cream2,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.open_in_browser_rounded,
              size: 20,
              color: AppColors.ink3,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.label()),
                const SizedBox(height: 2),
                Text(
                  'Xem trên web để sử dụng tính năng này',
                  style: AppTextStyles.bodySmall(color: AppColors.ink4),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.laptop_rounded,
            size: 16,
            color: AppColors.ink4,
          ),
        ],
      ),
    );
  }
}

class _WebOnlyContent extends StatelessWidget {
  const _WebOnlyContent();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.cream2,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.laptop_rounded,
                size: 36,
                color: AppColors.ink3,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Tính năng chỉ có trên web',
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Truy cập Tutora trên trình duyệt để sử dụng đầy đủ tính năng này.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.ink4,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
