/// Mô hình dữ liệu Topi v1 (kế hoạch trước buổi, gợi ý cho gia sư, kỹ năng).
///
/// Backend trả nguyên hình dạng của tutora-ai (snake_case), lọc theo cờ. Mọi
/// trường đều có thể thiếu hoặc null — parse khoan dung, không bao giờ ném lỗi
/// vì một trường lạ. Đọc cả khoá camelCase phòng khi backend đổi cách trả.
library;

Map<String, dynamic>? _map(Object? v) =>
    v is Map ? v.cast<String, dynamic>() : null;

List<Map<String, dynamic>> _list(Object? v) => v is List
    ? v.whereType<Map<dynamic, dynamic>>()
          .map((e) => e.cast<String, dynamic>())
          .toList()
    : const [];

/// Đọc khoá snake_case, rơi về camelCase.
Object? _get(Map<String, dynamic> j, String snake) {
  if (j.containsKey(snake)) return j[snake];
  final camel = snake.replaceAllMapped(
    RegExp('_([a-z])'),
    (m) => m.group(1)!.toUpperCase(),
  );
  return j[camel];
}

String? _str(Map<String, dynamic> j, String k) {
  final v = _get(j, k);
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}

int? _int(Map<String, dynamic> j, String k) {
  final v = _get(j, k);
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

bool _bool(Map<String, dynamic> j, String k) {
  final v = _get(j, k);
  if (v is bool) return v;
  if (v is String) return v.toLowerCase() == 'true';
  return false;
}

// ── Cờ ───────────────────────────────────────────────────────────────────────

/// `GET /recording/app/topi/flags` — mặc định tắt hết.
class TopiFlags {
  const TopiFlags({
    this.report = false,
    this.plan = false,
    this.tips = false,
    this.skills = false,
  });

  factory TopiFlags.fromJson(Map<String, dynamic> j) => TopiFlags(
    report: _bool(j, 'report'),
    plan: _bool(j, 'plan'),
    tips: _bool(j, 'tips'),
    skills: _bool(j, 'skills'),
  );

  static const off = TopiFlags();

  final bool report;
  final bool plan;
  final bool tips;
  final bool skills;

  bool get any => report || plan || tips || skills;
}

// ── Mức kỹ năng ──────────────────────────────────────────────────────────────

/// Bốn mức của bộ phát hiện kỹ năng, thứ tự từ thấp lên cao.
enum TopiLevel {
  toDo('to_do'),
  improving('improving'),
  standard('standard'),
  mastered('mastered');

  const TopiLevel(this.wire);

  final String wire;

  static TopiLevel? parse(String? v) {
    if (v == null) return null;
    final s = v.trim().toLowerCase().replaceAll('-', '_');
    for (final l in values) {
      if (l.wire == s || l.name.toLowerCase() == s.replaceAll('_', '')) {
        return l;
      }
    }
    return null;
  }
}

// ── Kế hoạch trước buổi (plan) ───────────────────────────────────────────────

class TopiGap {
  const TopiGap({
    required this.rank,
    this.node,
    this.title,
    this.wrong,
    this.right,
    this.role,
    this.seenInLessons,
    this.level,
  });

  factory TopiGap.fromJson(Map<String, dynamic> j, int index) => TopiGap(
    rank: _int(j, 'rank') ?? index + 1,
    node: _str(j, 'node'),
    title: _str(j, 'title'),
    wrong: _str(j, 'wrong'),
    right: _str(j, 'right'),
    role: _str(j, 'role'),
    seenInLessons: _int(j, 'seen_in_lessons'),
    level: TopiLevel.parse(_str(j, 'level')),
  );

  final int rank;
  final String? node;
  final String? title;
  final String? wrong;
  final String? right;

  /// focus | next | watch
  final String? role;
  final int? seenInLessons;

  /// Không có trong hợp đồng v1 — đọc nếu backend gắn thêm.
  final TopiLevel? level;
}

class TopiAsk {
  const TopiAsk({this.say, this.problem, this.answer, this.verified});

  factory TopiAsk.fromJson(Map<String, dynamic> j) => TopiAsk(
    say: _str(j, 'say'),
    problem: _str(j, 'problem'),
    answer: _str(j, 'answer'),
    verified: switch (_get(j, 'verified')) {
      final bool b => b,
      _ => null,
    },
  );

  final String? say;
  final String? problem;
  final String? answer;
  final bool? verified;

  bool get isEmpty => say == null && problem == null;
}

class TopiStep {
  const TopiStep({required this.name, this.minutes, this.asks = const []});

  factory TopiStep.fromJson(Map<String, dynamic> j) => TopiStep(
    name: (_str(j, 'name') ?? '').toLowerCase(),
    minutes: _int(j, 'minutes'),
    asks: _list(
      _get(j, 'asks'),
    ).map(TopiAsk.fromJson).where((a) => !a.isEmpty).toList(),
  );

  /// check | homework | memory | warmup
  final String name;
  final int? minutes;
  final List<TopiAsk> asks;
}

class TopiPlan {
  const TopiPlan({this.gaps = const [], this.steps = const []});

  factory TopiPlan.fromJson(Map<String, dynamic> j) {
    final gaps = _list(_get(j, 'gaps'));
    return TopiPlan(
      gaps: [for (var i = 0; i < gaps.length; i++) TopiGap.fromJson(gaps[i], i)]
        ..sort((a, b) => a.rank.compareTo(b.rank)),
      steps: _list(_get(j, 'steps')).map(TopiStep.fromJson).toList(),
    );
  }

  final List<TopiGap> gaps;
  final List<TopiStep> steps;

  bool get isEmpty => gaps.isEmpty && steps.isEmpty;
}

// ── Gợi ý cho gia sư (tips) ──────────────────────────────────────────────────

class TopiTip {
  const TopiTip({required this.text, this.seg, this.quote});

  final String text;
  final int? seg;
  final String? quote;

  static TopiTip? fromJson(Object? v) {
    final j = _map(v);
    if (j == null) return null;
    final text = _str(j, 'text');
    if (text == null) return null;
    return TopiTip(text: text, seg: _int(j, 'seg'), quote: _str(j, 'quote'));
  }
}

class TopiTips {
  const TopiTips({this.didWell, this.tryNext, this.talkMore});

  factory TopiTips.fromJson(Map<String, dynamic> j) => TopiTips(
    didWell: TopiTip.fromJson(_get(j, 'did_well')),
    tryNext: TopiTip.fromJson(_get(j, 'try_next')),
    talkMore: TopiTip.fromJson(_get(j, 'talk_more')),
  );

  final TopiTip? didWell;
  final TopiTip? tryNext;
  final TopiTip? talkMore;

  bool get isEmpty => didWell == null && tryNext == null && talkMore == null;
}

// ── Kỹ năng (skills) ─────────────────────────────────────────────────────────

class TopiSkillChange {
  const TopiSkillChange({
    required this.node,
    this.from,
    this.to,
    this.star = false,
  });

  factory TopiSkillChange.fromJson(Map<String, dynamic> j) => TopiSkillChange(
    node: _str(j, 'node') ?? '',
    from: TopiLevel.parse(_str(j, 'from')),
    to: TopiLevel.parse(_str(j, 'to')),
    star: _bool(j, 'star'),
  );

  final String node;
  final TopiLevel? from;
  final TopiLevel? to;
  final bool star;
}

class TopiFirstSeen {
  const TopiFirstSeen({required this.node, this.level});

  factory TopiFirstSeen.fromJson(Map<String, dynamic> j) => TopiFirstSeen(
    node: _str(j, 'node') ?? '',
    level: TopiLevel.parse(_str(j, 'level')),
  );

  final String node;
  final TopiLevel? level;
}

/// Một kỹ năng tìm thấy trong buổi, với mức hiện tại và số sao lên mức.
class TopiSkillItem {
  const TopiSkillItem({
    required this.node,
    required this.level,
    this.name,
    this.stars = 0,
  });

  final String node;
  final String? name;
  final TopiLevel level;
  final int stars;
}

class TopiSkills {
  const TopiSkills({
    this.proposedChanges = const [],
    this.firstSeen = const [],
    this.observedNodes = const [],
    this.names = const {},
  });

  factory TopiSkills.fromJson(Map<String, dynamic> j) {
    final names = <String, String>{};
    final observed = <String>[];
    for (final o in _list(_get(j, 'observations'))) {
      final node = _str(o, 'node');
      if (node == null) continue;
      if (!observed.contains(node)) observed.add(node);
      final name = _str(o, 'name_vi') ?? _str(o, 'name');
      if (name != null) names[node] = name;
    }
    final changes = _list(
      _get(j, 'proposed_changes'),
    ).map(TopiSkillChange.fromJson).where((c) => c.node.isNotEmpty).toList();
    final first = _list(
      _get(j, 'first_seen'),
    ).map(TopiFirstSeen.fromJson).where((f) => f.node.isNotEmpty).toList();
    for (final m in [
      ..._list(_get(j, 'proposed_changes')),
      ..._list(_get(j, 'first_seen')),
    ]) {
      final node = _str(m, 'node');
      final name = _str(m, 'name_vi') ?? _str(m, 'name');
      if (node != null && name != null) names[node] = name;
    }
    return TopiSkills(
      proposedChanges: changes,
      firstSeen: first,
      observedNodes: observed,
      names: names,
    );
  }

  final List<TopiSkillChange> proposedChanges;
  final List<TopiFirstSeen> firstSeen;
  final List<String> observedNodes;
  final Map<String, String> names;

  /// Kỹ năng có mức biết được: lần đầu thấy (không sao) và đổi mức (một sao
  /// mỗi bậc lên). Kỹ năng chỉ có quan sát mà chưa có mức thì bỏ qua.
  List<TopiSkillItem> get items {
    final level = <String, TopiLevel>{};
    final stars = <String, int>{};
    for (final f in firstSeen) {
      if (f.level != null) level[f.node] = f.level!;
    }
    for (final c in proposedChanges) {
      if (c.to != null) level[c.node] = c.to!;
      if (c.star) stars[c.node] = (stars[c.node] ?? 0) + 1;
    }
    return [
      for (final e in level.entries)
        TopiSkillItem(
          node: e.key,
          name: names[e.key],
          level: e.value,
          stars: stars[e.key] ?? 0,
        ),
    ]..sort((a, b) => a.node.compareTo(b.node));
  }
}

// ── Kết quả Topi của một buổi ────────────────────────────────────────────────

/// `GET /recording/app/{lessonId}/topi` — chỉ có các phần đang bật cờ; phần
/// tắt hoặc lỗi là null.
class LessonTopi {
  const LessonTopi({this.lessonId, this.plan, this.tips, this.skills});

  factory LessonTopi.fromJson(Map<String, dynamic> j) {
    final plan = _map(_get(j, 'plan'));
    final tips = _map(_get(j, 'tips'));
    final skills = _map(_get(j, 'skills'));
    return LessonTopi(
      lessonId: _str(j, 'lesson_id'),
      plan: plan == null ? null : TopiPlan.fromJson(plan),
      tips: tips == null ? null : TopiTips.fromJson(tips),
      skills: skills == null ? null : TopiSkills.fromJson(skills),
    );
  }

  final String? lessonId;
  final TopiPlan? plan;
  final TopiTips? tips;
  final TopiSkills? skills;
}
