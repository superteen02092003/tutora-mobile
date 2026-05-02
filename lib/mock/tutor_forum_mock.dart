enum MockPostType { question, discussion }

class MockForumPost {
  const MockForumPost({
    required this.authorName,
    required this.authorRole,
    required this.title,
    required this.preview,
    required this.category,
    required this.timeAgo,
    required this.likes,
    required this.comments,
    this.type = MockPostType.discussion,
    this.rewardPoints,
    this.isPinned = false,
  });

  final String authorName;
  final String authorRole;
  final String title;
  final String preview;
  final String category;
  final String timeAgo;
  final int likes;
  final int comments;
  final MockPostType type;
  final int? rewardPoints;
  final bool isPinned;

  bool get isQuestion => type == MockPostType.question;
}

class MockForumComment {
  const MockForumComment({
    required this.authorName,
    required this.authorRole,
    required this.content,
    required this.timeAgo,
    required this.likes,
  });

  final String authorName;
  final String authorRole;
  final String content;
  final String timeAgo;
  final int likes;
}

// ── Forum categories ─────────────────────────────────────────────────────

const kForumCategories = [
  'Tất cả',
  'Câu hỏi HS',
  'Phương pháp',
  'Tài liệu',
  'Hỏi đáp',
  'Chia sẻ',
];

// ── Pinned post ──────────────────────────────────────────────────────────

const kPinnedPost = MockForumPost(
  authorName: 'Cô Minh Thư',
  authorRole: 'Toán · 10 năm kinh nghiệm',
  title: 'Cách giải thích Vi-ét để học sinh lớp 10 không bị nhầm dấu',
  preview:
      'Mình thường vẽ bảng xét dấu ngay trước khi vào công thức, giúp học sinh hình dung trực quan hơn so với học thuộc lòng...',
  category: 'Phương pháp',
  timeAgo: '2 giờ trước',
  likes: 48,
  comments: 17,
  isPinned: true,
);

// ── Forum posts ──────────────────────────────────────────────────────────

const kForumPosts = [
  MockForumPost(
    authorName: 'Minh Khôi',
    authorRole: 'Học sinh · Lớp 10 · Cánh Diều',
    title: 'Chứng minh bất đẳng thức Cauchy-Schwarz trong tam giác?',
    preview:
        'Cho tam giác ABC, chứng minh rằng a/(b+c) + b/(a+c) + c/(a+b) ≥ 3/2. Mình không biết bắt đầu từ đâu...',
    category: 'Câu hỏi HS',
    timeAgo: '30 phút trước',
    likes: 0,
    comments: 2,
    type: MockPostType.question,
    rewardPoints: 50,
  ),
  MockForumPost(
    authorName: 'Thầy Quốc Bảo',
    authorRole: 'Vật Lý · 6 năm kinh nghiệm',
    title: 'Tài liệu tóm tắt Động lực học Newton — in sẵn cho buổi ôn thi',
    preview:
        'Bộ tài liệu 4 trang tự tổng hợp, đủ 3 định luật và bài tập cơ bản theo mức độ từ nhận biết đến vận dụng cao...',
    category: 'Tài liệu',
    timeAgo: '4 giờ trước',
    likes: 31,
    comments: 9,
  ),
  MockForumPost(
    authorName: 'Bảo Châu',
    authorRole: 'Học sinh · Lớp 11 · Kết nối',
    title: 'Vật lý 11: Cách phân biệt điện trường đều và không đều?',
    preview:
        'Bài thầy cô dạy mình hiểu điện trường đều rồi nhưng khi nào có điện trường không đều thì mình vẫn bị nhầm...',
    category: 'Câu hỏi HS',
    timeAgo: '1 giờ trước',
    likes: 0,
    comments: 0,
    type: MockPostType.question,
    rewardPoints: 35,
  ),
  MockForumPost(
    authorName: 'Cô Lan Anh',
    authorRole: 'Ngữ Văn · 5 năm kinh nghiệm',
    title: 'Hỏi: Xử lý thế nào khi học sinh không chịu đọc văn bản?',
    preview:
        'Mình có một học sinh lớp 9 rất giỏi nhưng cứ nhìn vào đề văn là bỏ cuộc. Đã thử giao đoạn ngắn hơn nhưng vẫn chưa ổn...',
    category: 'Hỏi đáp',
    timeAgo: '1 ngày trước',
    likes: 22,
    comments: 34,
  ),
  MockForumPost(
    authorName: 'Thầy Đức Minh',
    authorRole: 'Hoá · 4 năm kinh nghiệm',
    title: 'Lần đầu dạy trực tuyến — kinh nghiệm sau 3 tháng từ số 0',
    preview:
        'Chia sẻ thật lòng: tháng đầu mình cứ nhìn vào camera thay vì nhìn học sinh. Sau đây là vài điều mình học được...',
    category: 'Chia sẻ',
    timeAgo: '2 ngày trước',
    likes: 67,
    comments: 21,
  ),
  MockForumPost(
    authorName: 'Cô Thu Hằng',
    authorRole: 'Toán · 8 năm kinh nghiệm',
    title: 'Bộ câu hỏi kiểm tra nhanh 5 phút đầu giờ — hiệu quả bất ngờ',
    preview:
        'Thay vì hỏi "Bài hôm qua có câu hỏi không?", mình dùng 3 câu trắc nghiệm nhanh để kiểm tra đầu vào mỗi buổi...',
    category: 'Phương pháp',
    timeAgo: '3 ngày trước',
    likes: 41,
    comments: 13,
  ),
  MockForumPost(
    authorName: 'Thầy Huy Khang',
    authorRole: 'Lý · 7 năm kinh nghiệm',
    title: 'SGK mới 2025 thay đổi gì? — So sánh nhanh chương Sóng cơ',
    preview:
        'Chương Sóng cơ trong bộ Kết nối có thay đổi thứ tự so với Cánh Diều, cụ thể ở phần giao thoa...',
    category: 'Tài liệu',
    timeAgo: '4 ngày trước',
    likes: 55,
    comments: 28,
  ),
];

// ── Forum comments ───────────────────────────────────────────────────────

const kMockForumComments = [
  MockForumComment(
    authorName: 'Thầy Huy Khang',
    authorRole: 'Lý · 7 năm',
    content:
        'Mình cũng gặp vấn đề này. Cách hiệu quả nhất mình thấy là cho học sinh đọc to và gạch chân từ khoá trước. Giúp các em tập trung hơn nhiều so với đọc thầm.',
    timeAgo: '45 phút trước',
    likes: 12,
  ),
  MockForumComment(
    authorName: 'Cô Thu Hằng',
    authorRole: 'Toán · 8 năm',
    content:
        'Thử chia văn bản thành từng đoạn 4–5 câu rồi đặt câu hỏi sau mỗi đoạn. Học sinh sẽ có động lực đọc vì biết sẽ cần trả lời ngay.',
    timeAgo: '1 giờ trước',
    likes: 8,
  ),
  MockForumComment(
    authorName: 'Thầy Đức Minh',
    authorRole: 'Hoá · 4 năm',
    content:
        'Đôi khi chỉ cần thay văn bản dài bằng infographic tóm tắt để tạo hứng khởi ban đầu. Sau đó mới quay lại bản gốc.',
    timeAgo: '2 giờ trước',
    likes: 5,
  ),
];
