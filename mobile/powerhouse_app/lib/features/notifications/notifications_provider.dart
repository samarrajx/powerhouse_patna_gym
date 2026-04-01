import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/auth_provider.dart';
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

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      userId: userId,
      type: type,
      title: title,
      message: message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json, {bool localIsRead = false}) {
    return NotificationModel(
      id: json['id'],
      userId: json['user_id'],
      type: json['type'],
      title: json['title'],
      message: json['message'] ?? '',
      isRead: localIsRead || (json['is_read'] ?? false),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class NotificationsNotifier extends AsyncNotifier<List<NotificationModel>> {
  static const String _readKey = 'read_notification_ids';

  @override
  Future<List<NotificationModel>> build() async {
    return _fetch();
  }

  Future<List<NotificationModel>> _fetch() async {
    final prefs = await SharedPreferences.getInstance();
    // Get current user id from authProvider
    final authState = ref.read(authProvider);
    final userId = authState.user?['id'] ?? 'global';
    final userReadKey = '${_readKey}_$userId';
    
    final readIds = prefs.getStringList(userReadKey) ?? [];
    
    final res = await ApiService.get('/notifications');
    if (res['success'] == true) {
      final List<dynamic> data = res['data'];
      return data.map((e) {
        final id = e['id'] as String;
        return NotificationModel.fromJson(e, localIsRead: readIds.contains(id));
      }).toList();
    }
    throw Exception(res['message'] ?? 'Failed to load');
  }

  Future<void> fetchNotifications() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetch());
  }

  Future<void> markAsRead(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authState = ref.read(authProvider);
      final userId = authState.user?['id'] ?? 'global';
      final userReadKey = '${_readKey}_$userId';
      
      final readIds = prefs.getStringList(userReadKey) ?? [];
      
      if (!readIds.contains(id)) {
        readIds.add(id);
        await prefs.setStringList(userReadKey, readIds);
      }

      // If it's a real notification (UUID), try to sync with backend
      if (!id.startsWith('ann_')) {
        await ApiService.put('/notifications/$id/read', {});
      }

      state = state.whenData((list) {
        return list.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList();
      });
    } catch (e) {
      // Local fallback still works even if API fails
      state = state.whenData((list) {
        return list.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList();
      });
    }
  }
}

final notificationsProvider = AsyncNotifierProvider<NotificationsNotifier, List<NotificationModel>>(() {
  return NotificationsNotifier();
});
