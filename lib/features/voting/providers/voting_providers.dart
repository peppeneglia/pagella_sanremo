import 'dart:convert';
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

/// Account loggato: Supabase e' fonte primaria, cache locale di backup.
/// Anonimo: solo SharedPreferences.
///
/// Al login: cache locale (istantanea) + fetch Supabase + merge.
/// La cache copre il gap se un upsert era ancora in-flight al logout.
final votesProvider = StateNotifierProvider<VotesNotifier,
    Map<String, Map<String, Map<String, double>>>>((ref) {
  final user = Supabase.instance.client.auth.currentUser;
  return VotesNotifier(userId: user?.id);
});

class VotesNotifier
    extends StateNotifier<Map<String, Map<String, Map<String, double>>>> {
  final VoteSyncService _syncService = VoteSyncService();
  final String? _userId;

  VotesNotifier({String? userId}) : _userId = userId, super({}) {
    _init();
  }

  String get _cacheKey => 'votes_${_userId ?? "anonymous"}';

  Future<void> _init() async {
    if (_userId != null) {
      // 1. Carica cache locale (istantaneo, sopravvive a logout rapidi)
      await _loadCache();
      final cached = _deepCopy(state);

      // 2. Fetch da Supabase (fonte primaria)
      try {
        final remote = await _syncService.fetchAllVotes(_userId);
        if (!mounted) return;

        // 3. Merge: Supabase vince, cache riempie i gap
        //    (gap = voti salvati in cache ma il cui upsert non era ancora arrivato)
        final merged = _deepCopy(remote);
        final toSync = <Map<String, dynamic>>[];

        for (final de in cached.entries) {
          merged[de.key] ??= {};
          for (final ae in de.value.entries) {
            merged[de.key]![ae.key] ??= {};
            bool hasNew = false;

            for (final ce in ae.value.entries) {
              if (merged[de.key]![ae.key]![ce.key] == null) {
                merged[de.key]![ae.key]![ce.key] = ce.value;
                hasNew = true;
              }
            }

            if (hasNew) {
              final s = merged[de.key]![ae.key]!;
              toSync.add({
                'user_id': _userId,
                'artist_name': ae.key,
                'date': de.key,
                'canto': _validScore(s['CANTO']),
                'testo': _validScore(s['TESTO']),
                'look': _validScore(s['LOOK']),
                'updated_at': DateTime.now().toIso8601String(),
              });
            }
          }
        }

        state = merged;

        if (toSync.isNotEmpty) {
          _syncService.batchUpsert(toSync);
          debugPrint('Push ${toSync.length} voti dalla cache a Supabase');
        }

        debugPrint('Voti caricati: ${remote.length} da Supabase'
            '${toSync.isNotEmpty ? " + ${toSync.length} dalla cache" : ""}');
      } catch (e) {
        debugPrint('Supabase non raggiungibile, uso cache: $e');
        // state gia' caricato dalla cache al punto 1
      }

      // 4. Migra eventuali voti anonimi nell'account
      await _migrateAnonymousVotes();
      _saveCache();
    } else {
      // Anonimo: solo SharedPreferences
      await _loadCache();
    }
  }

  // -- Cache locale (salvataggio immediato, no debounce) --

  Future<void> _loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var data = prefs.getString(_cacheKey);

      // Migrazione una tantum dalla vecchia chiave 'votes'
      if (data == null && _userId != null) {
        data = prefs.getString('votes');
        if (data != null) {
          await prefs.setString(_cacheKey, data);
          await prefs.remove('votes');
        }
      }

      if (data != null && mounted) {
        state = _parseJson(data);
      }
    } catch (e) {
      debugPrint('Errore caricamento cache: $e');
    }
  }

  /// Salva cache immediatamente. Fire-and-forget, SharedPreferences
  /// aggiorna la cache in-memoria in modo sincrono quindi e' subito
  /// disponibile anche se il write su disco e' ancora in corso.
  void _saveCache() {
    final snapshot = jsonEncode(state);
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(_cacheKey, snapshot);
    });
  }

  // -- Migrazione anonimo -> account --

  Future<void> _migrateAnonymousVotes() async {
    if (_userId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final anonData = prefs.getString('votes_anonymous');
    if (anonData == null) return;

    try {
      final anonVotes = _parseJson(anonData);
      if (anonVotes.isEmpty) {
        await prefs.remove('votes_anonymous');
        return;
      }

      final merged = _deepCopy(state);
      final rowsToSync = <Map<String, dynamic>>[];

      for (final de in anonVotes.entries) {
        merged[de.key] ??= {};
        for (final ae in de.value.entries) {
          merged[de.key]![ae.key] ??= {};
          bool added = false;

          for (final ce in ae.value.entries) {
            if (merged[de.key]![ae.key]![ce.key] == null) {
              merged[de.key]![ae.key]![ce.key] = ce.value;
              added = true;
            }
          }

          if (added) {
            final s = merged[de.key]![ae.key]!;
            rowsToSync.add({
              'user_id': _userId,
              'artist_name': ae.key,
              'date': de.key,
              'canto': _validScore(s['CANTO']),
              'testo': _validScore(s['TESTO']),
              'look': _validScore(s['LOOK']),
              'updated_at': DateTime.now().toIso8601String(),
            });
          }
        }
      }

      if (!mounted) return;

      if (rowsToSync.isNotEmpty) {
        state = merged;
        try {
          await _syncService.batchUpsert(rowsToSync);
          await prefs.remove('votes_anonymous');
          debugPrint('Migrati ${rowsToSync.length} voti anonimi -> account');
        } catch (e) {
          debugPrint('Push anonimi fallito, riprovo al prossimo login: $e');
          // NON cancello votes_anonymous: riprovo al prossimo login
        }
      } else {
        await prefs.remove('votes_anonymous');
      }
    } catch (e) {
      debugPrint('Errore migrazione anonimi: $e');
    }
  }

  // -- Operazioni sui voti --

  Future<void> updateVote(
      String date, String artistName, String category, double score) async {
    final s = _deepCopy(state);
    s[date] ??= {};
    s[date]![artistName] ??= {};
    s[date]![artistName]![category] = score;
    state = s;

    // Cache immediata: sopravvive anche a logout istantaneo
    _saveCache();

    if (_userId != null) {
      final scores = s[date]![artistName]!;
      _syncService.upsertVote(
        userId: _userId,
        artistName: artistName,
        date: date,
        canto: _validScore(scores['CANTO']),
        testo: _validScore(scores['TESTO']),
        look: _validScore(scores['LOOK']),
      );
    }
  }

  Future<void> removeVote(
      String date, String artistName, String category) async {
    final s = _deepCopy(state);
    s[date]?[artistName]?.remove(category);

    if (s[date]?[artistName]?.isEmpty ?? false) {
      s[date]!.remove(artistName);
    }
    if (s[date]?.isEmpty ?? false) {
      s.remove(date);
    }

    state = s;
    _saveCache();

    if (_userId != null) {
      final remaining = s[date]?[artistName] ?? {};
      _syncService.upsertVote(
        userId: _userId,
        artistName: artistName,
        date: date,
        canto: _validScore(remaining['CANTO']),
        testo: _validScore(remaining['TESTO']),
        look: _validScore(remaining['LOOK']),
      );
    }
  }

  Map<String, Map<String, double>> getVotesForDate(String date) =>
      state[date] ?? {};

  Map<String, double>? getArtistVotes(String date, String artistName) =>
      state[date]?[artistName];

  Future<void> forceSync() async {
    if (_userId != null) {
      try {
        final remote = await _syncService.fetchAllVotes(_userId);
        if (!mounted) return;
        state = remote;
        _saveCache();
      } catch (e) {
        debugPrint('Errore forceSync: $e');
      }
    }
  }

  // -- Helpers --

  num? _validScore(double? v) {
    if (v == null) return null;
    if (v < 1 || v > 10) return null;
    final remainder = v % 1;
    if (remainder != 0.0 && remainder != 0.5) return null;
    return v == v.roundToDouble() ? v.toInt() : v;
  }

  Map<String, Map<String, Map<String, double>>> _deepCopy(
      Map<String, Map<String, Map<String, double>>> src) {
    return src.map((k, v) => MapEntry(
        k, v.map((k2, v2) => MapEntry(k2, Map<String, double>.from(v2)))));
  }

  Map<String, Map<String, Map<String, double>>> _parseJson(String raw) {
    final Map<String, dynamic> json = jsonDecode(raw);
    final result = <String, Map<String, Map<String, double>>>{};
    for (final d in json.keys) {
      result[d] = {};
      final dateMap = json[d] as Map<String, dynamic>;
      for (final a in dateMap.keys) {
        result[d]![a] = {};
        final artistMap = dateMap[a] as Map<String, dynamic>;
        for (final c in artistMap.keys) {
          result[d]![a]![c] = (artistMap[c] as num).toDouble();
        }
      }
    }
    return result;
  }
}
