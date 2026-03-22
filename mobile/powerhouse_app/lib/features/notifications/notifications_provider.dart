import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_service.dart';

class NotificationModel {
  final String id;
  final String? userId;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      userId: json['user_id'],
      type: json['type'],
      title: json['title'],
      message: json['message'] ?? '',
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class NotificationsNotifier extends StateNotifier<AsyncValue<List<NotificationModel>>> {
  NotificationsNotifier() : super(const AsyncValue.loading()) {
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    try {
      final res = await ApiService.get('/notifications');
      if (res['success'] == true) {
        final List<dynamic> data = res['data'];
        state = AsyncValue.data(data.map((e) => NotificationModel.fromJson(e)).toList());
      } else {
        state = AsyncValue.error(res['message'] ?? 'Failed to load', StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      final res = await ApiService.put('/notifications/$id/read', {});
      if (res['success'] == true) {
        state.whenData((list) {
          state = AsyncValue.data(list.map((n) => n.id == id ? NotificationModel(
            id: n.id,
            userId: n.userId,
            type: n.type,
            title: n.title,
            message: n.message,
            isRead: true,
            createdAt: n.createdAt,
          ) : n).toList());
        });
      }
    } catch (_) {}
  }
  
  int get unreadCount {
    return state.maybeWhen(
      data: (list) => list.where((n) => !n.isRead).length,
      orElse: () => 0,
    );
  }
}

final notificationsProvider = StateNotifierProvider<NotificationsNotifier, AsyncValue<List<NotificationModel>>>((ref) {
  return NotificationsNotifier();
});
