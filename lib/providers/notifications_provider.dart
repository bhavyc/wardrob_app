import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../models/notification_model.dart';
import 'auth_provider.dart';

class NotificationsState {
  final List<NotificationModel> notifications;
  final int unreadCount;
  final bool isLoading;
  final String? error;

  NotificationsState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.error,
  });

  NotificationsState copyWith({
    List<NotificationModel>? notifications,
    int? unreadCount,
    bool? isLoading,
    String? error,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  final client = ref.watch(apiClientProvider);
  final auth = ref.watch(authProvider);
  return NotificationsNotifier(client, auth.isAuthenticated);
});

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final ApiClient _client;
  final bool _isAuthenticated;

  NotificationsNotifier(this._client, this._isAuthenticated)
      : super(NotificationsState()) {
    if (_isAuthenticated) {
      fetchNotifications();
    }
  }

  Future<void> fetchNotifications() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _client.dio.get('/notifications');
      if (res.statusCode == 200 && res.data['success'] == true) {
        final list = (res.data['notifications'] as List? ?? [])
            .map((n) => NotificationModel.fromJson(n as Map<String, dynamic>))
            .toList();
        final unread = res.data['unreadCount'] as int? ?? 0;
        state = state.copyWith(
          notifications: list,
          unreadCount: unread,
          isLoading: false,
        );
        return;
      }
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      // Optimistic update
      final updated = state.notifications.map((n) {
        if (n.id == id) return n.copyWith(isRead: true);
        return n;
      }).toList();
      final newUnread = (state.unreadCount - 1).clamp(0, double.infinity).toInt();
      state = state.copyWith(notifications: updated, unreadCount: newUnread);

      await _client.dio.patch('/notifications', data: {'id': id});
    } catch (e) {
      // Fallback
      fetchNotifications();
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final updated = state.notifications.map((n) => n.copyWith(isRead: true)).toList();
      state = state.copyWith(notifications: updated, unreadCount: 0);

      await _client.dio.patch('/notifications', data: {'all': true});
    } catch (e) {
      fetchNotifications();
    }
  }
}
