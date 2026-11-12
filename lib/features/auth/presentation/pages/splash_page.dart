import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/core/router/app_routes.dart';
import 'package:tutora/core/storage/secure_storage.dart';
import 'package:tutora/core/theme/tutor_design.dart';
import 'package:tutora/core/utils/jwt_utils.dart';
import 'package:tutora/features/auth/presentation/controllers/auth_controller.dart';
import 'package:tutora/features/auth/presentation/pages/login_page.dart'
    show tutorOnlyMessage;
import 'package:tutora/features/auth/presentation/widgets/auth_top_deco.dart'
    show AuthLeaf;
import 'package:tutora/shared/widgets/app_toast.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    unawaited(_init());
  }

  Future<void> _init() async {
    await Future<void>.delayed(const Duration(milliseconds: 1600));
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

    if (claims.role == UserRole.tutor) {
      context.go(AppRoutes.tutorHome);
      return;
    }

    // Phiên cũ của học sinh / phụ huynh (hoặc vai trò lạ): app này chỉ dành
    // cho gia sư → đăng xuất (gỡ push token của phiên cũ + xoá token), về
    // trang đăng nhập kèm lời nhắn dùng web.
    await ref.read(authControllerProvider.notifier).logout();
    if (!mounted) return;
    if (claims.role != UserRole.unknown) {
      AppToast.show(
        context,
        message: tutorOnlyMessage,
        type: AppToastType.warning,
        duration: const Duration(seconds: 6),
      );
    }
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    // V5.6: nền giấy, lá cây góc phải, chữ "TopTutor" Bricolage ở giữa.
    return Scaffold(
      backgroundColor: TutorColors.bg,
      body: DecoratedBox(
        decoration: TutorSurface.paper,
        child: SafeArea(
          child: Stack(
            children: [
              const Positioned(top: 0, right: 0, child: AuthLeaf(width: 170)),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('TopTutor', style: TutorType.display(size: 40)),
                    const SizedBox(height: 8),
                    Text('Dành cho gia sư', style: TutorType.rowSub()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
