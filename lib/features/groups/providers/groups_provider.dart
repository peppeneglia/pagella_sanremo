import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pagella_sanremo/features/groups/models/group.dart';
import 'package:pagella_sanremo/features/groups/services/group_service.dart';
import 'package:pagella_sanremo/features/rankings/services/community_ranking_service.dart';
import 'package:pagella_sanremo/features/voting/providers/voting_providers.dart';

final groupServiceProvider = Provider<GroupService>((ref) {
  return GroupService();
});

final myGroupsProvider = FutureProvider<List<Group>>((ref) {
  final service = ref.watch(groupServiceProvider);
  return service.getMyGroups();
});

final groupRankingsProvider =
    FutureProvider.family<List<CommunityRanking>, String>((ref, groupId) {
  final date = ref.watch(selectedDateProvider);
  final service = ref.watch(groupServiceProvider);
  return service.fetchGroupRankings(groupId, date);
});

final artistMemberVotesProvider = FutureProvider.family<List<MemberArtistVote>,
    ({String groupId, String artistName, String date})>((ref, params) {
  final service = ref.watch(groupServiceProvider);
  return service.getArtistMemberVotes(
      params.groupId, params.artistName, params.date);
});

final selectedGroupIdProvider = StateProvider<String?>((ref) => null);
