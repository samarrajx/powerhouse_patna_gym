import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_service.dart';

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final String? role;
  final Map<String, dynamic>? user;
  final String? errorMessage;

  AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.role,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    String? role,
    Map<String, dynamic>? user,
    String? errorMessage,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      role: role ?? this.role,
      user: user ?? this.user,
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
    final token = await ApiService.getToken();
    if (token != null) {
      final res = await ApiService.get('/auth/me');
      if (res['success'] == true) {
        state = AuthState(
          isAuthenticated: true,
          user: res['data'],
          role: res['data']['role'],
          isLoading: false,
        );
      } else {
        await ApiService.clearToken();
        state = AuthState(isLoading: false);
      }
    } else {
      state = AuthState(isLoading: false);
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

  Future<void> logout() async {
    await ApiService.clearToken();
    state = AuthState();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
