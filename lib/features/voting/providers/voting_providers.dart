import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/artists_data.dart';
import '../models/artist.dart';
import '../services/vote_sync_service.dart';

export 'package:pagella_sanremo/features/voting/data/artists_data.dart'
    show artists, coverNightArtists;

final dates = [
  'MAR 24',
  'MER 25',
  'GIO 26',
  'VEN 27',
  'SAB 28',
];

final selectedDateProvider = StateProvider<String>((ref) => dates[0]);

/// Distribuzione artisti per serata:
/// MAR 24: tutti i 30 | MER 25: primi 15 | GIO 26: ultimi 15
/// VEN 27: serata cover con ospiti | SAB 28: finale, tutti i 30
final artistsForDateProvider =
    Provider.family<List<Artist>, String>((ref, date) {
  switch (date) {
    case 'MAR 24':
      return artists;
    case 'MER 25':
      return artists.take(15).toList();
    case 'GIO 26':
      return artists.skip(15).toList();
    case 'VEN 27':
      return coverNightArtists;
    case 'SAB 28':
      return artists;
    default:
      return [];
  }
});

/// Stato: Map<data, Map<nomeArtista, Map<categoria, punteggio>>>
final votesProvider = StateNotifierProvider<VotesNotifier,
    Map<String, Map<String, Map<String, double>>>>((ref) {
  return VotesNotifier(ref);
});

class VotesNotifier
    extends StateNotifier<Map<String, Map<String, Map<String, double>>>> {
  final VoteSyncService _syncService = VoteSyncService();

  VotesNotifier(Ref ref) : super({}) {
    _init();
  }

  static const String _votesKey = 'votes';
  Timer? _saveTimer;
  bool _isSaving = false;

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    await _loadLocalVotes();

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      await _syncWithSupabase();
    }
  }

  Future<void> _loadLocalVotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final votesString = prefs.getString(_votesKey);

      if (votesString != null) {
        final Map<String, dynamic> votesMap = jsonDecode(votesString);
        final newState = <String, Map<String, Map<String, double>>>{};

        for (final date in votesMap.keys) {
          newState[date] = {};
          final dateVotes = votesMap[date] as Map<String, dynamic>;

          for (final artistName in dateVotes.keys) {
            newState[date]![artistName] = {};
            final artistVotes = dateVotes[artistName] as Map<String, dynamic>;

            for (final category in artistVotes.keys) {
              final score = artistVotes[category] as num;
              newState[date]![artistName]![category] = score.toDouble();
            }
          }
        }

        state = newState;
        debugPrint('Voti locali caricati');
      }
    } catch (e) {
      debugPrint('Errore nel caricamento dei voti locali: $e');
    }
  }

  /// Merge dei voti remoti con quelli locali (priorita' ai remoti).
  /// Se non ci sono voti remoti ma esistono locali, li carica su Supabase.
  Future<void> _syncWithSupabase() async {
    try {
      final remoteVotes = await _syncService.fetchAllVotes();

      if (remoteVotes.isNotEmpty) {
        final mergedVotes =
            Map<String, Map<String, Map<String, double>>>.from(state);

        for (final dateEntry in remoteVotes.entries) {
          mergedVotes[dateEntry.key] ??= {};
          for (final artistEntry in dateEntry.value.entries) {
            mergedVotes[dateEntry.key]![artistEntry.key] = artistEntry.value;
          }
        }

        state = mergedVotes;
        await _saveLocalVotes();
        debugPrint('Voti sincronizzati da Supabase');
      } else if (state.isNotEmpty) {
        await _syncService.syncLocalVotes(state);
        debugPrint('Voti locali caricati su Supabase');
      }
    } catch (e) {
      debugPrint('Errore sync Supabase: $e');
    }
  }

  Future<void> _saveLocalVotes() async {
    if (_isSaving) return;
    _isSaving = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final votesString = jsonEncode(state);
      await prefs.setString(_votesKey, votesString);
    } catch (e) {
      debugPrint('Errore nel salvataggio locale: $e');
    } finally {
      _isSaving = false;
    }
  }

  void _debouncedSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), () {
      _saveLocalVotes();
    });
  }

  Future<void> updateVote(
      String date, String artistName, String category, double score) async {
    final newState = Map<String, Map<String, Map<String, double>>>.from(state);
    newState[date] ??= {};
    newState[date]![artistName] ??= {};
    newState[date]![artistName]![category] = score;
    state = newState;

    _debouncedSave();

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final artistScores = newState[date]![artistName]!;
      await _syncService.upsertVote(
        artistName: artistName,
        date: date,
        canto: artistScores['CANTO']?.toInt(),
        testo: artistScores['TESTO']?.toInt(),
        look: artistScores['LOOK']?.toInt(),
      );
    }
  }

  Future<void> removeVote(
      String date, String artistName, String category) async {
    final newState = Map<String, Map<String, Map<String, double>>>.from(state);
    newState[date] ??= {};
    newState[date]![artistName]?.remove(category);

    if (newState[date]![artistName]?.isEmpty ?? false) {
      newState[date]!.remove(artistName);
    }

    if (newState[date]?.isEmpty ?? false) {
      newState.remove(date);
    }

    state = newState;
    _debouncedSave();
  }

  Map<String, Map<String, double>> getVotesForDate(String date) {
    return state[date] ?? {};
  }

  Map<String, double>? getArtistVotes(String date, String artistName) {
    return state[date]?[artistName];
  }

  Future<void> forceSync() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      await _syncWithSupabase();
    }
  }
}
