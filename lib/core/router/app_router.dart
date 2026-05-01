import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tutora/core/router/app_routes.dart';
import 'package:tutora/features/auth/presentation/pages/forgot_page.dart';
import 'package:tutora/features/auth/presentation/pages/login_page.dart';
import 'package:tutora/features/auth/presentation/pages/otp_page.dart';
import 'package:tutora/features/auth/presentation/pages/register_page.dart';
import 'package:tutora/features/auth/presentation/pages/splash_page.dart';
import 'package:tutora/features/student/presentation/pages/student_capture_page.dart';
import 'package:tutora/features/student/presentation/pages/student_home_page.dart';
import 'package:tutora/features/student/presentation/pages/student_lessons_page.dart';
import 'package:tutora/features/student/presentation/pages/student_marketplace_page.dart';
import 'package:tutora/features/student/presentation/pages/student_profile_page.dart';
import 'package:tutora/features/student/presentation/pages/tutor_detail_page.dart';
import 'package:tutora/features/student/presentation/shell/student_shell.dart';
import 'package:tutora/features/tutor/presentation/pages/tutor_contribute_page.dart';
import 'package:tutora/features/tutor/presentation/pages/tutor_home_page.dart';
import 'package:tutora/features/tutor/presentation/pages/tutor_profile_page.dart';
import 'package:tutora/features/tutor/presentation/pages/tutor_schedule_page.dart';
import 'package:tutora/features/tutor/presentation/shell/tutor_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
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
        path: AppRoutes.register,
        builder: (context, _) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.forgot,
        builder: (context, _) => const ForgotPage(),
      ),
      GoRoute(
        path: AppRoutes.otp,
        builder: (context, state) => OtpPage(
          email: state.extra as String? ?? '',
        ),
      ),

      // ── Student shell — 5 tabs: Home(0) · Search(1) · Capture(2,center) · Lessons(3) · Profile(4)
      StatefulShellRoute.indexedStack(
        builder: (context, _, shell) => StudentShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.studentHome,
                builder: (context, _) => const StudentHomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.studentSearch,
                builder: (context, _) => const StudentMarketplacePage(),
                routes: [
                  GoRoute(
                    path: 'tutor/:id',
                    builder: (context, state) => TutorDetailPage(
                      tutorId: state.pathParameters['id'] ?? '0',
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.studentCapture,
                builder: (context, _) => const StudentCapturePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.studentLessons,
                builder: (context, _) => const StudentLessonsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.studentProfile,
                builder: (context, _) => const StudentProfilePage(),
              ),
            ],
          ),
        ],
      ),

      // ── Tutor shell — 4 tabs: Home · Schedule · Contribute · Profile
      StatefulShellRoute.indexedStack(
        builder: (context, _, shell) => TutorShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.tutorHome,
                builder: (context, _) => const TutorHomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.tutorSchedule,
                builder: (context, _) => const TutorSchedulePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.tutorContribute,
                builder: (context, _) => const TutorContributePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.tutorProfile,
                builder: (context, _) => const TutorProfilePage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
