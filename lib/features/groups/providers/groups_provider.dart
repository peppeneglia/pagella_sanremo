import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pagella_sanremo/features/groups/models/group.dart';
import 'package:pagella_sanremo/features/groups/services/group_service.dart';

final groupServiceProvider = Provider<GroupService>((ref) {
  return GroupService();
});

final myGroupsProvider = FutureProvider<List<Group>>((ref) async {
  final service = ref.watch(groupServiceProvider);
  return await service.getMyGroups();
});

final groupMembersProvider =
    FutureProvider.family<List<GroupMember>, String>((ref, groupId) async {
  final service = ref.watch(groupServiceProvider);
  return await service.getGroupMembers(groupId);
});
