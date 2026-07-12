import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';
import 'package:tutora/core/constants/app_text_styles.dart';
import 'package:tutora/core/router/app_routes.dart';
import 'package:tutora/features/auth/presentation/widgets/auth_top_deco.dart';

class RegisterRolePage extends StatelessWidget {
  const RegisterRolePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const AuthTopDeco(
            bgColor: AppColors.ink,
            line1: 'Bắt đầu hành trình,',
            italicWord: 'chọn',
            line2Suffix: 'vai trò của bạn',
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 14,
                            color: AppColors.ink3,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Quay lại',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.ink3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    Text('Bạn là ai?', style: AppTextStyles.h2()),
                    const SizedBox(height: 4),
                    Text(
                      'Chọn vai trò để chúng tôi thiết lập trải nghiệm phù hợp.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.ink3,
                      ),
                    ),
                    const SizedBox(height: 24),

                    _RoleCard(
                      icon: Icons.school_rounded,
                      title: 'Học sinh',
                      subtitle: 'Tìm gia sư, đặt lịch và học cùng AI.',
                      onTap: () => context.push(AppRoutes.registerStudent),
                    ),
                    const SizedBox(height: 14),
                    _RoleCard(
                      icon: Icons.cast_for_education_rounded,
                      title: 'Gia sư',
                      subtitle: 'Nhận học sinh, quản lý lịch dạy và thu nhập.',
                      onTap: () => context.push(AppRoutes.registerTutor),
                    ),
                    const SizedBox(height: 14),
                    _RoleCard(
                      icon: Icons.family_restroom_rounded,
                      title: 'Phụ huynh',
                      subtitle: 'Theo dõi việc học và đặt lịch cho con.',
                      onTap: () => context.push(AppRoutes.registerParent),
                    ),

                    const SizedBox(height: 28),

                    Center(
                      child: Text.rich(
                        TextSpan(
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.ink3,
                          ),
                          children: [
                            const TextSpan(text: 'Đã có tài khoản? '),
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: GestureDetector(
                                onTap: () => context.pop(),
                                child: Text(
                                  'Đăng nhập',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.oxblood,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.paper,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.cream2,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 24, color: AppColors.ink),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.ink3,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 15,
                color: AppColors.ink4,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
