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
  NotificationNotifier(this._ds) : super(const NotificationState());

  final NotificationDatasource _ds;

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
    } catch (_) {
      await load();
    }
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
      return NotificationNotifier(ref.read(notificationDatasourceProvider));
    });
