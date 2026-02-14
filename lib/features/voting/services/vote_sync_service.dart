import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VoteSyncService {
  SupabaseClient get _client => Supabase.instance.client;

  Future<void> upsertVote({
    required String artistName,
    required String date,
    int? canto,
    int? testo,
    int? look,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _client.from('votes').upsert({
        'user_id': userId,
        'artist_name': artistName,
        'date': date,
        'canto': canto,
        'testo': testo,
        'look': look,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,artist_name,date');
    } catch (e) {
      debugPrint('Errore upsert voto: $e');
    }
  }

  Future<Map<String, Map<String, Map<String, double>>>> fetchAllVotes() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return {};

    try {
      final response =
          await _client.from('votes').select().eq('user_id', userId);

      final Map<String, Map<String, Map<String, double>>> votes = {};

      for (final row in response) {
        final date = row['date'] as String;
        final artistName = row['artist_name'] as String;

        votes[date] ??= {};
        votes[date]![artistName] = {};

        if (row['canto'] != null) {
          votes[date]![artistName]!['CANTO'] = (row['canto'] as num).toDouble();
        }
        if (row['testo'] != null) {
          votes[date]![artistName]!['TESTO'] = (row['testo'] as num).toDouble();
        }
        if (row['look'] != null) {
          votes[date]![artistName]!['LOOK'] = (row['look'] as num).toDouble();
        }
      }

      return votes;
    } catch (e) {
      debugPrint('Errore fetch voti: $e');
      return {};
    }
  }

  /// Carica in blocco i voti locali su Supabase, in chunk da 50
  Future<void> syncLocalVotes(
      Map<String, Map<String, Map<String, double>>> localVotes) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final rows = <Map<String, dynamic>>[];

      for (final dateEntry in localVotes.entries) {
        final date = dateEntry.key;
        for (final artistEntry in dateEntry.value.entries) {
          final artistName = artistEntry.key;
          final scores = artistEntry.value;

          rows.add({
            'user_id': userId,
            'artist_name': artistName,
            'date': date,
            'canto': scores['CANTO']?.toInt(),
            'testo': scores['TESTO']?.toInt(),
            'look': scores['LOOK']?.toInt(),
            'updated_at': DateTime.now().toIso8601String(),
          });
        }
      }

      for (var i = 0; i < rows.length; i += 50) {
        final chunk = rows.sublist(
          i,
          i + 50 > rows.length ? rows.length : i + 50,
        );
        await _client
            .from('votes')
            .upsert(chunk, onConflict: 'user_id,artist_name,date');
      }

      debugPrint('Sync batch completata: ${rows.length} voti');
    } catch (e) {
      debugPrint('Errore sync batch: $e');
    }
  }
}
