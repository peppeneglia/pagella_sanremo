import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pagella_sanremo/config/theme/app_theme.dart';
import 'package:pagella_sanremo/features/voting/providers/voting_providers.dart';
import 'package:pagella_sanremo/features/rankings/providers/ranking_provider.dart';
import 'package:pagella_sanremo/features/voting/widgets/date_button.dart';

const _cardShadow = Color(0x26355DBF);

class PersonalRankingPage extends ConsumerStatefulWidget {
  const PersonalRankingPage({super.key});

  @override
  ConsumerState<PersonalRankingPage> createState() =>
      _PersonalRankingPageState();
}

class _PersonalRankingPageState extends ConsumerState<PersonalRankingPage> {
  RankingType _selectedType = RankingType.total;

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);
    final rankedArtists = ref.watch(rankingProvider(_selectedType));

    return Column(
      children: [
        SizedBox(
          height: 40,
          child: Row(
            children: dates.map((date) {
              return Expanded(
                child: DateButton(
                  date: date,
                  isSelected: date == selectedDate,
                  onTap: () =>
                      ref.read(selectedDateProvider.notifier).state = date,
                ),
              );
            }).toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: RankingType.values
                  .map((type) => _buildTypeButton(type))
                  .toList(),
            ),
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: _cardShadow,
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.blueDark,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 24),
                      const Expanded(
                        flex: 3,
                        child: Text(
                          'ARTISTI',
                          style: TextStyle(
                            color: AppColors.blueDark,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            fontFamily: 'PlusJakartaSans',
                          ),
                        ),
                      ),
                      if (_selectedType == RankingType.total) ...[
                        _buildHeaderColumn('CANTO'),
                        _buildHeaderColumn('TESTO'),
                        _buildHeaderColumn('LOOK'),
                      ] else if (_selectedType ==
                          RankingType.singingAndText) ...[
                        _buildHeaderColumn('CANTO'),
                        _buildHeaderColumn('TESTO'),
                      ],
                      _buildHeaderColumn(_selectedType == RankingType.total
                          ? 'MEDIA'
                          : 'VOTO'),
                    ],
                  ),
                ),
                Expanded(
                  child: rankedArtists.isEmpty
                      ? const Center(
                          child: Text(
                            'Nessun voto per questa serata',
                            style: TextStyle(
                              color: AppColors.blueDark,
                              fontSize: 14,
                              fontFamily: 'PlusJakartaSans',
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: rankedArtists.length,
                          itemBuilder: (context, index) {
                            final ranked = rankedArtists[index];
                            return _buildRankingRow(
                              position: ranked.position,
                              artistName: ranked.artist.name,
                              artistSong: ranked.artist.song,
                              votes: ranked.categoryScores,
                              score: ranked.score,
                              showAllScores: _selectedType == RankingType.total,
                              showSingingAndText:
                                  _selectedType == RankingType.singingAndText,
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTypeButton(RankingType type) {
    final isSelected = type == _selectedType;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: ElevatedButton(
        onPressed: () => setState(() => _selectedType = type),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? AppColors.blueDark : Colors.white,
          foregroundColor: isSelected ? Colors.white : AppColors.blueDark,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isSelected ? AppColors.blueDark : Colors.grey.shade300,
            ),
          ),
        ),
        child: Text(
          type.label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            fontFamily: 'PlusJakartaSans',
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderColumn(String text) {
    return SizedBox(
      width: 50,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.blueDark,
          fontWeight: FontWeight.w600,
          fontSize: 13,
          fontFamily: 'PlusJakartaSans',
        ),
      ),
    );
  }

  Widget _buildScoreBox(double? score) {
    String displayScore = '-';
    if (score != null && score > 0) {
      displayScore = score == score.roundToDouble()
          ? score.toInt().toString()
          : score.toStringAsFixed(1).replaceAll('.', ',');
    }

    return Container(
      width: 50,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.blueDarkLight,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        displayScore,
        style: const TextStyle(
          color: AppColors.blueDark,
          fontWeight: FontWeight.w700,
          fontSize: 13,
          fontFamily: 'PlusJakartaSans',
        ),
      ),
    );
  }

  Widget _buildRankingRow({
    required int position,
    required String artistName,
    required String artistSong,
    required Map<String, double> votes,
    required double score,
    required bool showAllScores,
    required bool showSingingAndText,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: position <= 3
                ? Text(
                    position == 1
                        ? '\u{1F947}'
                        : position == 2
                            ? '\u{1F948}'
                            : '\u{1F949}',
                    style: const TextStyle(fontSize: 16, height: 1),
                  )
                : Text(
                    position.toString(),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      fontFamily: 'PlusJakartaSans',
                    ),
                  ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  artistName,
                  style: const TextStyle(
                    color: AppColors.blueDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    fontFamily: 'PlusJakartaSans',
                  ),
                ),
                Text(
                  artistSong,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                    fontFamily: 'PlusJakartaSans',
                  ),
                ),
              ],
            ),
          ),
          if (showAllScores) ...[
            _buildScoreBox(votes['CANTO']),
            _buildScoreBox(votes['TESTO']),
            _buildScoreBox(votes['LOOK']),
            _buildScoreBox(score),
          ] else if (showSingingAndText) ...[
            _buildScoreBox(votes['CANTO']),
            _buildScoreBox(votes['TESTO']),
            _buildScoreBox(score),
          ] else
            _buildScoreBox(score),
        ],
      ),
    );
  }
}
