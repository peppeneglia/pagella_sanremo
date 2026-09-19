import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pagella_sanremo/features/voting/providers/voting_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const cacheKey = 'votes_anonymous';

  test('carica i voti dalla cache locale', () async {
    SharedPreferences.setMockInitialValues({
      cacheKey: jsonEncode({
        'MAR 24': {
          'Raf': {'CANTO': 7.5},
        },
      }),
    });

    final notifier = VotesNotifier();
    addTearDown(notifier.dispose);
    await notifier.ready;

    expect(notifier.state['MAR 24']?['Raf'], {'CANTO': 7.5});
  });

  test('i voti dati mentre la cache si sta caricando non vengono persi',
      () async {
    SharedPreferences.setMockInitialValues({
      cacheKey: jsonEncode({
        'MAR 24': {
          'Raf': {'CANTO': 5.0, 'LOOK': 6.0},
        },
      }),
    });

    final notifier = VotesNotifier();
    addTearDown(notifier.dispose);

    // Modifiche fatte prima che il caricamento asincrono sia completato.
    await notifier.updateVote('MAR 24', 'Raf', 'TESTO', 8);
    await notifier.removeVote('MAR 24', 'Raf', 'LOOK');
    await notifier.ready;

    expect(notifier.state['MAR 24']?['Raf'], {'CANTO': 5.0, 'TESTO': 8.0});
  });

  test('salva i voti nella cache locale', () async {
    SharedPreferences.setMockInitialValues({});

    final notifier = VotesNotifier();
    addTearDown(notifier.dispose);
    await notifier.ready;

    await notifier.updateVote('MER 25', 'Arisa', 'CANTO', 9);
    // Il salvataggio è fire-and-forget: lascia completare le microtask.
    await Future<void>.delayed(Duration.zero);

    final prefs = await SharedPreferences.getInstance();
    final saved = jsonDecode(prefs.getString(cacheKey)!);

    expect(saved, {
      'MER 25': {
        'Arisa': {'CANTO': 9.0},
      },
    });
  });

  test('rimuovere l\'ultimo voto di un artista elimina anche le mappe vuote',
      () async {
    SharedPreferences.setMockInitialValues({});

    final notifier = VotesNotifier();
    addTearDown(notifier.dispose);
    await notifier.ready;

    await notifier.updateVote('MAR 24', 'Raf', 'CANTO', 7);
    await notifier.removeVote('MAR 24', 'Raf', 'CANTO');

    expect(notifier.state, isEmpty);
  });
}
