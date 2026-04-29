import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.xxl),
              Text('Chào mừng\ntrở lại.', style: AppTextStyles.h1()),
              const SizedBox(height: AppSpacing.sm),
              Text('Đăng nhập để tiếp tục học tập.', style: AppTextStyles.body()),
              const SizedBox(height: AppSpacing.xl),

              // Email field
              const TextField(
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: AppSpacing.md),

              // Password field
              const TextField(
                obscureText: true,
                decoration: InputDecoration(labelText: 'Mật khẩu'),
              ),
              const SizedBox(height: AppSpacing.xl),

              ElevatedButton(
                onPressed: () {
                  // TODO: wire to AuthController
                },
                child: const Text('Đăng nhập'),
              ),

              const SizedBox(height: AppSpacing.md),
              Center(
                child: TextButton(
                  onPressed: () {},
                  child: Text(
                    'Quên mật khẩu?',
                    style: AppTextStyles.label(color: AppColors.oxblood),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
