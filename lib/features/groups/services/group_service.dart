import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pagella_sanremo/features/groups/models/group.dart';

class GroupService {
  SupabaseClient get _client => Supabase.instance.client;

  /// Genera un codice di 6 caratteri senza caratteri ambigui (I, L, O, 0, 1)
  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
  }

  /// Crea un gruppo e aggiunge il creatore come membro.
  /// Riprova fino a 3 volte in caso di codice duplicato.
  Future<Group?> createGroup({
    required String name,
    String emoji = '👥',
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final code = _generateCode();

        final response = await _client
            .from('groups')
            .insert({
              'name': name,
              'emoji': emoji,
              'code': code,
              'owner_id': userId,
            })
            .select()
            .single();

        final group = Group.fromMap(response);

        await _client.from('group_members').insert({
          'group_id': group.id,
          'user_id': userId,
        });

        return group;
      } on PostgrestException catch (e) {
        if (e.code == '23505' && attempt < 2) {
          debugPrint('Codice duplicato, retry ${attempt + 1}');
          continue;
        }
        debugPrint('Errore creazione gruppo: $e');
        return null;
      } catch (e) {
        debugPrint('Errore creazione gruppo: $e');
        return null;
      }
    }
    return null;
  }

  Future<Group?> joinGroup(String code) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final groupResponse = await _client
          .from('groups')
          .select()
          .eq('code', code.toUpperCase())
          .single();

      final group = Group.fromMap(groupResponse);

      final existingMember = await _client
          .from('group_members')
          .select()
          .eq('group_id', group.id)
          .eq('user_id', userId)
          .maybeSingle();

      if (existingMember != null) return group;

      await _client.from('group_members').insert({
        'group_id': group.id,
        'user_id': userId,
      });

      return group;
    } catch (e) {
      debugPrint('Errore unione al gruppo: $e');
      return null;
    }
  }

  /// Recupera i gruppi dell'utente con conteggio membri (2 query ottimizzate).
  Future<List<Group>> getMyGroups() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _client
          .from('group_members')
          .select('group_id, groups(*)')
          .eq('user_id', userId);

      if ((response as List).isEmpty) return [];

      final groupIds =
          response.map((m) => m['groups']['id'] as String).toList();

      final membersCountResponse = await _client
          .from('group_members')
          .select('group_id')
          .inFilter('group_id', groupIds);

      final memberCounts = <String, int>{};
      for (final row in membersCountResponse as List) {
        final gid = row['group_id'] as String;
        memberCounts[gid] = (memberCounts[gid] ?? 0) + 1;
      }

      return response.map<Group>((m) {
        final groupData = m['groups'] as Map<String, dynamic>;
        final gid = groupData['id'] as String;
        return Group.fromMap({
          ...groupData,
          'member_count': memberCounts[gid] ?? 0,
        });
      }).toList();
    } catch (e) {
      debugPrint('Errore caricamento gruppi: $e');
      return [];
    }
  }

  /// Recupera i membri con statistiche di voto (2 query ottimizzate).
  /// Ordinati per media decrescente, senza voti in fondo.
  Future<List<GroupMember>> getGroupMembers(String groupId) async {
    try {
      final response = await _client.from('group_members').select('''
            id,
            group_id,
            user_id,
            joined_at,
            profiles (
              username,
              email
            )
          ''').eq('group_id', groupId);

      if ((response as List).isEmpty) return [];

      final userIds = response.map((m) => m['user_id'] as String).toList();

      final allVotes = await _client
          .from('votes')
          .select('user_id, canto, testo, look')
          .inFilter('user_id', userIds);

      final statsMap = <String, Map<String, dynamic>>{};
      for (final uid in userIds) {
        statsMap[uid] = {'totalSum': 0.0, 'totalCount': 0, 'voteCount': 0};
      }

      for (final vote in allVotes as List) {
        final uid = vote['user_id'] as String;
        final scores = [vote['canto'], vote['testo'], vote['look']]
            .whereType<num>()
            .toList();

        if (scores.isNotEmpty) {
          statsMap[uid]!['totalSum'] = (statsMap[uid]!['totalSum'] as double) +
              scores.reduce((a, b) => a + b).toDouble();
          statsMap[uid]!['totalCount'] =
              (statsMap[uid]!['totalCount'] as int) + scores.length;
        }
        statsMap[uid]!['voteCount'] = (statsMap[uid]!['voteCount'] as int) + 1;
      }

      final members = response.map<GroupMember>((memberData) {
        final profile = memberData['profiles'] as Map<String, dynamic>?;
        final uid = memberData['user_id'] as String;
        final stats = statsMap[uid]!;
        final totalCount = stats['totalCount'] as int;
        final totalSum = stats['totalSum'] as double;

        return GroupMember(
          id: memberData['id'],
          groupId: memberData['group_id'],
          userId: uid,
          username: profile?['username'] ?? profile?['email'] ?? 'Utente',
          email: profile?['email'],
          joinedAt: DateTime.parse(memberData['joined_at']),
          averageScore: totalCount > 0 ? totalSum / totalCount : null,
          totalVotes: stats['voteCount'] as int,
        );
      }).toList();

      members.sort((a, b) {
        if (a.averageScore == null && b.averageScore == null) return 0;
        if (a.averageScore == null) return 1;
        if (b.averageScore == null) return -1;
        return b.averageScore!.compareTo(a.averageScore!);
      });

      return members;
    } catch (e) {
      debugPrint('Errore caricamento membri: $e');
      return [];
    }
  }

  Future<bool> leaveGroup(String groupId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      await _client
          .from('group_members')
          .delete()
          .eq('group_id', groupId)
          .eq('user_id', userId);
      return true;
    } catch (e) {
      debugPrint('Errore uscita dal gruppo: $e');
      return false;
    }
  }

  /// Elimina gruppo (solo owner). I membri vengono rimossi via CASCADE.
  Future<bool> deleteGroup(String groupId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      await _client
          .from('groups')
          .delete()
          .eq('id', groupId)
          .eq('owner_id', userId);
      return true;
    } catch (e) {
      debugPrint('Errore eliminazione gruppo: $e');
      return false;
    }
  }
}
