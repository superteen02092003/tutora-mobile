import 'dart:typed_data';

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
import 'package:tutora/features/auth/presentation/pages/register_page.dart';
import 'package:tutora/features/auth/presentation/pages/register_parent_page.dart';
import 'package:tutora/features/auth/presentation/pages/splash_page.dart';
import 'package:tutora/features/parent/presentation/screens/parent_bookings_screen.dart';
import 'package:tutora/features/parent/presentation/screens/parent_calendar_screen.dart';
import 'package:tutora/features/parent/presentation/screens/parent_edit_info_screen.dart';
import 'package:tutora/features/parent/presentation/screens/parent_home_screen.dart';
import 'package:tutora/features/parent/presentation/screens/parent_marketplace_screen.dart';
import 'package:tutora/features/parent/presentation/screens/parent_profile_screen.dart';
import 'package:tutora/features/parent/presentation/screens/parent_student_detail_screen.dart';
import 'package:tutora/features/parent/presentation/screens/parent_tutor_detail_screen.dart';
import 'package:tutora/features/parent/presentation/shell/parent_shell.dart';
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

// Auth-only routes — no role guard needed
const Set<String> _publicPaths = {
  AppRoutes.splash,
  AppRoutes.login,
  AppRoutes.register,
  AppRoutes.registerParent,
  AppRoutes.forgot,
  AppRoutes.otp,
};

// Routes that belong exclusively to each role
const _studentOnlyPrefixes = ['/student/'];
const _tutorOnlyPrefixes = ['/tutor/'];
const _parentOnlyPrefixes = ['/parent/'];

bool _isPublic(String path) => _publicPaths.any((p) => path == p);

String? _roleGuard(String path, UserRole role) {
  if (_isPublic(path)) return null;

  final isStudentPath = _studentOnlyPrefixes.any(path.startsWith);
  final isTutorPath = _tutorOnlyPrefixes.any(path.startsWith);
  final isParentPath = _parentOnlyPrefixes.any(path.startsWith);

  // If on a role-specific path, verify it matches the JWT role
  if (isStudentPath && role != UserRole.student) {
    return _homeForRole(role);
  }
  if (isTutorPath && role != UserRole.tutor) {
    return _homeForRole(role);
  }
  if (isParentPath && role != UserRole.parent) {
    return _homeForRole(role);
  }

  // Shared routes like /notifications — guard: must be logged in (handled by token check below)
  return null;
}

String _homeForRole(UserRole role) => switch (role) {
  UserRole.student => AppRoutes.studentHome,
  UserRole.tutor => AppRoutes.tutorHome,
  UserRole.parent => AppRoutes.parentHome,
  UserRole.unknown => AppRoutes.login,
};

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

      // Role guard
      return _roleGuard(path, claims.role);
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
        path: AppRoutes.register,
        builder: (context, _) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.registerParent,
        builder: (context, _) => const RegisterParentPage(),
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

      // Student-only standalone routes
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
        builder: (context, state) => StudentSolutionPage(
          imageBytes: state.extra as Uint8List?,
        ),
      ),

      // Student shell (5 tabs)
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

      // Tutor-only standalone routes
      GoRoute(
        path: AppRoutes.tutorNotifications,
        builder: (context, _) => const TutorNotificationsScreen(),
      ),

      // Tutor shell (5 tabs)
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

      // Parent-only standalone routes
      GoRoute(
        path: AppRoutes.parentNotifications,
        builder: (context, _) => const StudentNotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.parentCalendar,
        builder: (context, _) => const ParentCalendarPage(),
      ),
      GoRoute(
        path: AppRoutes.parentBookings,
        builder: (context, _) => const ParentBookingsPage(),
      ),
      GoRoute(
        path: AppRoutes.parentLessonConfirm,
        builder: (context, _) => const ParentHomePage(),
      ),
      GoRoute(
        path: AppRoutes.parentEditInfo,
        builder: (context, _) => const ParentEditInfoScreen(),
      ),

      // Parent shell (3 tabs)
      StatefulShellRoute.indexedStack(
        builder: (context, _, shell) => ParentShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.parentHome,
                builder: (context, _) => const ParentHomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.parentSearch,
                builder: (context, _) => const ParentMarketplacePage(),
                routes: [
                  GoRoute(
                    path: 'tutor/:id',
                    builder: (context, state) => ParentTutorDetailPage(
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
                path: AppRoutes.parentProfile,
                builder: (context, _) => const ParentProfilePage(),
                routes: [
                  GoRoute(
                    path: 'student/:id',
                    builder: (context, state) => ParentStudentDetailPage(
                      studentId: state.pathParameters['id'] ?? '',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
