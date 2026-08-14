import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tutora/core/router/app_routes.dart';
import 'package:tutora/features/auth/presentation/controllers/auth_controller.dart';
import 'package:tutora/features/parent/presentation/providers/parent_profile_provider.dart';
import 'package:tutora/features/parent/presentation/providers/parent_provider.dart';
import 'package:tutora/features/student/presentation/providers/class_provider.dart';
import 'package:tutora/features/student/presentation/providers/profile_provider.dart';
import 'package:tutora/shared/widgets/app_toast.dart';

class AuthListener extends ConsumerWidget {
  const AuthListener({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AuthState>(authControllerProvider, (_, next) async {
      if (next is AuthLoggedOut) {
        ref
          ..invalidate(profileProvider)
          ..invalidate(classListProvider)
          ..invalidate(parentProfileProvider)
          ..invalidate(parentStudentsProvider)
          ..invalidate(parentDashboardProvider);

        AppToast.show(
          context,
          message: 'Đã đăng xuất.',
          type: AppToastType.success,
        );
        await Future<void>.delayed(const Duration(milliseconds: 800));
        if (context.mounted) context.go(AppRoutes.login);
      } else if (next is AuthError) {
        AppToast.show(
          context,
          message: 'Đăng xuất thất bại. Vui lòng thử lại.',
          type: AppToastType.error,
        );
      }
    });
    return child;
  }
}
