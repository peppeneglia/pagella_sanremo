import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommunityRanking {
  final String artistName;
  final String date;
  final double avgCanto;
  final double avgTesto;
  final double avgLook;
  final double avgTotal;
  final int totalVoters;

  const CommunityRanking({
    required this.artistName,
    required this.date,
    required this.avgCanto,
    required this.avgTesto,
    required this.avgLook,
    required this.avgTotal,
    required this.totalVoters,
  });

  factory CommunityRanking.fromMap(Map<String, dynamic> map) {
    return CommunityRanking(
      artistName: map['artist_name'] as String,
      date: map['date'] as String,
      avgCanto: (map['avg_canto'] as num?)?.toDouble() ?? 0,
      avgTesto: (map['avg_testo'] as num?)?.toDouble() ?? 0,
      avgLook: (map['avg_look'] as num?)?.toDouble() ?? 0,
      avgTotal: (map['avg_total'] as num?)?.toDouble() ?? 0,
      totalVoters: (map['total_voters'] as num?)?.toInt() ?? 0,
    );
  }
}

class CommunityRankingService {
  SupabaseClient get _client => Supabase.instance.client;

  Future<List<CommunityRanking>> fetchRankings(String date) async {
    try {
      final response = await _client
          .from('community_rankings')
          .select()
          .eq('date', date)
          .order('avg_total', ascending: false);

      return (response as List)
          .map((row) => CommunityRanking.fromMap(row))
          .toList();
    } catch (e) {
      debugPrint('Errore caricamento classifica community: $e');
      return [];
    }
  }

  Future<List<CommunityRanking>> fetchOverallRankings() async {
    try {
      final response = await _client.rpc('get_overall_community_rankings');

      return (response as List)
          .map((row) => CommunityRanking.fromMap(row))
          .toList();
    } catch (e) {
      debugPrint('Errore caricamento classifica generale: $e');
      return [];
    }
  }
}
