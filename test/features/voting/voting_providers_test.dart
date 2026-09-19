import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pagella_sanremo/features/voting/data/artists_data.dart';
import 'package:pagella_sanremo/features/voting/providers/voting_providers.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
  });

  test('le serate sono cinque e la serata cover è tra queste', () {
    expect(dates, hasLength(5));
    expect(dates.toSet(), hasLength(5));
    expect(dates, contains(coverNightDate));
  });

  test('la serata selezionata di default è la prima', () {
    expect(container.read(selectedDateProvider), dates.first);
  });

  group('artistsForDateProvider', () {
    test('prima serata e finale hanno tutti gli artisti', () {
      expect(container.read(artistsForDateProvider('MAR 24')), artists);
      expect(container.read(artistsForDateProvider('SAB 28')), artists);
    });

    test('seconda e terza serata si dividono gli artisti a metà', () {
      final second = container.read(artistsForDateProvider('MER 25'));
      final third = container.read(artistsForDateProvider('GIO 26'));

      expect(second, hasLength(15));
      expect(third, hasLength(15));
      expect([...second, ...third], artists);
    });

    test('la serata cover usa la lista con ospiti', () {
      expect(
        container.read(artistsForDateProvider(coverNightDate)),
        coverNightArtists,
      );
    });

    test('una data sconosciuta restituisce una lista vuota', () {
      expect(container.read(artistsForDateProvider('DOM 29')), isEmpty);
    });
  });
}
