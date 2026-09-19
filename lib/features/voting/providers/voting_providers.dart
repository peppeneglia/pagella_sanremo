import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pagella_sanremo/features/voting/data/artists_data.dart';
import 'package:pagella_sanremo/features/voting/models/artist.dart';
import 'package:pagella_sanremo/features/voting/services/vote_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Le cinque serate del Festival, nell'ordine in cui vengono mostrate.
const dates = [
  'MAR 24',
  'MER 25',
  'GIO 26',
  'VEN 27',
  'SAB 28',
];

/// Serata cover: gli artisti si esibiscono con un ospite su un brano diverso.
const coverNightDate = 'VEN 27';

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
    case coverNightDate:
      return coverNightArtists;
    case 'SAB 28':
      return artists;
    default:
      return [];
  }
});

/// Voti dell'utente: `{ serata: { artista: { categoria: voto } } }`.
typedef VotesMap = Map<String, Map<String, Map<String, double>>>;

/// Account loggato: Supabase è fonte primaria, cache locale di backup.
/// Anonimo: solo SharedPreferences.
///
/// Al login: cache locale (istantanea) + fetch Supabase + merge.
/// La cache copre il gap se un upsert era ancora in-flight al logout.
final votesProvider = StateNotifierProvider<VotesNotifier, VotesMap>((ref) {
  final user = Supabase.instance.client.auth.currentUser;
  return VotesNotifier(userId: user?.id);
});

class VotesNotifier extends StateNotifier<VotesMap> {
  final VoteSyncService _syncService = VoteSyncService();
  final String? _userId;

  /// Completa quando cache locale (e voti remoti, se loggato) sono caricati.
  late final Future<void> ready;

  bool _initializing = true;

  /// Modifiche fatte dall'utente mentre [_init] era in corso.
  /// Vengono riapplicate sopra i dati caricati in modo asincrono, altrimenti
  /// il caricamento le sovrascriverebbe con uno snapshot precedente.
  /// Valore `null` = voto rimosso.
  final _pendingEdits =
      <(String date, String artist, String category), double?>{};

  VotesNotifier({String? userId})
      : _userId = userId,
        super({}) {
    ready = _init();
  }

  String get _cacheKey => 'votes_${_userId ?? "anonymous"}';

  Future<void> _init() async {
    try {
      if (_userId != null) {
        await _initLoggedIn(_userId);
      } else {
        await _loadCache();
      }
    } finally {
      _initializing = false;
      if (_pendingEdits.isNotEmpty) {
        _pendingEdits.clear();
        // Durante l'init i salvataggi sono sospesi: persiste ora lo stato
        // completo (dati caricati + modifiche fatte nel frattempo).
        _saveCache();
      }
    }
  }

  Future<void> _initLoggedIn(String userId) async {
    // 1. Carica cache locale (istantaneo, sopravvive a logout rapidi)
    await _loadCache();
    final cached = _deepCopy(state);

    // 2. Fetch da Supabase (fonte primaria)
    try {
      final remote = await _syncService.fetchAllVotes(userId);
      if (!mounted) return;

      // 3. Merge: Supabase vince, cache riempie i gap
      //    (gap = voti salvati in cache ma il cui upsert non era ancora arrivato)
      final merged = _deepCopy(remote);
      final toSyncKeys = <(String date, String artist)>{};

      for (final de in cached.entries) {
        for (final ae in de.value.entries) {
          for (final ce in ae.value.entries) {
            if (merged[de.key]?[ae.key]?[ce.key] == null) {
              _put(merged, de.key, ae.key, ce.key, ce.value);
              toSyncKeys.add((de.key, ae.key));
            }
          }
        }
      }

      state = _withPendingEdits(merged);

      final toSync = [
        for (final (date, artist) in toSyncKeys)
          if (state[date]?[artist] case final scores?)
            _buildRow(userId, artist, date, scores),
      ];

      if (toSync.isNotEmpty) {
        unawaited(_syncService.batchUpsert(toSync));
        debugPrint('Push ${toSync.length} voti dalla cache a Supabase');
      }

      debugPrint('Voti caricati: ${remote.length} da Supabase'
          '${toSync.isNotEmpty ? " + ${toSync.length} dalla cache" : ""}');
    } catch (e) {
      debugPrint('Supabase non raggiungibile, uso cache: $e');
      // state già caricato dalla cache al punto 1
    }

    // 4. Migra eventuali voti anonimi nell'account
    await _migrateAnonymousVotes(userId);
    _saveCache();
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
        state = _withPendingEdits(_parseJson(data));
      }
    } catch (e) {
      debugPrint('Errore caricamento cache: $e');
    }
  }

  /// Salva cache immediatamente. Fire-and-forget: SharedPreferences
  /// aggiorna la cache in-memoria in modo sincrono, quindi è subito
  /// disponibile anche se il write su disco è ancora in corso.
  void _saveCache() {
    final snapshot = jsonEncode(state);
    unawaited(SharedPreferences.getInstance().then((prefs) {
      prefs.setString(_cacheKey, snapshot);
    }));
  }

  // -- Migrazione anonimo -> account --

  Future<void> _migrateAnonymousVotes(String userId) async {
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
        for (final ae in de.value.entries) {
          var added = false;

          for (final ce in ae.value.entries) {
            if (merged[de.key]?[ae.key]?[ce.key] == null) {
              _put(merged, de.key, ae.key, ce.key, ce.value);
              added = true;
            }
          }

          if (added) {
            rowsToSync.add(
              _buildRow(userId, ae.key, de.key, merged[de.key]![ae.key]!),
            );
          }
        }
      }

      if (!mounted) return;

      if (rowsToSync.isNotEmpty) {
        state = _withPendingEdits(merged);
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
    _put(s, date, artistName, category, score);
    state = s;
    _persist((date, artistName, category), score);

    if (_userId != null) {
      unawaited(_syncService.upsertVote(
        userId: _userId,
        artistName: artistName,
        date: date,
        canto: _validScore(s[date]![artistName]!['CANTO']),
        testo: _validScore(s[date]![artistName]!['TESTO']),
        look: _validScore(s[date]![artistName]!['LOOK']),
      ));
    }
  }

  Future<void> removeVote(
      String date, String artistName, String category) async {
    final s = _deepCopy(state);
    _drop(s, date, artistName, category);
    state = s;
    _persist((date, artistName, category), null);

    if (_userId != null) {
      final remaining = s[date]?[artistName] ?? {};
      unawaited(_syncService.upsertVote(
        userId: _userId,
        artistName: artistName,
        date: date,
        canto: _validScore(remaining['CANTO']),
        testo: _validScore(remaining['TESTO']),
        look: _validScore(remaining['LOOK']),
      ));
    }
  }

  // -- Helpers --

  /// Cache immediata (sopravvive anche a un logout istantaneo).
  /// Durante l'init la modifica viene solo annotata: salvare ora scriverebbe
  /// su disco uno stato parziale, senza i dati ancora in caricamento.
  void _persist((String, String, String) key, double? score) {
    if (_initializing) {
      _pendingEdits[key] = score;
    } else {
      _saveCache();
    }
  }

  /// Riapplica su [votes] le modifiche fatte durante l'inizializzazione.
  VotesMap _withPendingEdits(VotesMap votes) {
    for (final entry in _pendingEdits.entries) {
      final (date, artist, category) = entry.key;
      final score = entry.value;
      if (score != null) {
        _put(votes, date, artist, category, score);
      } else {
        _drop(votes, date, artist, category);
      }
    }
    return votes;
  }

  static void _put(VotesMap votes, String date, String artist, String category,
      double score) {
    final artistVotes = (votes[date] ??= {})[artist] ??= {};
    artistVotes[category] = score;
  }

  /// Rimuove il voto e ripulisce le mappe rimaste vuote.
  static void _drop(
      VotesMap votes, String date, String artist, String category) {
    final artistVotes = votes[date]?[artist];
    if (artistVotes == null) return;
    artistVotes.remove(category);
    if (artistVotes.isEmpty) votes[date]!.remove(artist);
    if (votes[date]!.isEmpty) votes.remove(date);
  }

  Map<String, dynamic> _buildRow(
      String userId, String artist, String date, Map<String, double> scores) {
    return {
      'user_id': userId,
      'artist_name': artist,
      'date': date,
      'canto': _validScore(scores['CANTO']),
      'testo': _validScore(scores['TESTO']),
      'look': _validScore(scores['LOOK']),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  num? _validScore(double? v) {
    if (v == null) return null;
    if (v < 1 || v > 10) return null;
    final remainder = v % 1;
    if (remainder != 0.0 && remainder != 0.5) return null;
    return v == v.roundToDouble() ? v.toInt() : v;
  }

  VotesMap _deepCopy(VotesMap src) {
    return src.map((k, v) => MapEntry(
        k, v.map((k2, v2) => MapEntry(k2, Map<String, double>.from(v2)))));
  }

  VotesMap _parseJson(String raw) {
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
