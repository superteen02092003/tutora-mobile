import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tutora/core/router/app_routes.dart';
import 'package:tutora/features/auth/presentation/pages/forgot_page.dart';
import 'package:tutora/features/auth/presentation/pages/login_page.dart';
import 'package:tutora/features/auth/presentation/pages/otp_page.dart';
import 'package:tutora/features/auth/presentation/pages/register_page.dart';
import 'package:tutora/features/auth/presentation/pages/splash_page.dart';
import 'package:tutora/features/student/presentation/screens/student_booking_detail_screen.dart';
import 'package:tutora/features/student/presentation/screens/student_booking_screen.dart';
import 'package:tutora/features/student/presentation/screens/student_capture_screen.dart';
import 'package:tutora/features/student/presentation/screens/student_home_screen.dart';
import 'package:tutora/features/student/presentation/screens/student_lessons_screen.dart';
import 'package:tutora/features/student/presentation/screens/student_marketplace_screen.dart';
import 'package:tutora/features/student/presentation/screens/student_messages_screen.dart';
import 'package:tutora/features/student/presentation/screens/student_notifications_screen.dart';
import 'package:tutora/features/student/presentation/screens/student_profile_screen.dart';
import 'package:tutora/features/student/presentation/screens/student_solution_screen.dart';
import 'package:tutora/features/student/presentation/screens/tutor_detail_screen.dart';
import 'package:tutora/features/student/presentation/shell/student_shell.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_contribute_screen.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_home_screen.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_messages_screen.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_notifications_screen.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_profile/tutor_profile_screen.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_schedule/tutor_schedule_screen.dart';
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
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, _) => const StudentNotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.studentMessages,
        builder: (context, _) => const StudentMessagesScreen(),
      ),
      GoRoute(
        path: AppRoutes.studentCapture,
        builder: (context, _) => const StudentCapturePage(),
      ),
      GoRoute(
        path: AppRoutes.studentBookings,
        builder: (context, _) => const StudentBookingScreen(),
      ),
      GoRoute(
        path: AppRoutes.studentBookingDetail,
        builder: (context, state) => StudentBookingDetailScreen(
          bookingId: int.parse(state.pathParameters['id'] ?? '0'),
        ),
      ),
      GoRoute(
        path: AppRoutes.studentSolution,
        builder: (context, _) => const StudentSolutionPage(),
      ),

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
          // Branch slot kept to preserve tab indices (0-4); FAB pushes outside shell
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/student/capture-stub',
                builder: (context, _) => const SizedBox.shrink(),
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

      GoRoute(
        path: AppRoutes.tutorNotifications,
        builder: (context, _) => const TutorNotificationsScreen(),
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, _, shell) => TutorShell(navigationShell: shell),
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
                path: AppRoutes.tutorContribute,
                builder: (context, _) => const TutorContributeScreen(),
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
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.tutorMessages,
                builder: (context, _) => const TutorMessagesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.tutorProfile,
                builder: (context, _) => const TutorProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
