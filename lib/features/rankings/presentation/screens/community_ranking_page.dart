import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pagella_sanremo/config/theme/app_theme.dart';
import 'package:pagella_sanremo/features/auth/providers/auth_providers.dart';
import 'package:pagella_sanremo/features/voting/providers/voting_providers.dart';
import 'package:pagella_sanremo/features/rankings/providers/community_ranking_provider.dart';
import 'package:pagella_sanremo/features/rankings/providers/ranking_provider.dart';
import 'package:pagella_sanremo/features/rankings/services/community_ranking_service.dart';
import 'package:pagella_sanremo/features/voting/widgets/date_button.dart';

const _cardShadow = Color(0x26355DBF);

class CommunityRankingPage extends ConsumerStatefulWidget {
  const CommunityRankingPage({super.key});

  @override
  ConsumerState<CommunityRankingPage> createState() =>
      _CommunityRankingPageState();
}

class _CommunityRankingPageState extends ConsumerState<CommunityRankingPage> {
  Timer? _autoRefreshTimer;
  RankingType _selectedType = RankingType.total;

  @override
  void initState() {
    super.initState();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      ref.invalidate(currentCommunityRankingProvider);
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  double _scoreForType(CommunityRanking r) {
    switch (_selectedType) {
      case RankingType.total:
        return r.avgTotal;
      case RankingType.singing:
        return r.avgCanto;
      case RankingType.text:
        return r.avgTesto;
      case RankingType.look:
        return r.avgLook;
      case RankingType.singingAndText:
        final scores = [
          if (r.avgCanto > 0) r.avgCanto,
          if (r.avgTesto > 0) r.avgTesto,
        ];
        if (scores.isEmpty) return 0;
        return scores.reduce((a, b) => a + b) / scores.length;
    }
  }

  List<CommunityRanking> _sortedRankings(List<CommunityRanking> rankings) {
    final filtered = rankings.where((r) => _scoreForType(r) > 0).toList();
    filtered.sort((a, b) => _scoreForType(b).compareTo(_scoreForType(a)));
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);
    final isAnonymous = ref.watch(anonymousModeProvider);
    final rankingsAsync = ref.watch(currentCommunityRankingProvider);

    if (isAnonymous) {
      return _buildLoginPrompt(context);
    }

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

        const SizedBox(height: 8),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.public, color: AppColors.blueDark, size: 20),
              const SizedBox(width: 8),
              const Text(
                'CLASSIFICA COMMUNITY',
                style: TextStyle(
                  color: AppColors.blueDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  fontFamily: 'PlusJakartaSans',
                ),
              ),
              const Spacer(),
              rankingsAsync.when(
                data: (rankings) {
                  if (rankings.isEmpty) return const SizedBox();
                  final maxVoters = rankings
                      .map((r) => r.totalVoters)
                      .reduce((a, b) => a > b ? a : b);
                  return Text(
                    '$maxVoters ${maxVoters == 1 ? 'voto' : 'voti'}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      fontFamily: 'PlusJakartaSans',
                    ),
                  );
                },
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () =>
                    ref.invalidate(currentCommunityRankingProvider),
                child: Icon(
                  Icons.refresh,
                  color: Colors.grey.shade500,
                  size: 20,
                ),
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
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
                          'ARTISTA',
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
                      ] else if (_selectedType == RankingType.singingAndText) ...[
                        _buildHeaderColumn('CANTO'),
                        _buildHeaderColumn('TESTO'),
                      ],
                      _buildHeaderColumn('MEDIA'),
                    ],
                  ),
                ),

                Expanded(
                  child: rankingsAsync.when(
                    data: (rankings) {
                      if (rankings.isEmpty) {
                        return const Center(
                          child: Text(
                            'Nessun voto per questa serata',
                            style: TextStyle(
                              color: AppColors.blueDark,
                              fontSize: 14,
                              fontFamily: 'PlusJakartaSans',
                            ),
                          ),
                        );
                      }

                      final sorted = _sortedRankings(rankings);

                      return RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(currentCommunityRankingProvider);
                        },
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: sorted.length,
                          itemBuilder: (context, index) {
                            final ranking = sorted[index];
                            return _buildRankingRow(
                              context,
                              position: index + 1,
                              ranking: ranking,
                            );
                          },
                        ),
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.blueDark,
                      ),
                    ),
                    error: (error, stack) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red.shade400,
                            size: 40,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Errore nel caricamento',
                            style: TextStyle(
                              color: Colors.red.shade400,
                              fontFamily: 'PlusJakartaSans',
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              ref.invalidate(currentCommunityRankingProvider);
                            },
                            child: const Text('Riprova'),
                          ),
                        ],
                      ),
                    ),
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

  Widget _buildScoreBox(double score) {
    String displayScore = '-';
    if (score > 0) {
      displayScore = score.toStringAsFixed(1).replaceAll('.', ',');
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

  Widget _buildRankingRow(
    BuildContext context, {
    required int position,
    required CommunityRanking ranking,
  }) {
    return InkWell(
      onTap: () => _showDetailDialog(context, ranking),
      child: Container(
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
                    ranking.artistName,
                    style: TextStyle(
                      color: AppColors.blueDark,
                      fontWeight:
                          position <= 3 ? FontWeight.w700 : FontWeight.w600,
                      fontSize: 13,
                      fontFamily: 'PlusJakartaSans',
                    ),
                  ),
                  Text(
                    '${ranking.totalVoters} ${ranking.totalVoters == 1 ? 'voto' : 'voti'}',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 11,
                      fontFamily: 'PlusJakartaSans',
                    ),
                  ),
                ],
              ),
            ),
            if (_selectedType == RankingType.total) ...[
              _buildScoreBox(ranking.avgCanto),
              _buildScoreBox(ranking.avgTesto),
              _buildScoreBox(ranking.avgLook),
            ] else if (_selectedType == RankingType.singingAndText) ...[
              _buildScoreBox(ranking.avgCanto),
              _buildScoreBox(ranking.avgTesto),
            ],
            _buildScoreBox(_scoreForType(ranking)),
          ],
        ),
      ),
    );
  }

  void _showDetailDialog(BuildContext context, CommunityRanking ranking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          ranking.artistName,
          style: const TextStyle(
            color: AppColors.blueDark,
            fontWeight: FontWeight.w700,
            fontFamily: 'PlusJakartaSans',
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow('Canto', ranking.avgCanto),
            const SizedBox(height: 8),
            _buildDetailRow('Testo', ranking.avgTesto),
            const SizedBox(height: 8),
            _buildDetailRow('Look', ranking.avgLook),
            const Divider(height: 24),
            _buildDetailRow('Media totale', ranking.avgTotal, isTotal: true),
            const SizedBox(height: 16),
            Text(
              'Votato da ${ranking.totalVoters} utenti',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
                fontFamily: 'PlusJakartaSans',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Chiudi',
              style: TextStyle(
                color: AppColors.blueDark,
                fontFamily: 'PlusJakartaSans',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, double score, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isTotal ? AppColors.blueDark : Colors.grey.shade700,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            fontSize: 14,
            fontFamily: 'PlusJakartaSans',
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isTotal ? AppColors.blueDark : AppColors.blueDarkLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            score > 0 ? score.toStringAsFixed(1).replaceAll('.', ',') : '-',
            style: TextStyle(
              color: isTotal ? Colors.white : AppColors.blueDark,
              fontWeight: FontWeight.w700,
              fontSize: 14,
              fontFamily: 'PlusJakartaSans',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'Accedi per vedere la\nclassifica community',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.blueDark,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                fontFamily: 'PlusJakartaSans',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Scopri cosa pensa il pubblico\ne confronta i tuoi voti',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                fontFamily: 'PlusJakartaSans',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                ref.read(anonymousModeProvider.notifier).set(false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blueDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Accedi o registrati',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'PlusJakartaSans',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
