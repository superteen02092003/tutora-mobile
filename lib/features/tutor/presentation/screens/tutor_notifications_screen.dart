import 'package:flutter/material.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';
import 'package:tutora/core/constants/app_text_styles.dart';

// Mock data
enum _NotiType { booking, lesson, payment, system }

class _Noti {
  const _Noti({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.time,
    this.isRead = false,
  });

  final String id;
  final _NotiType type;
  final String title;
  final String body;
  final String time;
  final bool isRead;

  IconData get icon => switch (type) {
    _NotiType.booking => Icons.event_available_outlined,
    _NotiType.lesson => Icons.menu_book_outlined,
    _NotiType.payment => Icons.payments_outlined,
    _NotiType.system => Icons.info_outline,
  };

  _Noti copyWith({bool? isRead}) => _Noti(
    id: id,
    type: type,
    title: title,
    body: body,
    time: time,
    isRead: isRead ?? this.isRead,
  );
}

final _kMock = <_Noti>[
  const _Noti(
    id: 'n1',
    type: _NotiType.booking,
    title: 'Yêu cầu đặt lịch mới',
    body: 'Phụ huynh Nguyễn Thị Lan muốn đặt lịch học Toán 10 — 3 buổi/tuần.',
    time: '5p trước',
  ),
  const _Noti(
    id: 'n2',
    type: _NotiType.payment,
    title: 'Tiền được giải ngân',
    body: 'Buổi học với Minh Anh ngày 7/5 đã hoàn thành. 180.000 ₫ đã vào ví.',
    time: '1 giờ trước',
  ),
  const _Noti(
    id: 'n3',
    type: _NotiType.lesson,
    title: 'Nhắc buổi học sắp tới',
    body: 'Buổi học Vật Lý 11 với Đức Khang sẽ bắt đầu lúc 19:00 hôm nay.',
    time: '3 giờ trước',
    isRead: true,
  ),
  const _Noti(
    id: 'n4',
    type: _NotiType.booking,
    title: 'Booking sắp hết hạn',
    body: 'Yêu cầu từ phụ huynh Trần Văn Bình sẽ hết hạn sau 12 giờ nữa.',
    time: 'Hôm qua',
    isRead: true,
  ),
  const _Noti(
    id: 'n5',
    type: _NotiType.lesson,
    title: 'Học sinh vắng mặt',
    body: 'Bảo Trân chưa check-in buổi học Toán 11 lúc 17:00 ngày 6/5.',
    time: '6/5',
    isRead: true,
  ),
  const _Noti(
    id: 'n6',
    type: _NotiType.system,
    title: 'Hồ sơ đã được duyệt',
    body: 'Chúc mừng! Hồ sơ gia sư của bạn đã được admin xác minh thành công.',
    time: '2/5',
    isRead: true,
  ),
];

class TutorNotificationsScreen extends StatefulWidget {
  const TutorNotificationsScreen({super.key});

  @override
  State<TutorNotificationsScreen> createState() =>
      _TutorNotificationsScreenState();
}

class _TutorNotificationsScreenState extends State<TutorNotificationsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late List<_Noti> _notis;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() => setState(() {}));
    _notis = List.of(_kMock);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _markRead(String id) {
    setState(() {
      final i = _notis.indexWhere((n) => n.id == id);
      if (i != -1) _notis[i] = _notis[i].copyWith(isRead: true);
    });
  }

  void _markAllRead() {
    setState(() {
      _notis = _notis.map((n) => n.copyWith(isRead: true)).toList();
    });
  }

  List<_Noti> get _unread => _notis.where((n) => !n.isRead).toList();

  @override
  Widget build(BuildContext context) {
    final hasUnread = _unread.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 16, 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                      color: AppColors.ink,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text('Thông báo', style: AppTextStyles.h3()),
                  ),
                  if (hasUnread)
                    GestureDetector(
                      onTap: _markAllRead,
                      child: Text(
                        'Đánh dấu tất cả đã đọc',
                        style: AppTextStyles.label(color: AppColors.oxblood),
                      ),
                    ),
                ],
              ),
            ),
            // Segmented tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.cream2,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TabBar(
                  controller: _tabs,
                  indicator: BoxDecoration(
                    color: AppColors.paper,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.ink.withValues(alpha: 0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorPadding: const EdgeInsets.all(3),
                  dividerColor: Colors.transparent,
                  labelStyle: AppTextStyles.label(),
                  unselectedLabelStyle: AppTextStyles.label(
                    color: AppColors.ink4,
                  ),
                  labelColor: AppColors.ink,
                  unselectedLabelColor: AppColors.ink4,
                  tabs: const [
                    Tab(text: 'Tất cả'),
                    Tab(text: 'Chưa đọc'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _NotiList(items: _notis, onTap: _markRead),
                  _NotiList(items: _unread, onTap: _markRead),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotiList extends StatelessWidget {
  const _NotiList({required this.items, required this.onTap});

  final List<_Noti> items;
  final void Function(String id) onTap;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/common/empty_notification.png',
              width: 180,
            ),
            const SizedBox(height: 16),
            Text('Không có thông báo', style: AppTextStyles.h3()),
            const SizedBox(height: 6),
            Text(
              'Bạn đã đọc hết rồi!',
              style: AppTextStyles.bodySmall(color: AppColors.ink4),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      itemCount: items.length,
      separatorBuilder: (_, _) => const Divider(
        height: 1,
        color: AppColors.line,
        indent: 52,
      ),
      itemBuilder: (_, i) => _NotiTile(
        item: items[i],
        onTap: () => onTap(items[i].id),
      ),
    );
  }
}

class _NotiTile extends StatelessWidget {
  const _NotiTile({required this.item, required this.onTap});

  final _Noti item;
  final VoidCallback onTap;

  Color get _iconBg => switch (item.type) {
    _NotiType.booking => const Color(0xFFE8F0FE),
    _NotiType.lesson => const Color(0xFFD5EDD9),
    _NotiType.payment => const Color(0xFFFFF3CD),
    _NotiType.system => AppColors.cream2,
  };

  Color get _iconColor => switch (item.type) {
    _NotiType.booking => const Color(0xFF3D6EEA),
    _NotiType.lesson => AppColors.moss,
    _NotiType.payment => const Color(0xFF7A5900),
    _NotiType.system => AppColors.ink3,
  };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _iconBg,
                  ),
                  child: Icon(item.icon, size: 20, color: _iconColor),
                ),
                if (!item.isRead)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.oxblood,
                        border: Border.all(color: AppColors.cream),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: item.isRead
                        ? AppTextStyles.label(color: AppColors.ink3)
                        : AppTextStyles.label(),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.body,
                    style: AppTextStyles.bodySmall(color: AppColors.ink4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(item.time, style: AppTextStyles.eyebrow()),
                ],
              ),
            ),
            if (!item.isRead)
              Padding(
                padding: const EdgeInsets.only(top: 2, left: 8),
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.oxblood,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
