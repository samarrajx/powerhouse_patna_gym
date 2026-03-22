import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_service.dart';

class LeaderboardState {
  final bool isLoading;
  final List<dynamic> players;
  final Map<String, dynamic>? userStats;
  final String? error;

  LeaderboardState({
    this.isLoading = false,
    this.players = const [],
    this.userStats,
    this.error,
  });

  LeaderboardState copyWith({
    bool? isLoading,
    List<dynamic>? players,
    Map<String, dynamic>? userStats,
    String? error,
  }) {
    return LeaderboardState(
      isLoading: isLoading ?? this.isLoading,
      players: players ?? this.players,
      userStats: userStats ?? this.userStats,
      error: error ?? this.error,
    );
  }
}

class LeaderboardNotifier extends Notifier<LeaderboardState> {
  @override
  LeaderboardState build() {
    // Initial fetch
    Future.microtask(() => refresh());
    return LeaderboardState(isLoading: true);
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await ApiService.get('/user/leaderboard');
      final statsRes = await ApiService.get('/user/stats');
      
      if (res['success'] == true) {
        state = state.copyWith(
          players: res['data'],
          userStats: statsRes['success'] == true ? statsRes['data'] : null,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false, error: res['message']);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Network error');
    }
  }
}

final leaderboardProvider = NotifierProvider<LeaderboardNotifier, LeaderboardState>(() {
  return LeaderboardNotifier();
});
