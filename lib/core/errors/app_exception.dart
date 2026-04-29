sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;
}

final class NetworkException extends AppException {
  const NetworkException([super.message = 'Lỗi kết nối mạng. Vui lòng thử lại.']);
}

final class UnauthorizedException extends AppException {
  const UnauthorizedException([super.message = 'Phiên đăng nhập đã hết hạn.']);
}

final class ServerException extends AppException {
  const ServerException([super.message = 'Lỗi máy chủ. Vui lòng thử lại sau.']);
  const ServerException.withMessage(String message) : this(message);
}

final class NotFoundException extends AppException {
  const NotFoundException([super.message = 'Không tìm thấy dữ liệu.']);
}

final class ValidationException extends AppException {
  const ValidationException(super.message);
}
