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
  static const studentBookings = '/student/bookings';
  static const studentBookingDetail = '/student/bookings/:id';
  static const studentMessages = '/student/messages';
  static const studentCapturePlaceholder = '/student/capture-stub';
  static const studentSolution = '/student/solution';
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
  static const tutorNotifications = '/tutor/notifications';

  // Parent shell tabs
  static const parentHome = '/parent/home';
  static const parentSearch = '/parent/search';
  static const parentProfile = '/parent/profile';

  // Parent sub-routes
  static const parentBookings = '/parent/bookings';
  static const parentNotifications = '/parent/notifications';
  static const parentTutorDetail = '/parent/tutor/:id';
  static const parentStudentDetail = '/parent/profile/student/:id';
  static const parentCalendar = '/parent/profile/calendar';
  static const parentLessonConfirm = '/parent/lesson/:id/confirm';

  // Shared
  static const chat = '/chat/:roomId';
  static const notifications = '/student/notifications';
}
