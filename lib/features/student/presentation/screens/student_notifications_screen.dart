import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';
import 'package:tutora/core/constants/app_text_styles.dart';
import 'package:tutora/shared/models/notification_models.dart';
import 'package:tutora/shared/providers/notification_provider.dart';

class StudentNotificationsScreen extends ConsumerStatefulWidget {
  const StudentNotificationsScreen({super.key});

  @override
  ConsumerState<StudentNotificationsScreen> createState() =>
      _StudentNotificationsScreenState();
}

class _StudentNotificationsScreenState
    extends ConsumerState<StudentNotificationsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() => setState(() {}));
    unawaited(
      Future.microtask(() => ref.read(notificationProvider.notifier).load()),
    );
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationProvider);
    final hasUnread = state.unreadCount > 0;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              hasUnread: hasUnread,
              onMarkAll: () =>
                  ref.read(notificationProvider.notifier).markAllRead(),
              onBack: () => context.pop(),
            ),
            _SegmentedTabs(controller: _tabs),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: state.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.oxblood,
                      ),
                    )
                  : state.error != null
                  ? _ErrorState(
                      onRetry: () =>
                          ref.read(notificationProvider.notifier).load(),
                    )
                  : TabBarView(
                      controller: _tabs,
                      children: [
                        _NotiList(
                          items: state.items,
                          onTap: (id) => ref
                              .read(notificationProvider.notifier)
                              .markRead(id),
                        ),
                        _NotiList(
                          items: state.unread,
                          onTap: (id) => ref
                              .read(notificationProvider.notifier)
                              .markRead(id),
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

  final List<NotificationDto> items;
  final void Function(int id) onTap;

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

  final NotificationDto item;
  final VoidCallback onTap;

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
                    color: item.iconBg,
                  ),
                  child: Icon(item.icon, size: 20, color: item.iconColor),
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
                    item.message,
                    style: AppTextStyles.bodySmall(color: AppColors.ink4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(item.timeAgo, style: AppTextStyles.eyebrow()),
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

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_outlined, size: 48, color: AppColors.ink4),
          const SizedBox(height: 12),
          Text(
            'Không tải được thông báo',
            style: AppTextStyles.body(color: AppColors.ink3),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onRetry,
            child: Text(
              'Thử lại',
              style: AppTextStyles.label(color: AppColors.oxblood),
            ),
          ),
        ],
      ),
    );
  }
}
