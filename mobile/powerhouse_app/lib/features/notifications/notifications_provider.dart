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

class NotificationsNotifier extends AsyncNotifier<List<NotificationModel>> {
  @override
  Future<List<NotificationModel>> build() async {
    return _fetch();
  }

  Future<List<NotificationModel>> _fetch() async {
    final res = await ApiService.get('/notifications');
    if (res['success'] == true) {
      final List<dynamic> data = res['data'];
      return data.map((e) => NotificationModel.fromJson(e)).toList();
    }
    throw Exception(res['message'] ?? 'Failed to load');
  }

  Future<void> fetchNotifications() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetch());
  }

  Future<void> markAsRead(String id) async {
    try {
      final res = await ApiService.put('/notifications/$id/read', {});
      if (res['success'] == true) {
        state = state.whenData((list) {
          return list.map((n) => n.id == id ? NotificationModel(
            id: n.id,
            userId: n.userId,
            type: n.type,
            title: n.title,
            message: n.message,
            isRead: true,
            createdAt: n.createdAt,
          ) : n).toList();
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

final notificationsProvider = AsyncNotifierProvider<NotificationsNotifier, List<NotificationModel>>(() {
  return NotificationsNotifier();
});
