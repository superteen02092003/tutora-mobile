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
  static const register = '/register';
  static const forgot = '/forgot';
  static const otp = '/otp';

  // Tutor shell tabs — Trang chủ · Lịch (Hồ sơ là màn con)
  static const tutorHome = '/tutor/home';
  static const tutorSchedule = '/tutor/schedule';
  // Tab V5.6 (2026-11-12): Trang chủ · Lộ trình · Bài học · Học sinh.
  static const tutorPath = '/tutor/path';
  static const tutorStudents = '/tutor/students';
  // Danh sách bản ghi âm (T6) — không còn là tab, mở từ Lộ trình.
  static const tutorRecordings = '/tutor/recordings';
  static const tutorRecordingTips = '/tutor/recorder/tips';
  static const tutorProfile = '/tutor/profile';
  // T1 Chào mừng — lần đầu sau đăng nhập, và "Xem lại" từ Cài đặt.
  static const tutorWelcome = '/tutor/welcome';

  // Tutor sub-routes
  static const tutorNotifications = '/tutor/notifications';
  static const tutorRecorder = '/tutor/recorder';
  static const tutorRecording = '/tutor/recorder/session';
  static const tutorReportReview = '/tutor/recorder/report';
  // T11 Ghi âm tốt — ngay sau khi kết thúc buổi, trước bản nháp báo cáo.
  static const tutorRecordedWell = '/tutor/recorder/done';
  static const tutorRecordingDetail = '/tutor/recorder/detail';

  // Topi v1 — chỉ mở được khi cờ `plan` bật.
  static const tutorBeforeLesson = '/tutor/recorder/before';
}
