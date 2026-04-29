abstract final class AppRoutes {
  // Auth
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';

  // Parent portal
  static const parentHome = '/parent/home';
  static const tutorSearch = '/parent/search';
  static const tutorDetail = '/parent/tutor/:id';
  static const booking = '/parent/booking/:tutorId';

  // Student portal
  static const studentHome = '/student/home';
  static const studentSchedule = '/student/schedule';

  // Tutor portal
  static const tutorHome = '/tutor/home';
  static const tutorSchedule = '/tutor/schedule';
  static const tutorEarnings = '/tutor/earnings';

  // Shared
  static const profile = '/profile';
  static const notifications = '/notifications';
  static const chat = '/chat/:roomId';
}
