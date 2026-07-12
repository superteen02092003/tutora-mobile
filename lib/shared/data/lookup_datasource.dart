import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/network/api_client.dart';

class SubjectLookup {
  const SubjectLookup({required this.subjectId, required this.subjectName});

  factory SubjectLookup.fromJson(Map<String, dynamic> j) => SubjectLookup(
    subjectId: j['subjectId'] as int? ?? 0,
    subjectName: j['subjectName'] as String? ?? '',
  );

  final int subjectId;
  final String subjectName;
}

class GradeLevelLookup {
  const GradeLevelLookup({
    required this.gradeLevelId,
    required this.gradeName,
    required this.levelOrder,
  });

  factory GradeLevelLookup.fromJson(Map<String, dynamic> j) => GradeLevelLookup(
    gradeLevelId: j['gradeLevelId'] as int? ?? 0,
    gradeName: j['gradeName'] as String? ?? '',
    levelOrder: j['levelOrder'] as int? ?? 0,
  );

  final int gradeLevelId;
  final String gradeName;
  final int levelOrder;
}

class LookupDatasource {
  const LookupDatasource(this._dio);
  final Dio _dio;

  Future<List<SubjectLookup>> getSubjects() async {
    final res = await _dio.get<dynamic>('/subjects');
    final content =
        (res.data as Map<String, dynamic>)['content'] as List<dynamic>? ?? [];
    return content
        .map((e) => SubjectLookup.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<GradeLevelLookup>> getGradeLevels() async {
    final res = await _dio.get<dynamic>('/grade-levels');
    final content =
        (res.data as Map<String, dynamic>)['content'] as List<dynamic>? ?? [];
    return content
        .map((e) => GradeLevelLookup.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final lookupDatasourceProvider = Provider<LookupDatasource>((ref) {
  return LookupDatasource(ref.read(apiClientProvider));
});

/// Subjects list — cached for the session.
final subjectsProvider = FutureProvider<List<SubjectLookup>>((ref) {
  return ref.read(lookupDatasourceProvider).getSubjects();
});

/// Grade levels list — cached for the session.
final gradeLevelsProvider = FutureProvider<List<GradeLevelLookup>>((ref) {
  return ref.read(lookupDatasourceProvider).getGradeLevels();
});
