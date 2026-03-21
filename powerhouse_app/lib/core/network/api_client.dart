import 'package:dio/dio.dart';
import '../storage/secure_storage.dart';

class ApiClient {
  final Dio _dio;
  final SecureStorage _storage;

  ApiClient(this._storage) : _dio = Dio(BaseOptions(
    baseUrl: 'https://powerhouse-gym-api.vercel.app/api',
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 3),
  )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read('jwt_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401) {
          // Token expired handling, kick user out to login
        }
        return handler.next(e);
      }
    ));
  }

  Dio get client => _dio;
}
