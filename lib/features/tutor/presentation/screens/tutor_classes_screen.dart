import 'package:flutter/material.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_text_styles.dart';

class TutorClassesScreen extends StatelessWidget {
  const TutorClassesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text('Tutor · Lớp học', style: AppTextStyles.h2()),
        ),
      ),
    );
  }
}
