// Domain-layer error representation — use Result<T> in use cases
sealed class Failure {
  const Failure(this.message);
  final String message;
}

final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Lỗi kết nối mạng. Vui lòng thử lại.']);
}

final class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Phiên đăng nhập đã hết hạn.']);
}

final class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Lỗi máy chủ. Vui lòng thử lại sau.']);
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Không tìm thấy dữ liệu.']);
}

final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

// Dart 3 sealed — use switch for exhaustive matching in domain/presentation
typedef Result<T> = ({T? data, Failure? failure});

extension ResultX<T> on Result<T> {
  bool get isSuccess => failure == null;
  T get requireData => data as T;
}
