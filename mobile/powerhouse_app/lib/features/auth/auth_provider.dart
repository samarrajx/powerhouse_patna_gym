import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_service.dart';

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final String? role;
  final Map<String, dynamic>? user;
  final bool comebackEligible;
  final String? errorMessage;

  AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.role,
    this.user,
    this.comebackEligible = false,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    String? role,
    Map<String, dynamic>? user,
    bool? comebackEligible,
    String? errorMessage,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      role: role ?? this.role,
      user: user ?? this.user,
      comebackEligible: comebackEligible ?? this.comebackEligible,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // We can't call async here directly for initial state,
    // so we return initial state and trigger checkAuth after.
    Future.microtask(() => checkAuth());
    return AuthState(isLoading: true);
  }

  Future<void> checkAuth() async {
    state = state.copyWith(isLoading: true);
    try {
      final token = await ApiService.getToken();
      if (token != null) {
        final res = await ApiService.get('/auth/me');
        if (res['success'] == true) {
          state = AuthState(
            isAuthenticated: true,
            user: res['data'],
            role: res['data']['role'],
            comebackEligible: res['comeback_eligible'] == true,
            isLoading: false,
          );
        } else {
          if (res['status_code'] == 401) {
            await ApiService.clearToken();
            state = AuthState(isLoading: false);
          } else {
            state = AuthState(isLoading: false, errorMessage: res['message']);
          }
        }
      } else {
        state = AuthState(isLoading: false);
      }
    } catch (e) {
      state = AuthState(isLoading: false, errorMessage: 'Initialization error');
    }
  }

  Future<void> login(String phone, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final res = await ApiService.post('/auth/login', {
        'phone': phone,
        'password': password,
      });

      if (res['success'] == true) {
        await ApiService.saveToken(res['data']['token']);
        state = AuthState(
          isAuthenticated: true,
          user: res['data']['user'],
          role: res['data']['user']['role'],
          comebackEligible: res['data']['comeback_eligible'] == true,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: res['message'] ?? 'Login failed',
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Network error');
    }
  }

  Future<bool> changePassword(String oldPwd, String newPwd) async {
    try {
      final res = await ApiService.post('/auth/change-password', {
        'oldPassword': oldPwd,
        'newPassword': newPwd,
      });
      return res['success'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> claimComeback() async {
    try {
      final res = await ApiService.post('/auth/claim-comeback', {});
      if (res['success'] == true) {
        await checkAuth(); // Refresh user data to get new expiry
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> logout() async {
    await ApiService.clearToken();
    state = AuthState();
  }

  Future<void> registerDeviceToken(String token) async {
    try {
      final res = await ApiService.post('/auth/device-token', {'token': token});
      if (res['success'] == true) {
        print('🔔 FCM Token registered with backend');
      } else {
        print('⚠️ FCM Token registration failed: ${res['message']}');
      }
    } catch (e) {
      print('❌ FCM Token registration error: $e');
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
