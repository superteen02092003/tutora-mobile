import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class StudentCapturePage extends StatelessWidget {
  const StudentCapturePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text('Student · Quét AI', style: AppTextStyles.h2(color: AppColors.cream)),
        ),
      ),
    );
  }
}
