abstract final class AppRoutes {
  // Auth
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const forgot = '/forgot';
  static const otp = '/otp';

  // Student shell tabs
  static const studentHome = '/student/home';
  static const studentCapture = '/student/capture';
  static const studentSearch = '/student/search';
  static const studentProfile = '/student/profile';
  static const studentLessons = '/student/lessons';

  // Student sub-routes
  static const tutorDetail = '/student/search/tutor/:id';
  static const booking = '/student/search/booking/:tutorId';

  // Tutor shell tabs
  static const tutorHome = '/tutor/home';
  static const tutorContribute = '/tutor/contribute';
  static const tutorSchedule = '/tutor/schedule';
  static const tutorMessages = '/tutor/messages';
  static const tutorProfile = '/tutor/profile';

  // Tutor sub-routes
  static const tutorBookingDetail = '/tutor/schedule/booking/:id';

  // Shared
  static const chat = '/chat/:roomId';
  static const notifications = '/notifications';
}
