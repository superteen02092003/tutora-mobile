import 'package:flutter_test/flutter_test.dart';
import 'package:tutora/core/errors/failure.dart';
import 'package:tutora/features/auth/domain/repositories/auth_repository.dart';
import 'package:tutora/features/auth/domain/usecases/forgot_password_usecase.dart';
import 'package:tutora/features/auth/domain/usecases/login_usecase.dart';
import 'package:tutora/features/auth/domain/usecases/register_tutor_usecase.dart';
import 'package:tutora/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:tutora/features/auth/domain/usecases/verify_phone_usecase.dart';

/// Ghi lại lời gọi repository: validation sai thì KHÔNG được gọi server.
class _RecordingRepo implements AuthRepository {
  final calls = <String>[];

  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls.add(invocation.memberName.toString());
    return Future.value((data: null, failure: null));
  }
}

void main() {
  late _RecordingRepo repo;
  setUp(() => repo = _RecordingRepo());

  void expectRejected(Result<Object?> r, String message) {
    expect(r.failure, isA<ValidationFailure>());
    expect(r.failure!.message, message);
    expect(repo.calls, isEmpty);
  }

  void expectPassed(Result<Object?> r) {
    expect(r.failure, isNull);
    expect(repo.calls, hasLength(1));
  }

  group('Đăng ký gia sư (R3)', () {
    Future<Result<String>> register({
      String name = 'Nguyễn Văn A',
      String phone = '0901234567',
      String password = 'abcd1234',
    }) => RegisterTutorUseCase(
      repo,
    )(fullName: name, phone: phone, password: password);

    test('họ tên dưới 2 ký tự', () async {
      expectRejected(
        await register(name: ' A '),
        'Họ tên phải có ít nhất 2 ký tự.',
      );
    });

    for (final phone in [
      '',
      '12345',
      '090123',
      '1901234567',
      '09012345678901',
    ]) {
      test('SĐT sai "$phone"', () async {
        expectRejected(
          await register(phone: phone),
          'Số điện thoại không hợp lệ.',
        );
      });
    }

    for (final phone in [
      '0901234567',
      '+84901234567',
      '84901234567',
      '090 123 4567',
    ]) {
      test('SĐT hợp lệ "$phone"', () async {
        expectPassed(await register(phone: phone));
      });
    }

    test('mật khẩu 7 ký tự bị chặn (tối thiểu 8)', () async {
      expectRejected(
        await register(password: 'abc1234'),
        'Mật khẩu phải có ít nhất 8 ký tự.',
      );
    });

    test('mật khẩu đúng 8 ký tự hợp lệ', () async {
      expectPassed(await register());
    });
  });

  group('Xác thực OTP (R3)', () {
    for (final otp in ['', '12345', '1234567']) {
      test('OTP "$otp" không đủ 6 số', () async {
        expectRejected(
          await VerifyPhoneUseCase(repo)(phone: '0901234567', otp: otp),
          'Mã OTP phải có 6 chữ số.',
        );
      });
    }

    test('OTP 6 số hợp lệ', () async {
      expectPassed(
        await VerifyPhoneUseCase(repo)(phone: '0901234567', otp: ' 123456 '),
      );
    });
  });

  group('Đăng nhập (R2)', () {
    Future<Result<Object?>> login(String id, String pass) =>
        LoginUseCase(repo)(emailOrPhone: id, password: pass);

    test('bỏ trống', () async {
      expectRejected(await login('', 'x'), 'Vui lòng nhập đầy đủ thông tin.');
      expectRejected(
        await login('0901234567', ''),
        'Vui lòng nhập đầy đủ thông tin.',
      );
    });

    test('SĐT quá ngắn', () async {
      expectRejected(
        await login('0901', 'abcd1234'),
        'Số điện thoại không hợp lệ.',
      );
    });

    test('email sai', () async {
      expectRejected(await login('a@b', 'abcd1234'), 'Email không hợp lệ.');
    });

    test('SĐT hợp lệ', () async {
      expectPassed(await login('0901234567', 'abcd1234'));
    });
  });

  group('Quên mật khẩu (R4)', () {
    test('bỏ trống SĐT', () async {
      expectRejected(
        await ForgotPasswordUseCase(repo)(phone: ' '),
        'Vui lòng nhập số điện thoại.',
      );
    });

    test('SĐT sai', () async {
      expectRejected(
        await ForgotPasswordUseCase(repo)(phone: '12345'),
        'Số điện thoại không hợp lệ.',
      );
    });

    for (final phone in [
      '0901234567',
      '+84901234567',
      '84901234567',
      '090 123 4567',
    ]) {
      test('SĐT hợp lệ "$phone" (giống màn đăng ký)', () async {
        expectPassed(await ForgotPasswordUseCase(repo)(phone: phone));
      });
    }
  });

  group('Đặt lại mật khẩu (R4)', () {
    Future<Result<void>> reset({
      String otp = '123456',
      String pass = 'abcd1234',
    }) => ResetPasswordUseCase(
      repo,
    )(phone: '0901234567', otp: otp, newPassword: pass);

    test('OTP không đủ 6 số', () async {
      expectRejected(await reset(otp: '123'), 'Mã OTP phải có 6 chữ số.');
    });

    test('mật khẩu mới dưới 8 ký tự', () async {
      expectRejected(
        await reset(pass: 'abc1234'),
        'Mật khẩu phải có ít nhất 8 ký tự.',
      );
    });

    test('mật khẩu mới đúng 8 ký tự hợp lệ', () async {
      expectPassed(await reset());
    });

    test('hợp lệ', () async {
      expectPassed(await reset());
    });
  });
}
