/// Gia sư xem lại thay đổi kỹ năng Topi đề xuất cho một buổi (backend
/// `/recording/app/{lessonId}/topi/skill-review`).
class SkillReviewLine {
  const SkillReviewLine({
    required this.seg,
    required this.start,
    required this.speaker,
    required this.text,
    this.evidence = false,
  });

  factory SkillReviewLine.fromJson(Map<String, dynamic> j) => SkillReviewLine(
    seg: (j['seg'] as num?)?.toInt() ?? 0,
    start: (j['start'] as num?)?.toDouble() ?? 0,
    speaker: j['speaker'] as String? ?? 'unknown',
    text: j['text'] as String? ?? '',
    evidence: j['evidence'] as bool? ?? false,
  );

  final int seg;
  final double start;
  final String speaker;
  final String text;

  /// Đoạn Topi dùng làm bằng chứng.
  final bool evidence;

  /// "GS" (gia sư) · "HS" (học sinh) · "" khi không rõ.
  String get who => switch (speaker) {
    'tutor' => 'GS',
    'student' || 'pupil' => 'HS',
    _ => '',
  };
}

class SkillReviewItem {
  const SkillReviewItem({
    required this.id,
    required this.node,
    required this.toLevel,
    required this.status,
    this.nameVi,
    this.fromLevel,
    this.star = false,
    this.firstSeen = false,
    this.reason,
    this.correctedNode,
    this.correctedNameVi,
    this.exercise,
    this.atSec,
    this.hasAudio = false,
    this.context = const [],
  });

  factory SkillReviewItem.fromJson(Map<String, dynamic> j) => SkillReviewItem(
    id: j['id'] as String? ?? '',
    node: j['node'] as String? ?? '',
    nameVi: j['nameVi'] as String?,
    fromLevel: j['fromLevel'] as String?,
    toLevel: j['toLevel'] as String? ?? '',
    star: j['star'] as bool? ?? false,
    firstSeen: j['firstSeen'] as bool? ?? false,
    status: j['status'] as String? ?? 'proposed',
    reason: j['reason'] as String?,
    correctedNode: j['correctedNode'] as String?,
    correctedNameVi: j['correctedNameVi'] as String?,
    exercise: j['exercise'] as String?,
    atSec: (j['atSec'] as num?)?.toDouble(),
    hasAudio: j['hasAudio'] as bool? ?? false,
    context: [
      for (final l in (j['context'] as List? ?? const []))
        if (l is Map) SkillReviewLine.fromJson(l.cast<String, dynamic>()),
    ],
  );

  final String id;
  final String node;
  final String? nameVi;
  final String? fromLevel;
  final String toLevel;
  final bool star;
  final bool firstSeen;

  /// proposed · confirmed · rejected
  final String status;
  final String? reason;
  final String? correctedNode;
  final String? correctedNameVi;
  final String? exercise;
  final double? atSec;
  final bool hasAudio;
  final List<SkillReviewLine> context;

  bool get isPending => status == 'proposed';
  bool get isConfirmed => status == 'confirmed';
  bool get isRejected => status == 'rejected';
  String get title => (nameVi ?? '').trim().isNotEmpty ? nameVi! : node;
}

class SkillNodeOption {
  const SkillNodeOption({
    required this.id,
    required this.grade,
    required this.nameVi,
  });

  factory SkillNodeOption.fromJson(Map<String, dynamic> j) => SkillNodeOption(
    id: j['id'] as String? ?? '',
    grade: (j['grade'] as num?)?.toInt() ?? 0,
    nameVi: j['nameVi'] as String? ?? '',
  );

  final String id;
  final int grade;
  final String nameVi;
}

List<T> parseReviewList<T>(
  Object? data,
  T Function(Map<String, dynamic>) fromJson,
) {
  final body = data is Map ? (data['content'] ?? data) : data;
  if (body is! List) return const [];
  return [
    for (final e in body)
      if (e is Map) fromJson(e.cast<String, dynamic>()),
  ];
}
