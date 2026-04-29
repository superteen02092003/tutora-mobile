import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/utils/jwt_utils.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await Future.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;

    final storage = ref.read(secureStorageProvider);
    final token = await storage.getAccessToken();

    if (!mounted) return;

    if (token == null) {
      context.go(AppRoutes.login);
      return;
    }

    final claims = parseJwt(token);

    if (claims == null || claims.isExpired) {
      await storage.clearTokens();
      if (mounted) context.go(AppRoutes.login);
      return;
    }

    switch (claims.role) {
      case UserRole.student:
        context.go(AppRoutes.studentHome);
      case UserRole.tutor:
        context.go(AppRoutes.tutorHome);
      case UserRole.unknown:
        context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('TUTORA', style: AppTextStyles.h1(color: AppColors.cream)),
            Text('.', style: AppTextStyles.h1(color: AppColors.oxblood)),
          ],
        ),
      ),
    );
  }
}
