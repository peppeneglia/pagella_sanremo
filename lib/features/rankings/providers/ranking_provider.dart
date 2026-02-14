import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pagella_sanremo/features/voting/models/artist.dart';
import 'package:pagella_sanremo/features/voting/providers/voting_providers.dart';

enum RankingType {
  total,
  singing,
  text,
  look,
  singingAndText;

  String get label {
    switch (this) {
      case RankingType.total:
        return 'TOTALE';
      case RankingType.singing:
        return 'CANTO';
      case RankingType.text:
        return 'TESTO';
      case RankingType.look:
        return 'LOOK';
      case RankingType.singingAndText:
        return 'CANTO + TESTO';
    }
  }
}

class RankedArtist {
  final int position;
  final Artist artist;
  final double score;
  final Map<String, double> categoryScores;

  const RankedArtist({
    required this.position,
    required this.artist,
    required this.score,
    required this.categoryScores,
  });
}

final rankingProvider =
    Provider.family<List<RankedArtist>, RankingType>((ref, type) {
  final votes = ref.watch(votesProvider);
  final selectedDate = ref.watch(selectedDateProvider);

  final allArtists = selectedDate == 'VEN 27'
      ? coverNightArtists
      : ref.watch(artistsForDateProvider(selectedDate));

  final dateVotes = votes[selectedDate] ?? {};

  final votedArtists = allArtists.where((artist) {
    final artistVotes = dateVotes[artist.name];
    if (artistVotes == null) return false;

    switch (type) {
      case RankingType.total:
        return artistVotes.isNotEmpty;
      case RankingType.singing:
        return artistVotes.containsKey('CANTO');
      case RankingType.text:
        return artistVotes.containsKey('TESTO');
      case RankingType.look:
        return artistVotes.containsKey('LOOK');
      case RankingType.singingAndText:
        return artistVotes.containsKey('CANTO') ||
            artistVotes.containsKey('TESTO');
    }
  }).toList();

  if (votedArtists.isEmpty) return [];

  votedArtists.sort((a, b) {
    final aVotes = Map<String, double>.from(dateVotes[a.name] ?? {});
    final bVotes = Map<String, double>.from(dateVotes[b.name] ?? {});
    return _calculateFinalScore(bVotes, type)
        .compareTo(_calculateFinalScore(aVotes, type));
  });

  return votedArtists.asMap().entries.map((entry) {
    final artistVotes =
        Map<String, double>.from(dateVotes[entry.value.name] ?? {});
    final categoryScores = {
      'CANTO': artistVotes['CANTO'] ?? 0,
      'TESTO': artistVotes['TESTO'] ?? 0,
      'LOOK': artistVotes['LOOK'] ?? 0,
    };

    return RankedArtist(
      position: entry.key + 1,
      artist: entry.value,
      score: _calculateFinalScore(artistVotes, type),
      categoryScores: categoryScores,
    );
  }).toList();
});

double _calculateFinalScore(Map<String, double> votes, RankingType type) {
  switch (type) {
    case RankingType.total:
      final validScores = votes.values.where((score) => score > 0).toList();
      return validScores.isEmpty
          ? 0
          : validScores.reduce((a, b) => a + b) / validScores.length;
    case RankingType.singing:
      return votes['CANTO'] ?? 0;
    case RankingType.text:
      return votes['TESTO'] ?? 0;
    case RankingType.look:
      return votes['LOOK'] ?? 0;
    case RankingType.singingAndText:
      final validScores = [
        if (votes.containsKey('CANTO')) votes['CANTO']!,
        if (votes.containsKey('TESTO')) votes['TESTO']!,
      ].where((score) => score > 0).toList();
      return validScores.isEmpty
          ? 0
          : validScores.reduce((a, b) => a + b) / validScores.length;
  }
}
