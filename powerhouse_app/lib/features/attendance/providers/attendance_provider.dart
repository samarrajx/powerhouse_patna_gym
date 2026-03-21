import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';

final attendanceProvider = StateNotifierProvider<AttendanceNotifier, AsyncValue<Map<String, dynamic>?>>((ref) {
  return AttendanceNotifier(ref.read(apiClientProvider).client);
});

class AttendanceNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>?>> {
  final Dio _client;

  AttendanceNotifier(this._client) : super(const AsyncData(null));

  Future<bool> processScan(String qrHash) async {
    state = const AsyncLoading();
    try {
      final response = await _client.post('/qr/scan', data: {
        'code_hash': qrHash
      });

      if (response.statusCode == 200 && response.data['success']) {
        state = AsyncData(response.data);
        return true; // Successfully checked in/out
      } else {
        state = AsyncError(response.data['message'] ?? 'Invalid QR', StackTrace.current);
        return false;
      }
    } on DioException catch (e) {
      if (e.response != null) {
          state = AsyncError(e.response?.data['message'] ?? 'Network Error', StackTrace.current);
      } else {
          state = AsyncError("Connection timeout. Ensure fast <2s scanning conditions.", StackTrace.current);
      }
      return false;
    }
  }
}
