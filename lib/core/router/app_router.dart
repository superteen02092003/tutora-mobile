import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tutora/core/network/interceptors/auth_interceptor.dart'
    show navigatorKeyProvider;
import 'package:tutora/core/router/app_routes.dart';
import 'package:tutora/core/storage/secure_storage.dart';
import 'package:tutora/core/utils/jwt_utils.dart';
import 'package:tutora/features/auth/presentation/pages/forgot_page.dart';
import 'package:tutora/features/auth/presentation/pages/login_page.dart';
import 'package:tutora/features/auth/presentation/pages/otp_page.dart';
import 'package:tutora/features/auth/presentation/pages/splash_page.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_home_screen.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_notifications_screen.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_profile/tutor_profile_screen.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_recorder/tutor_recorder_entry_screen.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_recorder/recording_target.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_recorder/tutor_recording_screen.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_recorder/tutor_recording_detail_screen.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_recorder/tutor_report_review_screen.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_schedule/tutor_schedule_screen.dart';
import 'package:tutora/features/tutor/presentation/shell/v2/tutor_shell_v2.dart';

// Auth-only routes — no role guard needed
const Set<String> _publicPaths = {
  AppRoutes.splash,
  AppRoutes.login,
  AppRoutes.forgot,
  AppRoutes.otp,
};

bool _isPublic(String path) => _publicPaths.any((p) => path == p);

final appRouterProvider = Provider<GoRouter>((ref) {
  final storage = ref.read(secureStorageProvider);
  final navigatorKey = ref.watch(navigatorKeyProvider);

  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) async {
      final path = state.matchedLocation;

      // Public pages: never redirect
      if (_isPublic(path)) return null;

      final token = await storage.getAccessToken();

      // No token → login
      if (token == null) return AppRoutes.login;

      final claims = parseJwt(token);

      // Invalid / expired token → login
      if (claims == null || claims.isExpired) return AppRoutes.login;

      // App chỉ dành cho gia sư: vai trò khác về trang đăng nhập (splash và
      // login tự xoá token + báo dùng web tutora.vn).
      if (claims.role != UserRole.tutor) return AppRoutes.login;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, _) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, _) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.forgot,
        builder: (context, _) => const ForgotPage(),
      ),
      GoRoute(
        path: AppRoutes.otp,
        builder: (context, state) {
          final args = state.extra as OtpArgs?;
          return OtpPage(
            phone: args?.phone ?? '',
            mode: args?.mode ?? OtpMode.register,
          );
        },
      ),

      // Tutor-only standalone routes
      GoRoute(
        path: AppRoutes.tutorNotifications,
        builder: (context, _) => const TutorNotificationsScreen(),
      ),

      // Hồ sơ (Tôi): màn con đứng riêng, vào từ avatar ở header Trang chủ.
      // Luồng ghi âm — đứng ngoài shell: khi đang ghi, thanh tab biến mất để
      // không ai bấm nhầm sang tab khác giữa buổi.
      GoRoute(
        path: AppRoutes.tutorRecorder,
        // Sheet: trong suốt để trang chủ vẫn nằm phía sau, trượt từ dưới lên.
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          opaque: false,
          barrierColor: Colors.transparent,
          child: const TutorRecorderEntryScreen(),
          transitionsBuilder: (context, animation, _, child) => SlideTransition(
            position:
                Tween(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.tutorRecording,
        builder: (context, state) {
          return TutorRecordingScreen(target: state.extra! as RecordingTarget);
        },
      ),
      GoRoute(
        path: AppRoutes.tutorRecordingDetail,
        builder: (context, state) => TutorRecordingDetailScreen(
          args: state.extra! as RecordingDetailArgs,
        ),
      ),
      GoRoute(
        path: AppRoutes.tutorReportReview,
        builder: (context, state) =>
            TutorReportReviewScreen(args: state.extra! as ReportReviewArgs),
      ),
      GoRoute(
        path: AppRoutes.tutorProfile,
        builder: (context, _) => const TutorProfileScreen(),
      ),

      // Tutor shell (2 tab + nút ghi âm ở giữa)
      StatefulShellRoute.indexedStack(
        builder: (context, _, shell) => TutorShellV2(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.tutorHome,
                builder: (context, _) => const TutorHomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.tutorSchedule,
                builder: (context, _) => const TutorScheduleScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
