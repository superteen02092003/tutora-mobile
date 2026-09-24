import 'package:flutter_test/flutter_test.dart';
import 'package:tutora/features/tutor/data/services/lesson_recorder.dart';

/// Quyết định dọn bản ghi còn sót trên máy gia sư khi mở app.
void main() {
  const fresh = Duration(days: 1);

  test('server đã nhận xong bản ghi thì xoá bản trên máy', () {
    for (final status in [
      'processing',
      'awaiting_approval',
      'sent',
      'failed',
      'discarded',
      'scheduled',
    ]) {
      expect(
        shouldDeleteLocalRecording(age: fresh, serverStatus: status),
        isTrue,
        reason: status,
      );
    }
  });

  test('server còn chờ đoạn thì giữ bản trên máy', () {
    expect(
      shouldDeleteLocalRecording(age: fresh, serverStatus: 'recording'),
      isFalse,
    );
    expect(
      shouldDeleteLocalRecording(age: fresh, serverStatus: 'uploading'),
      isFalse,
    );
  });

  test('buổi đã bị xoá trên server (404) thì xoá bản trên máy', () {
    expect(shouldDeleteLocalRecording(age: fresh, notFound: true), isTrue);
  });

  test('không hỏi được server thì để lần sau', () {
    expect(shouldDeleteLocalRecording(age: fresh), isFalse);
  });

  test('quá hạn 90 ngày thì xoá dù server nói gì', () {
    expect(
      shouldDeleteLocalRecording(
        age: localRecordingMaxAge,
        serverStatus: 'recording',
      ),
      isTrue,
    );
    expect(shouldDeleteLocalRecording(age: localRecordingMaxAge), isTrue);
  });
}
