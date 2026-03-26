import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_theme.dart';
import '../../core/ui/design_system.dart';
import '../../core/ui/app_card.dart';
import '../../core/theme/rank_theme.dart';
import '../auth/auth_provider.dart';
import 'leaderboard_provider.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(leaderboardProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('LEADERBOARD'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(leaderboardProvider.notifier).refresh(),
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Top 3 Podium
            SliverToBoxAdapter(
              child: _buildPodium(state.players.take(3).toList()),
            ),

            // Ranking List
            if (state.isLoading)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppColors.primary)))
            else if (state.players.length > 0) // Changed from > 3 to > 0 to include all players in the list
              SliverToBoxAdapter(
                child: _buildList(state.players, state.userStats, ref),
              )
            else if (state.players.isEmpty && !state.isLoading)
              const SliverFillRemaining(child: Center(child: Text('No streaks yet! 🏋️', style: TextStyle(color: Colors.white70)))),
            
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      bottomSheet: state.userStats != null ? _buildUserRankBar(context, state.userStats!) : null,
    );
  }

  Widget _buildPodium(List<dynamic> top3) {
    if (top3.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (top3.length > 1) _buildPodiumItem(top3[1], 2, 70),
          const SizedBox(width: 15),
          if (top3.isNotEmpty) _buildPodiumItem(top3[0], 1, 90),
          const SizedBox(width: 15),
          if (top3.length > 2) _buildPodiumItem(top3[2], 3, 60),
        ],
      ),
    );
  }

  Widget _buildPodiumItem(dynamic player, int rank, double height) {
    final colors = [Colors.amber, Colors.grey, Colors.brown];
    final color = rank <= 3 ? colors[rank - 1] : Colors.blueAccent;

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: height,
              height: height,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 3),
                image: const DecorationImage(
                  image: AssetImage('assets/images/logo.jpg'), // Placeholder
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Text('$rank', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          player['name'].toString().split(' ')[0],
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
        ),
        Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
          child: Text('${player['current_streak']}🔥', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
        ),
      ],
    );
  }

  Widget _buildList(List<dynamic> players, Map<String, dynamic>? userStats, WidgetRef ref) {
    final currentUserId = ref.watch(authProvider).user?['id'];

    return ListView.separated(
      shrinkWrap: true, // Added shrinkWrap to allow ListView inside CustomScrollView
      physics: const NeverScrollableScrollPhysics(), // Added NeverScrollableScrollPhysics to prevent nested scrolling
      padding: const EdgeInsets.all(AppPadding.p16),
      itemCount: players.length,
      separatorBuilder: (_, __) => AppSpacing.s12,
      itemBuilder: (context, index) {
        final player = players[index];
        final isMe = player['id'] == currentUserId;
        final rankNum = index + 1;
        final streak = player['current_streak'] ?? 0;
        
        // Determine rank tier for color coding
        String rankTier = 'E';
        if (streak > 50) rankTier = 'S';
        else if (streak > 35) rankTier = 'A';
        else if (streak > 20) rankTier = 'B';
        else if (streak > 10) rankTier = 'C';
        else if (streak > 3) rankTier = 'D';
        
        final rankColor = RankTheme.getRankColor(rankTier);

        return AppCard(
          backgroundColor: isMe ? AppColors.primary.withOpacity(0.05) : null,
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: Text(
                  rankNum <= 3 ? ['🥇', '🥈', '🥉'][rankNum - 1] : rankNum.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: rankNum <= 3 ? 20 : 14,
                    color: rankNum <= 3 ? null : AppColors.text3(context),
                  ),
                ),
              ),
              AppSpacing.s12,
              CircleAvatar(
                radius: 18,
                backgroundColor: isMe ? AppColors.primary : AppColors.surfHigh(context),
                child: Text(
                  (player['name'] ?? 'U')[0].toUpperCase(),
                  style: TextStyle(color: isMe ? Colors.white : AppColors.text1(context), fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
              AppSpacing.s16,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          player['name'] ?? 'MEMBER',
                          style: TextStyle(
                            fontWeight: isMe ? FontWeight.w900 : FontWeight.w700,
                            fontSize: 14,
                            color: isMe ? AppColors.primary : AppColors.text1(context),
                          ),
                        ),
                        if (isMe) ...[
                          AppSpacing.s8,
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('YOU', style: TextStyle(color: AppColors.primary, fontSize: 8, fontWeight: FontWeight.w900)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$streak DAYS',
                    style: TextStyle(fontWeight: FontWeight.w900, color: rankColor, fontSize: 13),
                  ),
                  Text(
                    'RANK $rankTier',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: rankColor.withOpacity(0.7), letterSpacing: 0.5),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUserRankBar(BuildContext context, Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surf(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20)],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('YOUR RANKING', style: TextStyle(color: AppColors.text3(context), fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.5)),
                const SizedBox(height: 4),
                Text('#${stats['rank']} WORLDWIDE', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(15)),
              child: Row(
                children: [
                  Text('${stats['current_streak']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                  const SizedBox(width: 4),
                  const Text('🔥', style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
