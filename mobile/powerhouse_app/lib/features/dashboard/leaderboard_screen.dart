import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_theme.dart';
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
            else if (state.players.length > 3)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final player = state.players[index + 3];
                      return _buildRankItem(context, index + 4, player);
                    },
                    childCount: state.players.length - 3,
                  ),
                ),
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
              child: Text('$rank', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
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

  Widget _buildRankItem(BuildContext context, int rank, dynamic player) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfHigh(context)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text('#$rank', style: TextStyle(color: AppColors.text3(context), fontWeight: FontWeight.w900, fontSize: 14)),
          ),
          const SizedBox(width: 12),
          const CircleAvatar(
            radius: 18,
            backgroundImage: AssetImage('assets/images/logo.jpg'),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              player['name'],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
          Text(
            '${player['current_streak']}',
            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 18),
          ),
          const SizedBox(width: 4),
          const Text('🔥', style: TextStyle(fontSize: 14)),
        ],
      ),
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
