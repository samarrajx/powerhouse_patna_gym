import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

class StorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static Future<void> saveToken(String token) =>
      _storage.write(key: AppConstants.jwtKey, value: token);

  static Future<String?> getToken() =>
      _storage.read(key: AppConstants.jwtKey);

  static Future<void> saveUser(String json) =>
      _storage.write(key: AppConstants.userKey, value: json);

  static Future<String?> getUser() =>
      _storage.read(key: AppConstants.userKey);

  static Future<void> clear() => _storage.deleteAll();
}
