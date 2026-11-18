import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutora/features/tutor/data/datasources/topi_datasource.dart';
import 'package:tutora/features/tutor/data/models/topi_models.dart';

import '../integration_test/as_built/fake_backend.dart';

/// Kỹ năng của học sinh (V57-Skills): parse, mức, ngày ôn lại.
void main() {
  test('pupil skills from the fake backend', () async {
    final fake = FakeBackend(now: DateTime(2026, 11, 16, 10));
    final ds = TopiDatasource(Dio()..httpClientAdapter = fake);
    final skills = await ds.getPupilSkills('stu-minh-an');
    expect(
      fake.log.last,
      'GET /recording/app/topi/students/stu-minh-an/skills',
    );
    expect(skills, hasLength(9));
    expect(skills.where((s) => s.level == TopiLevel.standard), hasLength(5));
    expect(skills.where((s) => s.level == TopiLevel.mastered), hasLength(2));
    final today = DateTime(2026, 11, 16);
    final due = skills.where((s) => s.reviewDue(today)).map((s) => s.name);
    expect(due, ['Hiệu hai bình phương', 'Chia đa thức cho đơn thức']);
    expect(skills.first.name, 'Bỏ ngoặc sau dấu trừ');
    expect(skills.first.lessonsSeen, 3);
  });

  test('unknown or missing fields are skipped', () {
    expect(
      parsePupilSkills({
        'skills': [
          {'node': 'N1', 'level': 'nope'},
          {'level': 'standard'},
          {'node': 'N2', 'level': 'standard'},
        ],
      }).map((s) => s.node),
      ['N2'],
    );
  });
}
