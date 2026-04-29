import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class TutorHomePage extends StatelessWidget {
  const TutorHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text('Tutor · Trang chủ', style: AppTextStyles.h2()),
        ),
      ),
    );
  }
}
