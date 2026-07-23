import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/shared/datasources/notification_datasource.dart';
import 'package:tutora/shared/models/notification_models.dart';

class NotificationState {
  const NotificationState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  final List<NotificationDto> items;
  final bool isLoading;
  final String? error;

  List<NotificationDto> get unread => items.where((n) => !n.isRead).toList();
  int get unreadCount => unread.length;

  NotificationState copyWith({
    List<NotificationDto>? items,
    bool? isLoading,
    String? error,
  }) => NotificationState(
    items: items ?? this.items,
    isLoading: isLoading ?? this.isLoading,
    error: error,
  );
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  NotificationNotifier(this._ds, this._ref) : super(const NotificationState());

  final NotificationDatasource _ds;
  final Ref _ref;

  /// Đồng bộ badge sau khi trạng thái đọc thay đổi.
  void _refreshBadge() => _ref.invalidate(unreadCountProvider);

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final items = await _ds.getMyNotifications();
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> markRead(int id) async {
    final idx = state.items.indexWhere((n) => n.id == id);
    if (idx == -1 || state.items[idx].isRead) return;

    // Optimistic update
    final updated = List<NotificationDto>.of(state.items);
    updated[idx] = updated[idx].copyWith(isRead: true);
    state = state.copyWith(items: updated);

    try {
      await _ds.markAsRead(id);
      _refreshBadge();
    } catch (_) {
      // Revert on failure
      updated[idx] = updated[idx].copyWith(isRead: false);
      state = state.copyWith(items: List.of(updated));
    }
  }

  Future<void> markAllRead() async {
    if (state.unreadCount == 0) return;

    // Optimistic update
    final updated = state.items.map((n) => n.copyWith(isRead: true)).toList();
    state = state.copyWith(items: updated);

    try {
      await _ds.markAllAsRead();
      _refreshBadge();
    } catch (_) {
      await load();
    }
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
      return NotificationNotifier(
        ref.read(notificationDatasourceProvider),
        ref,
      );
    });

/// Số thông báo chưa đọc — dùng cho badge chấm đỏ trên icon chuông.
final AutoDisposeFutureProvider<int> unreadCountProvider =
    FutureProvider.autoDispose<int>((ref) async {
      return ref.read(notificationDatasourceProvider).getUnreadCount();
    });
