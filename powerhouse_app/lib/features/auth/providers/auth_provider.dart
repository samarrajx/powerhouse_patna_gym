import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage.dart';

// Providers setup
final secureStorageProvider = Provider((ref) => SecureStorage());
final apiClientProvider = Provider((ref) => ApiClient(ref.read(secureStorageProvider)));

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
  return AuthNotifier(ref.read(apiClientProvider), ref.read(secureStorageProvider));
});

class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  final ApiClient _api;
  final SecureStorage _storage;

  AuthNotifier(this._api, this._storage) : super(const AsyncData(null));

  Future<bool> login(String phone, String password) async {
    state = const AsyncLoading();
    try {
      final response = await _api.client.post('/auth/login', data: {
        'phone': phone,
        'password': password,
      });

      if (response.data['success']) {
        final token = response.data['data']['token'];
        await _storage.write('jwt_token', token);
        state = const AsyncData(null);
        return true;
      } else {
        state = AsyncError(response.data['message'], StackTrace.current);
        return false;
      }
    } catch (e) {
      state = AsyncError("Login failed: ${e.toString()}", StackTrace.current);
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.delete('jwt_token');
    state = const AsyncData(null);
  }
}
