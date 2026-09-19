import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VoteSyncService {
  SupabaseClient get _client => Supabase.instance.client;

  /// Fetch tutti i voti dell'utente da Supabase.
  /// Lancia eccezione in caso di errore (il chiamante gestisce il fallback).
  Future<Map<String, Map<String, Map<String, double>>>> fetchAllVotes(
      String userId) async {
    final response = await _client.from('votes').select().eq('user_id', userId);

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
  }

  /// Upsert singolo voto. Errori loggati e ignorati (fire-and-forget).
  Future<void> upsertVote({
    required String userId,
    required String artistName,
    required String date,
    num? canto,
    num? testo,
    num? look,
  }) async {
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

  /// Upsert batch di righe pre-costruite, in chunk da 50.
  Future<void> batchUpsert(List<Map<String, dynamic>> rows) async {
    try {
      for (var i = 0; i < rows.length; i += 50) {
        final chunk = rows.sublist(
          i,
          i + 50 > rows.length ? rows.length : i + 50,
        );
        await _client
            .from('votes')
            .upsert(chunk, onConflict: 'user_id,artist_name,date');
      }
      debugPrint('Batch upsert completato: ${rows.length} righe');
    } catch (e) {
      debugPrint('Errore batch upsert: $e');
    }
  }
}
