import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';
import 'package:tutora/core/constants/app_text_styles.dart';
import 'package:tutora/mock/student_notifications_mock.dart';

class StudentNotificationsScreen extends StatefulWidget {
  const StudentNotificationsScreen({super.key});

  @override
  State<StudentNotificationsScreen> createState() =>
      _StudentNotificationsScreenState();
}

class _StudentNotificationsScreenState extends State<StudentNotificationsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late List<MockNotification> _notis;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() => setState(() {}));
    _notis = List.of(kMockNotifications);
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

  List<MockNotification> get _unread => _notis.where((n) => !n.isRead).toList();

  @override
  Widget build(BuildContext context) {
    final hasUnread = _unread.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              hasUnread: hasUnread,
              onMarkAll: _markAllRead,
              onBack: () => context.pop(),
            ),
            _SegmentedTabs(controller: _tabs),
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

class _Header extends StatelessWidget {
  const _Header({
    required this.hasUnread,
    required this.onMarkAll,
    required this.onBack,
  });

  final bool hasUnread;
  final VoidCallback onMarkAll;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.ink),
            onPressed: onBack,
          ),
          Expanded(
            child: Text('Thông báo', style: AppTextStyles.h3()),
          ),
          if (hasUnread)
            GestureDetector(
              onTap: onMarkAll,
              child: Text(
                'Đánh dấu tất cả đã đọc',
                style: AppTextStyles.label(color: AppColors.oxblood),
              ),
            ),
        ],
      ),
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs({required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.cream2,
          borderRadius: BorderRadius.circular(10),
        ),
        child: TabBar(
          controller: controller,
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
          unselectedLabelStyle: AppTextStyles.label(color: AppColors.ink4),
          labelColor: AppColors.ink,
          unselectedLabelColor: AppColors.ink4,
          tabs: const [
            Tab(text: 'Tất cả'),
            Tab(text: 'Chưa đọc'),
          ],
        ),
      ),
    );
  }
}

class _NotiList extends StatelessWidget {
  const _NotiList({required this.items, required this.onTap});

  final List<MockNotification> items;
  final void Function(String id) onTap;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const _EmptyState();

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

  final MockNotification item;
  final VoidCallback onTap;

  Color get _iconBg => switch (item.type) {
    NotificationType.lesson => const Color(0xFFE8F0FE),
    NotificationType.review => const Color(0xFFFFF3E0),
    NotificationType.system => AppColors.cream2,
  };

  Color get _iconColor => switch (item.type) {
    NotificationType.lesson => const Color(0xFF3D6EEA),
    NotificationType.review => const Color(0xFFE07B00),
    NotificationType.system => AppColors.ink3,
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
                  Text(
                    item.time,
                    style: AppTextStyles.eyebrow(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
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
}
