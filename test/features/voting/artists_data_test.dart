import 'package:flutter_test/flutter_test.dart';
import 'package:pagella_sanremo/features/voting/data/artists_data.dart';

void main() {
  group('artists', () {
    test('sono 30 con nomi univoci', () {
      expect(artists, hasLength(30));
      expect(artists.map((a) => a.name).toSet(), hasLength(30));
    });

    test('ogni artista ha nome e brano non vuoti', () {
      for (final artist in artists) {
        expect(artist.name, isNotEmpty);
        expect(artist.song, isNotEmpty, reason: artist.name);
      }
    });
  });

  group('coverNightArtists', () {
    test('contiene gli stessi artisti della gara, nello stesso ordine', () {
      expect(
        coverNightArtists.map((a) => a.name).toList(),
        artists.map((a) => a.name).toList(),
      );
    });

    test('ogni artista ha ospite e brano cover', () {
      for (final artist in coverNightArtists) {
        expect(artist.guest, isNotEmpty, reason: artist.name);
        expect(artist.coverSong, isNotEmpty, reason: artist.name);
      }
    });
  });
}
