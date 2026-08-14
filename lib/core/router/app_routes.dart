enum OtpMode { register, forgotPassword }

class OtpArgs {
  const OtpArgs({required this.phone, required this.mode});
  final String phone;
  final OtpMode mode;
}

abstract final class AppRoutes {
  // Auth
  static const splash = '/';
  static const login = '/login';
  static const register = '/register'; // role selection screen
  static const registerStudent = '/register/student';
  static const registerTutor = '/register/tutor';
  static const registerParent = '/register/parent';
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
  static const studentSolveHistory = '/student/solve-history';
  static const studentSolveSession = '/student/solve-session/:sessionId';
  static const tutorDetail = '/student/search/tutor/:id';
  static const booking = '/student/search/booking/:tutorId';

  // Tutor shell tabs — Trang chủ · Lịch · Ví · Tin nhắn · Tôi
  static const tutorHome = '/tutor/home';
  static const tutorSchedule = '/tutor/schedule';
  static const tutorWallet = '/tutor/wallet';
  static const tutorMessages = '/tutor/messages';
  static const tutorProfile = '/tutor/profile';

  // Tutor sub-routes
  static const tutorBookingDetail = '/tutor/schedule/booking/:id';
  static const tutorNotifications = '/tutor/notifications';
  static const tutorDisputes = '/tutor/disputes';

  // Parent shell tabs
  static const parentHome = '/parent/home';
  static const parentSearch = '/parent/search';
  static const parentInfo = '/parent/info';
  static const parentMessages = '/parent/messages';
  static const parentProfile = '/parent/profile';

  // Parent sub-routes
  static const parentBookings = '/parent/bookings';
  static const parentNotifications = '/parent/notifications';
  static const parentTutorDetail = '/parent/tutor/:id';
  static const parentEditInfo = '/parent/edit-info';
  static const parentStudentDetail = '/parent/profile/student/:id';
  static const parentAddChild = '/parent/profile/add-child';
  static const parentCalendar = '/parent/profile/calendar';
  static const parentWallet = '/parent/profile/wallet';
  static const parentLessonConfirm = '/parent/lesson/:id/confirm';

  // Shared
  static const chat = '/chat/:roomId';
  static const notifications = '/student/notifications';
}
