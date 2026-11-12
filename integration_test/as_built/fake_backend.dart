// As-built screenshots: an in-memory stand-in for the TopTutor backend.
//
// Everything here is FICTIONAL (pupils "Minh An" and "Bao", tutor "Ha").
// It is plugged in as the Dio HttpClientAdapter of `apiClientProvider`, so the
// app's real datasources and DTO parsing run, but no network request is made.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Which kind of data the fake backend serves.
enum Scenario {
  /// Tutor with two pupils, a lesson today, a report waiting for review.
  loaded,

  /// New tutor: no pupils, no lessons, no notifications.
  empty,

  /// Every request answers HTTP 500.
  error,

  /// Every request hangs (loading / skeleton states).
  loading,

  /// No pupils in the address book, one lesson today (entry sheet "confirm").
  oneLesson,
}

DateTime _local(int y, int m, int d, int h, [int min = 0]) =>
    DateTime(y, m, d, h, min);

String _utc(DateTime local) => local.toUtc().toIso8601String();

/// Local date-time -> the BE style "timestamp without time zone, UTC, no Z".
String _utcNoZ(DateTime local) =>
    local.toUtc().toIso8601String().replaceFirst('Z', '');

Map<String, dynamic> _ok(Object? content) => {'content': content};

class FakeBackend implements HttpClientAdapter {
  FakeBackend({DateTime? now}) : now = now ?? DateTime.now();

  Scenario scenario = Scenario.loaded;

  /// How many booking-platform classes (legacy side of the app) to serve.
  /// 0 = none; the pilot tutor only has off-platform pupils.
  int bookingClasses = 0;

  /// Requests seen, as "GET /path" (the test prints them: proof of no network).
  final List<String> log = [];

  /// Recording ids that answer 500 (to show the report error state).
  final Set<String> failingRecordings = {'rec-error'};

  final DateTime now;

  DateTime get today => DateTime(now.year, now.month, now.day);

  static const tutorId = '00000000-0000-0000-0000-00000000ha01';

  /// The lesson on the design canvas: Monday 9 Nov, 86 of 90 minutes.
  DateTime get lesson9Nov => _local(2026, 11, 9, 19);

  Map<String, dynamic> studentAn() => {
    'studentId': 'stu-minh-an',
    'fullName': 'Minh An',
    'grade': 8,
    'subject': 'Toán',
    'parentName': 'Mẹ của An',
    'parentPhone': '0900000001',
    'consentStatus': 'parent_confirmed',
    'consentVersion': 'v1',
    'note': 'Hay nhầm dấu khi chuyển vế.',
    'lessonCount': 12,
    'lastLessonAt': _utc(lesson9Nov),
    'schedule': [
      {'dayOfWeek': 1, 'start': '19:00', 'end': '20:30'},
      {'dayOfWeek': 4, 'start': '16:30', 'end': '18:00'},
    ],
    'scheduleFrom': '2026-09-01',
    'scheduleUntil': null,
    'parentLinkStatus': 'linked',
    'parentLinkedAt': _utc(_local(2026, 10, 5, 20)),
    'parentZaloName': 'Mẹ An',
  };

  Map<String, dynamic> studentBao() => {
    'studentId': 'stu-bao',
    'fullName': 'Bao',
    'grade': 9,
    'subject': 'Toán',
    'parentName': 'Bố của Bao',
    'parentPhone': '0900000002',
    'consentStatus': 'tutor_confirmed',
    'note': null,
    'lessonCount': 5,
    'lastLessonAt': _utc(_local(2026, 11, 10, 19)),
    'schedule': [
      {'dayOfWeek': 2, 'start': '19:00', 'end': '20:30'},
      {'dayOfWeek': 4, 'start': '19:00', 'end': '20:30'},
    ],
    'scheduleFrom': '2026-10-01',
    'scheduleUntil': null,
    'parentLinkStatus': 'invited',
    'inviteExpiresAt': _utc(now.add(const Duration(days: 2))),
  };

  Map<String, dynamic> _lesson({
    required String id,
    required String student,
    required String name,
    required int grade,
    required DateTime start,
    required int minutes,
    required String status,
    String ai = 'none',
    int durationSec = 0,
  }) => {
    'lessonId': id,
    'studentId': student,
    'studentName': name,
    'grade': grade,
    'subject': 'Toán',
    'scheduledStart': _utc(start),
    'scheduledEnd': _utc(start.add(Duration(minutes: minutes))),
    'status': status,
    'aiStatus': ai,
    'durationSec': durationSec,
    if (durationSec > 0) 'startedAt': _utc(start),
  };

  List<Map<String, dynamic>> recorderLessons() {
    final t = today;
    return [
      // Today: two lessons still to record.
      _lesson(
        id: 'les-an-today',
        student: 'stu-minh-an',
        name: 'Minh An',
        grade: 8,
        start: _local(t.year, t.month, t.day, 16, 30),
        minutes: 90,
        status: 'scheduled',
      ),
      _lesson(
        id: 'les-bao-today',
        student: 'stu-bao',
        name: 'Bao',
        grade: 9,
        start: _local(t.year, t.month, t.day, 19),
        minutes: 90,
        status: 'scheduled',
      ),
      // 9 Nov: recorded 86 of 90 min, report waiting for the tutor.
      _lesson(
        id: 'rec-ready',
        student: 'stu-minh-an',
        name: 'Minh An',
        grade: 8,
        start: lesson9Nov,
        minutes: 90,
        status: 'awaiting_approval',
        ai: 'completed',
        durationSec: 86 * 60,
      ),
      // 10 Nov: AI still writing.
      _lesson(
        id: 'rec-ai',
        student: 'stu-bao',
        name: 'Bao',
        grade: 9,
        start: _local(2026, 11, 10, 19),
        minutes: 90,
        status: 'processing',
        ai: 'processing',
        durationSec: 88 * 60,
      ),
      // 2 Nov: sent to the parent.
      _lesson(
        id: 'rec-sent',
        student: 'stu-minh-an',
        name: 'Minh An',
        grade: 8,
        start: _local(2026, 11, 2, 19),
        minutes: 90,
        status: 'sent',
        ai: 'completed',
        durationSec: 89 * 60,
      ),
      // 3 Nov: AI failed.
      _lesson(
        id: 'rec-failed',
        student: 'stu-bao',
        name: 'Bao',
        grade: 9,
        start: _local(2026, 11, 3, 19),
        minutes: 90,
        status: 'failed',
        ai: 'failed',
        durationSec: 41 * 60,
      ),
    ];
  }

  Map<String, dynamic> _base(
    String id, {
    required String status,
    required String ai,
    required String student,
    required String name,
    required int grade,
    required DateTime start,
    required int durationSec,
  }) => {
    'recordingId': id,
    'status': status,
    'aiStatus': ai,
    'partCount': (durationSec / 300).ceil(),
    'bytes': durationSec * 4100,
    'durationSec': durationSec,
    'studentId': student,
    'studentName': name,
    'grade': grade,
    'subject': 'Toán',
    'deliveryChannel': 'zns',
    'scheduledStart': _utcNoZ(start),
    'startedAt': _utcNoZ(start.add(const Duration(minutes: 1))),
    'endedAt': _utcNoZ(start.add(Duration(seconds: 60 + durationSec))),
    'parentPhone': student == 'stu-minh-an' ? '0900000001' : '0900000002',
    'transcriptStatus': 'completed',
    'audioAvailable': false,
  };

  Map<String, dynamic> recordingStatus(String id) {
    switch (id) {
      case 'rec-ai':
        return _base(
          id,
          status: 'processing',
          ai: 'processing',
          student: 'stu-bao',
          name: 'Bao',
          grade: 9,
          start: _local(2026, 11, 10, 19),
          durationSec: 88 * 60,
        );
      case 'rec-failed':
        return _base(
          id,
          status: 'failed',
          ai: 'failed',
          student: 'stu-bao',
          name: 'Bao',
          grade: 9,
          start: _local(2026, 11, 3, 19),
          durationSec: 41 * 60,
        )..['errorMessage'] = 'Bản ghi quá ngắn hoặc quá nhỏ để soạn báo cáo.';
      case 'rec-sent':
        return _base(
            id,
            status: 'sent',
            ai: 'completed',
            student: 'stu-minh-an',
            name: 'Minh An',
            grade: 8,
            start: _local(2026, 11, 2, 19),
            durationSec: 89 * 60,
          )
          ..addAll(_report())
          ..['deliveryStatus'] = 'sent'
          ..['approvedAt'] = _utcNoZ(_local(2026, 11, 2, 21))
          ..['sentAt'] = _utcNoZ(_local(2026, 11, 2, 21, 1));
      default:
        // 'rec-ready' and anything a recording just created (e.g. 'rec-new').
        return _base(
            id,
            status: 'awaiting_approval',
            ai: 'completed',
            student: 'stu-minh-an',
            name: 'Minh An',
            grade: 8,
            start: lesson9Nov,
            durationSec: 86 * 60,
          )
          ..addAll(_report())
          ..['deliveryStatus'] = 'pending'
          ..['transcript'] =
              '[00:12] Gia sư: Hôm nay mình ôn bình phương của một tổng nhé.\n'
              '[00:30] Học sinh: Dạ, (a+b)^2 bằng a^2 cộng b^2 ạ?\n'
              '[00:41] Gia sư: Gần đúng rồi, còn thiếu một số hạng.';
    }
  }

  Map<String, dynamic> _report() => {
    'lessonContent':
        'Ôn hằng đẳng thức bình phương của một tổng và một hiệu. Minh An '
        'làm 6 bài khai triển, sai 2 bài do quên số hạng 2ab. Sau khi được '
        'gợi ý bằng hình vuông cạnh (a+b), em tự làm đúng 3 bài còn lại.',
    'homework': 'Làm bài 4, 5 trang 12 (SGK Toán 8, tập 1).',
    'tutorNotes':
        'An hiểu nhanh khi có hình minh hoạ. Nên cho thêm bài tự kiểm tra.',
    'zaloContent':
        'Hôm nay An ôn hằng đẳng thức (a+b)². Em làm đúng 4/6 bài, sai do '
        'quên số hạng 2ab.',
    'zaloHomework': 'Làm bài 4, 5 trang 12 SGK Toán 8.',
    'zaloNotes':
        'An tiến bộ khi có hình minh hoạ. Cô sẽ cho thêm bài kiểm tra.',
    'sessionMinutes': {
      'summary':
          'Buổi ôn hằng đẳng thức bình phương của một tổng, một hiệu; học sinh '
          'nắm công thức nhưng còn quên số hạng 2ab khi khai triển nhanh.',
      'keyPoints': [
        'Công thức (a+b)² = a² + 2ab + b² và (a−b)² = a² − 2ab + b².',
        'Minh hoạ bằng hình vuông cạnh a+b.',
      ],
      'followUps': [
        'Cho 3 bài khai triển nhanh để kiểm tra số hạng 2ab.',
        'Chuyển sang hằng đẳng thức hiệu hai bình phương.',
      ],
      'sections': [
        {
          'title': 'Khởi động (10 phút)',
          'details': ['Nhắc lại phép nhân đa thức.', 'Kiểm tra bài về nhà.'],
        },
        {
          'title': 'Bài mới (50 phút)',
          'details': ['Dẫn dắt bằng hình vuông.', 'Học sinh tự khai triển.'],
        },
      ],
      'exercises': [
        {'type': 'Khai triển (a+b)²', 'result': 'Tự làm đúng'},
        {
          'type': 'Khai triển (2x−3)²',
          'result': 'Đúng sau khi được gợi ý',
          'note': 'Quên hệ số khi nhân đôi.',
        },
        {'type': 'Rút gọn biểu thức', 'result': 'Làm sai'},
      ],
      'strengths': ['Nhớ công thức', 'Biết vẽ hình minh hoạ'],
      'difficulties': ['Quên số hạng 2ab', 'Nhầm dấu khi có số âm'],
      'usefulNotes': ['Học tốt hơn khi có hình vẽ.'],
      'teachingNotes': [
        {
          'content': 'Cho học sinh tự giải thích lại bước khai triển.',
          'example': 'Em thử nói vì sao còn thiếu 2ab?',
        },
      ],
    },
  };

  Map<String, dynamic>? lessonTopi(String id) {
    if (id != 'rec-ready' && id != 'rec-sent') return null;
    return {
      'lesson_id': id,
      'plan': {
        'gaps': [
          {
            'rank': 1,
            'node': 'alg.identities.square_sum',
            'title': 'Quên số hạng 2ab',
            'wrong': '(a+b)² = a² + b²',
            'right': '(a+b)² = a² + 2ab + b²',
            'role': 'focus',
            'seen_in_lessons': 2,
          },
          {
            'rank': 2,
            'node': 'alg.signs',
            'title': 'Nhầm dấu khi có số âm',
            'wrong': '(−3)² = −9',
            'right': '(−3)² = 9',
            'role': 'next',
            'seen_in_lessons': 1,
          },
        ],
        'steps': [
          {
            'name': 'check',
            'minutes': 5,
            'asks': [
              {
                'say': 'Em khai triển giúp cô (x+4)².',
                'problem': '(x+4)²',
                'answer': 'x² + 8x + 16',
                'verified': true,
              },
            ],
          },
          {
            'name': 'homework',
            'minutes': 5,
            'asks': [
              {'say': 'Cho cô xem bài 4 trang 12.'},
            ],
          },
          {'name': 'memory', 'minutes': 3},
          {'name': 'warmup', 'minutes': 2},
        ],
      },
      'tips': {
        'did_well': {
          'text': 'Em tự giải thích được hình vuông cạnh a+b.',
          'seg': 4,
          'quote': 'Dạ, phần này là a nhân b hai lần.',
        },
        'try_next': {'text': 'Chờ em trả lời thêm vài giây trước khi gợi ý.'},
        'talk_more': {'text': 'Cho em nói nhiều hơn khi chữa bài.'},
      },
      'skills': {
        'observations': [
          {
            'node': 'alg.identities.square_sum',
            'name_vi': 'Bình phương của một tổng',
          },
          {'node': 'alg.signs', 'name_vi': 'Dấu của số âm'},
        ],
        'first_seen': [
          {
            'node': 'alg.identities.square_sum',
            'level': 'improving',
            'name_vi': 'Bình phương của một tổng',
          },
        ],
        'proposed_changes': [
          {
            'node': 'alg.signs',
            'from': 'to_do',
            'to': 'improving',
            'star': true,
            'name_vi': 'Dấu của số âm',
          },
        ],
      },
    };
  }

  /// No booking-platform data: the pilot tutor only has off-platform pupils.
  Map<String, dynamic> dashboard() => {
    'upcomingClassSessions': 0,
    'completedThisMonth': 0,
    'earningsThisMonth': 0,
    'averageRating': 0,
    'totalReviews': 0,
    'frozenBalance': 0,
    'pendingConfirmation': 0,
    'activeDisputes': 0,
    'awaitingReport': 0,
    'awaitingReportClassSessions': <dynamic>[],
    'nextClassSessions': <dynamic>[],
  };

  ResponseBody _json(Object? body, [int status = 200]) =>
      ResponseBody.fromString(
        jsonEncode(body),
        status,
        headers: {
          Headers.contentTypeHeader: ['application/json; charset=utf-8'],
        },
      );

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.path;
    log.add('${options.method} $path');

    if (scenario == Scenario.loading) {
      // Never answers: the screen stays in its loading state.
      return Completer<ResponseBody>().future;
    }
    if (scenario == Scenario.error) {
      return _json({'message': 'Lỗi giả lập'}, 500);
    }
    final empty = scenario == Scenario.empty;

    if (options.method == 'GET') {
      if (path == '/users/profile') {
        return _json(
          _ok({
            'userid': tutorId,
            'fullname': 'Ha',
            'email': 'ha@example.com',
            'phone': '0900000000',
            'birthdate': '1998-05-20',
            'address': 'Hà Nội',
            'gender': 'female',
            'avatarurl': '',
            'createdat': '2026-09-01T00:00:00Z',
          }),
        );
      }
      if (path.endsWith('/verification/progress')) {
        return _json(_ok({'sections': <String, dynamic>{}}));
      }
      if (path == '/tutors/me/profile') return _json(_ok(<String, dynamic>{}));
      if (path.endsWith('/accepting-bookings')) {
        return _json(_ok({'accepting': true}));
      }
      if (path == '/tutor/class-sessions/dashboard') {
        return _json(_ok(dashboard()));
      }
      if (path == '/tutor/class-sessions/calendar') {
        return _json(_ok(_calendarDays()));
      }
      if (path == '/tutor/class-sessions') {
        final b = options.queryParameters['bookingId'];
        return _json(_ok(b == null ? <dynamic>[] : _classSessions(b as int)));
      }
      if (path == '/tutor/classes') {
        final items = _classes();
        return _json(_ok({'items': items, 'totalCount': items.length}));
      }
      if (RegExp(r'^/class-sessions/\d+$').hasMatch(path)) {
        return _json(
          _ok({
            'classSessionPrice': 200000,
            'student': {'gradeLevelName': 'Lớp 7'},
          }),
        );
      }
      if (path == '/tutor/availabilities') return _json(_ok(<dynamic>[]));
      if (path == '/tutors/bookings') {
        return _json(_ok({'items': <dynamic>[], 'totalCount': 0}));
      }
      if (path == '/notifications/mine') {
        return _json(_ok(empty ? <dynamic>[] : _notifications()));
      }
      if (path == '/notifications/mine/unread-count') {
        return _json(_ok({'unreadCount': empty ? 0 : 2}));
      }
      if (path == '/recorder/students') {
        return _json(
          _ok(
            empty || scenario == Scenario.oneLesson
                ? <dynamic>[]
                : [studentAn(), studentBao()],
          ),
        );
      }
      if (path.startsWith('/recorder/students/')) {
        final id = path.split('/').last;
        return _json(_ok(id == 'stu-bao' ? studentBao() : studentAn()));
      }
      if (path == '/recorder/lessons') {
        if (empty) return _json(_ok(<dynamic>[]));
        final sid = options.queryParameters['studentId'];
        final all = scenario == Scenario.oneLesson
            ? recorderLessons()
                  .where((l) => l['lessonId'] == 'les-bao-today')
                  .toList()
            : recorderLessons();
        return _json(
          _ok(
            sid == null
                ? all
                : all.where((l) => l['studentId'] == sid).toList(),
          ),
        );
      }
      if (path == '/recording/app/topi/flags') {
        return _json(
          _ok({'report': true, 'plan': true, 'tips': true, 'skills': true}),
        );
      }
      final topi = RegExp(r'^/recording/app/([^/]+)/topi$').firstMatch(path);
      if (topi != null) {
        final t = lessonTopi(topi.group(1)!);
        if (t == null) return _json({'message': 'not found'}, 404);
        return _json(_ok(t));
      }
      final rec = RegExp(r'^/recording/app/([^/]+)$').firstMatch(path);
      if (rec != null) {
        final id = rec.group(1)!;
        if (failingRecordings.contains(id)) {
          return _json({'message': 'Lỗi giả lập'}, 500);
        }
        return _json(_ok(recordingStatus(id)));
      }
    }

    // Anything else (writes, unknown reads): succeed with an empty body so a
    // stray tap cannot fail loudly. Nothing leaves the process.
    return _json(_ok(<String, dynamic>{}));
  }

  static const _classNames = ['Linh', 'Chi', 'Duc', 'Hoa', 'Nam'];

  DateTime _nextSession(int i) {
    final t = today.add(Duration(days: 1 + i));
    return _local(t.year, t.month, t.day, 17);
  }

  List<Map<String, dynamic>> _classes() => [
    for (var i = 0; i < bookingClasses && i < _classNames.length; i++)
      {
        'bookingId': 101 + i,
        'studentName': _classNames[i],
        'subjectName': 'Tiếng Anh',
        'totalSessions': 8,
        'completedSessions': 3,
        'schedule': 'T3 17:00, T5 17:00',
        'nextSessionStart': _utc(_nextSession(i)),
        'status': 'in_progress',
      },
  ];

  Map<String, dynamic> _session(
    int booking,
    int n,
    String status,
    DateTime start,
  ) => {
    'classSessionId': booking * 10 + n,
    'bookingId': booking,
    'studentName': _classNames[booking - 101],
    'subjectName': 'Tiếng Anh',
    'scheduledStart': _utc(start),
    'scheduledEnd': _utc(start.add(const Duration(hours: 1))),
    'status': status,
  };

  List<Map<String, dynamic>> _classSessions(int booking) {
    if (booking < 101 || booking - 101 >= bookingClasses) return [];
    final next = _nextSession(booking - 101);
    return [
      _session(
        booking,
        1,
        'completed',
        next.subtract(const Duration(days: 14)),
      ),
      _session(booking, 2, 'completed', next.subtract(const Duration(days: 7))),
      _session(booking, 3, 'scheduled', next),
      _session(booking, 4, 'scheduled', next.add(const Duration(days: 7))),
    ];
  }

  List<Map<String, dynamic>> _calendarDays() => [
    for (var i = 0; i < bookingClasses && i < _classNames.length; i++)
      {
        'date': _nextSession(i).toIso8601String().substring(0, 10),
        'classSessions': [_session(101 + i, 3, 'scheduled', _nextSession(i))],
      },
  ];

  List<Map<String, dynamic>> _notifications() => [
    {
      'notificationid': 1,
      'userid': tutorId,
      'title': 'Báo cáo buổi học đã sẵn sàng',
      'message': 'Báo cáo buổi học của Minh An đang chờ bạn duyệt.',
      'isread': false,
      'createdat': now.subtract(const Duration(minutes: 20)).toIso8601String(),
      'type': 'Report',
    },
    {
      'notificationid': 2,
      'userid': tutorId,
      'title': 'Nhắc lịch dạy',
      'message': 'Buổi học với Bao bắt đầu lúc 19:00 hôm nay.',
      'isread': false,
      'createdat': now.subtract(const Duration(hours: 3)).toIso8601String(),
    },
    {
      'notificationid': 3,
      'userid': tutorId,
      'title': 'Báo cáo đã gửi phụ huynh',
      'message': 'Phụ huynh của Minh An đã nhận báo cáo ngày 2/11.',
      'isread': true,
      'createdat': now.subtract(const Duration(days: 9)).toIso8601String(),
    },
  ];

  @override
  void close({bool force = false}) {}
}
