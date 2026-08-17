/// Đường dẫn asset dùng chung.
abstract final class AppAssets {
  static const String mascot = 'assets/mascot/sample.png';

  /// Hero trang chủ: có buổi sắp tới vs chưa có buổi nào.
  static const String heroUpcoming = 'assets/mascot/next-lesson.png';
  static const String heroNoLesson = 'assets/mascot/no-tutor.png';

  /// Minh hoạ ô hành động nhanh.
  static const String actionSolve = 'assets/mascot/ai-solution.png';
  static const String actionFindTutor = 'assets/mascot/explore.png';

  /// Minh hoạ khi chưa có dữ liệu.
  static const String emptyClasses = heroNoLesson;
  static const String emptyAsk = actionSolve;

  /// Minh hoạ "đã xác minh CCCD" ở màn Xác minh thông tin.
  static const String verifiedIdentity = mascot;
}
