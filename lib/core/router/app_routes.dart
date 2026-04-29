abstract final class AppRoutes {
  // Auth (shared)
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';

  // Student portal
  static const studentHome = '/student/home';
  static const studentSchedule = '/student/schedule';
  static const tutorSearch = '/student/search';
  static const tutorDetail = '/student/tutor/:id';
  static const booking = '/student/booking/:tutorId';

  // Tutor portal
  static const tutorHome = '/tutor/home';
  static const tutorSchedule = '/tutor/schedule';
  static const tutorStudents = '/tutor/students';
  static const tutorEarnings = '/tutor/earnings';

  // Shared (both roles)
  static const profile = '/profile';
  static const notifications = '/notifications';
  static const chat = '/chat/:roomId';
}
