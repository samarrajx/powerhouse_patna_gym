import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import '../services/storage_service.dart';

final dio = _createDio();

Dio _createDio() {
  final d = Dio(BaseOptions(
    baseUrl: AppConstants.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
  ));

  d.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await StorageService.getToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
    onError: (error, handler) {
      handler.next(error);
    },
  ));

  return d;
}

// Generic API call wrapper matching { success, message, data, error_code }
Future<Map<String, dynamic>> apiCall(Future<Response> call) async {
  try {
    final res = await call;
    return res.data as Map<String, dynamic>;
  } on DioException catch (e) {
    final data = e.response?.data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {'success': false, 'message': e.message ?? 'Network error', 'data': null, 'error_code': 'NETWORK_ERROR'};
  }
}
