/// Đánh giá phụ huynh dành cho gia sư.
///
/// Backend: `GET /api/tutors/me/feedbacks` trả `PagedList<FeedbackListResponse>`
/// — kế thừa `List<T>` nên `content` là **mảng JSON** (giống `/tutor/disputes`,
/// khác `/tutors/bookings` vốn trả object có `items`).
library;

class TutorFeedbackDto {
  const TutorFeedbackDto({
    required this.feedbackId,
    required this.rating,
    required this.comment,
    required this.parentName,
    required this.parentAvatarUrl,
    required this.subjectName,
    required this.reply,
    required this.repliedAt,
    required this.createdAt,
  });

  factory TutorFeedbackDto.fromJson(Map<String, dynamic> j) => TutorFeedbackDto(
    feedbackId: j['feedbackId'] as int? ?? 0,
    rating: j['rating'] as int? ?? 0,
    comment: j['comment'] as String? ?? '',
    parentName:
        j['parentName'] as String? ??
        j['fromUserName'] as String? ??
        'Phụ huynh',
    parentAvatarUrl:
        j['parentAvatarUrl'] as String? ?? j['fromUserAvatarUrl'] as String?,
    subjectName: j['subjectName'] as String? ?? '',
    reply: j['reply'] as String? ?? j['replyComment'] as String?,
    repliedAt: DateTime.tryParse(j['repliedAt'] as String? ?? ''),
    createdAt: DateTime.tryParse(j['createdAt'] as String? ?? ''),
  );

  final int feedbackId;
  final int rating;
  final String comment;
  final String parentName;
  final String? parentAvatarUrl;
  final String subjectName;

  /// Phản hồi của gia sư — hiện chỉ trả lời được trên web.
  final String? reply;
  final DateTime? repliedAt;
  final DateTime? createdAt;

  bool get hasReply => reply != null && reply!.trim().isNotEmpty;
}

/// Thống kê đánh giá gộp từ danh sách — backend không có endpoint riêng cho
/// gia sư tự xem, nên tính tại client từ trang đã tải.
class TutorFeedbackStats {
  const TutorFeedbackStats({
    required this.average,
    required this.total,
    required this.starCounts,
  });

  factory TutorFeedbackStats.from(List<TutorFeedbackDto> items) {
    if (items.isEmpty) {
      return const TutorFeedbackStats(
        average: 0,
        total: 0,
        starCounts: {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
      );
    }

    final counts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    var sum = 0;
    for (final f in items) {
      sum += f.rating;
      counts[f.rating] = (counts[f.rating] ?? 0) + 1;
    }
    return TutorFeedbackStats(
      average: sum / items.length,
      total: items.length,
      starCounts: counts,
    );
  }

  final double average;
  final int total;

  /// Số lượt theo từng mức sao (5 → 1).
  final Map<int, int> starCounts;

  double ratioOf(int star) => total == 0 ? 0 : (starCounts[star] ?? 0) / total;
}
