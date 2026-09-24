import 'package:url_launcher/url_launcher.dart';

/// Liên kết pháp lý trên tutora.vn — đổi đường dẫn tại đây.
///
/// Web hiển thị văn bản chính sách theo route `/policies/<slug>` (bảng
/// `policy_documents`). `privacy-app` và `data-deletion` là văn bản riêng của
/// app gia sư (migration V20261002).
abstract final class LegalLinks {
  static const String terms = 'https://tutora.vn/policies/terms';
  static const String privacy = 'https://tutora.vn/policies/privacy-app';
  static const String dataDeletion = 'https://tutora.vn/policies/data-deletion';
}

/// Mở [url] bằng trình duyệt ngoài. Trả `false` nếu không mở được.
Future<bool> openExternalUrl(String url) async {
  try {
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    return opened;
  } catch (_) {
    return false;
  }
}
