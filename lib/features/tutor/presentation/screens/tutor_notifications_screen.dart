import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/core/theme/tutor_design.dart';
import 'package:tutora/features/tutor/presentation/widgets/canvas_ui.dart';
import 'package:tutora/shared/models/notification_models.dart';
import 'package:tutora/shared/providers/notification_provider.dart';
import 'package:tutora/shared/services/fcm_notification_handler.dart';

/// Thông báo (design V5.6): nút tròn quay lại, tab gạch chân, hàng kẻ mảnh,
/// ô biểu tượng lõm màu mực, chấm chưa đọc màu rêu.
class TutorNotificationsScreen extends ConsumerStatefulWidget {
  const TutorNotificationsScreen({super.key});

  @override
  ConsumerState<TutorNotificationsScreen> createState() =>
      _TutorNotificationsScreenState();
}

class _TutorNotificationsScreenState
    extends ConsumerState<TutorNotificationsScreen>
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

  /// Đánh dấu đã đọc; thông báo nhắc buổi học mở luồng ghi âm.
  void _open(NotificationDto item) {
    unawaited(ref.read(notificationProvider.notifier).markRead(item.id));
    if (item.type == recorderLessonReminderType) {
      openRecorderForReminder(GoRouter.of(context));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationProvider);
    final hasUnread = state.unreadCount > 0;

    return Scaffold(
      backgroundColor: TutorColors.bg,
      body: DecoratedBox(
        decoration: TutorSurface.paper,
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CanvasHeader(
                title: 'Thông báo',
                titleSize: 24,
                onBack: () => Navigator.of(context).pop(),
                trailing: hasUnread
                    ? CanvasCircleButton(
                        tooltip: 'Đánh dấu tất cả đã đọc',
                        onTap: () => ref
                            .read(notificationProvider.notifier)
                            .markAllRead(),
                        child: const Icon(
                          Icons.done_all_rounded,
                          size: 20,
                          color: TutorColors.ink,
                        ),
                      )
                    : null,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  TutorSurface.gutter,
                  16,
                  TutorSurface.gutter,
                  0,
                ),
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0x141F2A24)),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabs,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    padding: EdgeInsets.zero,
                    labelPadding: const EdgeInsets.only(right: 22),
                    indicatorColor: TutorColors.ink,
                    indicatorSize: TabBarIndicatorSize.label,
                    dividerColor: Colors.transparent,
                    labelStyle: TutorType.action(),
                    unselectedLabelStyle: TutorType.action(
                      color: const Color(0xFF8A8F89),
                    ),
                    labelColor: TutorColors.ink,
                    unselectedLabelColor: const Color(0xFF8A8F89),
                    overlayColor: const WidgetStatePropertyAll(
                      Colors.transparent,
                    ),
                    tabs: const [
                      Tab(text: 'Tất cả', height: 40),
                      Tab(text: 'Chưa đọc', height: 40),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: state.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: TutorColors.primary,
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
                          _NotiList(items: state.items, onTap: _open),
                          _NotiList(items: state.unread, onTap: _open),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotiList extends StatelessWidget {
  const _NotiList({required this.items, required this.onTap});

  final List<NotificationDto> items;
  final void Function(NotificationDto item) onTap;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: TutorSurface.screenPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Không có thông báo', style: TutorType.sectionTitle()),
              const SizedBox(height: 14),
              const CanvasHand('Bạn đã đọc hết rồi!', size: 18),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        TutorSurface.gutter,
        4,
        TutorSurface.gutter,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => _NotiTile(
        item: items[i],
        first: i == 0,
        onTap: () => onTap(items[i]),
      ),
    );
  }
}

class _NotiTile extends StatelessWidget {
  const _NotiTile({
    required this.item,
    required this.first,
    required this.onTap,
  });

  final NotificationDto item;
  final bool first;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          border: Border(top: first ? BorderSide.none : TutorSurface.rule),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: item.isRead
                  ? TutorSurface.well()
                  : BoxDecoration(
                      color: TutorColors.sage,
                      borderRadius: BorderRadius.circular(
                        TutorSurface.radiusSmall,
                      ),
                    ),
              child: Icon(item.icon, size: 18, color: TutorColors.ink),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TutorType.body(
                      color: item.isRead ? TutorColors.ink3 : TutorColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.message,
                    style: TutorType.rowSub(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(item.timeAgo, style: TutorType.caption()),
                ],
              ),
            ),
            if (!item.isRead)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 8),
                child: Semantics(
                  label: 'Chưa đọc',
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: TutorColors.ink,
                    ),
                  ),
                ),
              ),
          ],
        ),
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
      child: Padding(
        padding: TutorSurface.screenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_outlined,
              size: 36,
              color: TutorColors.ink3,
            ),
            const SizedBox(height: 12),
            Text(
              'Không tải được thông báo',
              style: TutorType.body(color: TutorColors.ink3),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: 160,
              child: CanvasCta(
                label: 'Thử lại',
                secondary: true,
                onPressed: onRetry,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
