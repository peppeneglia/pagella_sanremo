import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pagella_sanremo/features/rankings/services/community_ranking_service.dart';
import 'package:pagella_sanremo/features/voting/providers/voting_providers.dart';

final communityRankingServiceProvider =
    Provider<CommunityRankingService>((ref) {
  return CommunityRankingService();
});

final currentCommunityRankingProvider =
    FutureProvider<List<CommunityRanking>>((ref) async {
  final selectedDate = ref.watch(selectedDateProvider);
  final service = ref.watch(communityRankingServiceProvider);
  return await service.fetchRankings(selectedDate);
});
