import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pagella_sanremo/features/rankings/providers/ranking_provider.dart';
import 'package:pagella_sanremo/features/voting/providers/voting_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    container = ProviderContainer(
      overrides: [
        // Utente anonimo: i voti restano in memoria/SharedPreferences,
        // nessuna chiamata a Supabase.
        votesProvider.overrideWith((ref) => VotesNotifier()),
      ],
    );
    addTearDown(container.dispose);
    await container.read(votesProvider.notifier).ready;
  });

  Future<void> vote(
    String artist, {
    double? canto,
    double? testo,
    double? look,
  }) async {
    final notifier = container.read(votesProvider.notifier);
    final date = container.read(selectedDateProvider);
    if (canto != null) await notifier.updateVote(date, artist, 'CANTO', canto);
    if (testo != null) await notifier.updateVote(date, artist, 'TESTO', testo);
    if (look != null) await notifier.updateVote(date, artist, 'LOOK', look);
  }

  List<String> names(RankingType type) => container
      .read(rankingProvider(type))
      .map((ranked) => ranked.artist.name)
      .toList();

  test('senza voti la classifica è vuota', () {
    expect(container.read(rankingProvider(RankingType.total)), isEmpty);
  });

  test('ordina per media decrescente e assegna le posizioni', () async {
    await vote('Raf', canto: 6, testo: 6, look: 6);
    await vote('Arisa', canto: 9, testo: 8, look: 10);
    await vote('Levante', canto: 7);

    final ranking = container.read(rankingProvider(RankingType.total));

    expect(names(RankingType.total), ['Arisa', 'Levante', 'Raf']);
    expect(ranking.map((r) => r.position), [1, 2, 3]);
    expect(ranking[0].score, 9);
    expect(ranking[1].score, 7);
    expect(ranking[2].score, 6);
  });

  test('le categorie non votate valgono 0 nei punteggi per categoria',
      () async {
    await vote('Raf', canto: 8);

    final ranked = container.read(rankingProvider(RankingType.total)).single;

    expect(ranked.categoryScores, {'CANTO': 8.0, 'TESTO': 0.0, 'LOOK': 0.0});
  });

  test('la classifica per categoria include solo chi ha quel voto', () async {
    await vote('Raf', canto: 8);
    await vote('Arisa', look: 9);

    expect(names(RankingType.singing), ['Raf']);
    expect(names(RankingType.look), ['Arisa']);
    expect(names(RankingType.text), isEmpty);
  });

  test('CANTO + TESTO fa la media delle sole due categorie', () async {
    await vote('Raf', canto: 8, testo: 6, look: 1);

    final ranked =
        container.read(rankingProvider(RankingType.singingAndText)).single;

    expect(ranked.score, 7);
  });

  test('la classifica segue la serata selezionata', () async {
    await vote('Raf', canto: 8);

    container.read(selectedDateProvider.notifier).state = 'SAB 28';

    expect(names(RankingType.total), isEmpty);
  });

  test('rimuovere un voto aggiorna la classifica', () async {
    await vote('Raf', canto: 8);
    final date = container.read(selectedDateProvider);

    await container
        .read(votesProvider.notifier)
        .removeVote(date, 'Raf', 'CANTO');

    expect(container.read(rankingProvider(RankingType.total)), isEmpty);
  });
}
