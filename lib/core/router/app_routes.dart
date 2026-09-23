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
  static const forgot = '/forgot';
  static const otp = '/otp';

  // Tutor shell tabs — Trang chủ · Lịch (Hồ sơ là màn con)
  static const tutorHome = '/tutor/home';
  static const tutorSchedule = '/tutor/schedule';
  static const tutorProfile = '/tutor/profile';

  // Tutor sub-routes
  static const tutorNotifications = '/tutor/notifications';
  static const tutorRecorder = '/tutor/recorder';
  static const tutorRecording = '/tutor/recorder/session';
  static const tutorReportReview = '/tutor/recorder/report';
  static const tutorRecordingDetail = '/tutor/recorder/detail';
}
