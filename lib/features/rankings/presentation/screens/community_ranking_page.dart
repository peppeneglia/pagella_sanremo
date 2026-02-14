import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pagella_sanremo/config/theme/app_theme.dart';
import 'package:pagella_sanremo/features/auth/providers/auth_providers.dart';
import 'package:pagella_sanremo/features/voting/providers/voting_providers.dart';
import 'package:pagella_sanremo/features/rankings/providers/community_ranking_provider.dart';
import 'package:pagella_sanremo/features/rankings/services/community_ranking_service.dart';
import 'package:pagella_sanremo/features/voting/widgets/date_button.dart';

const _cardShadow = Color(0x26355DBF);

class CommunityRankingPage extends ConsumerWidget {
  const CommunityRankingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final isAnonymous = ref.watch(anonymousModeProvider);
    final rankingsAsync = ref.watch(currentCommunityRankingProvider);

    if (isAnonymous) {
      return _buildLoginPrompt(context, ref);
    }

    return Column(
      children: [
        SizedBox(
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: dates.map((date) {
              return DateButton(
                date: date,
                isSelected: date == selectedDate,
                onTap: () =>
                    ref.read(selectedDateProvider.notifier).state = date,
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 16),

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
                    '$maxVoters voti',
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
            ],
          ),
        ),

        const SizedBox(height: 12),

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
                  child: const Row(
                    children: [
                      SizedBox(width: 32),
                      Expanded(
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
                      SizedBox(
                        width: 50,
                        child: Text(
                          'MEDIA',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.blueDark,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            fontFamily: 'PlusJakartaSans',
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 50,
                        child: Text(
                          'VOTI',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.blueDark,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            fontFamily: 'PlusJakartaSans',
                          ),
                        ),
                      ),
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

                      return RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(currentCommunityRankingProvider);
                        },
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: rankings.length,
                          itemBuilder: (context, index) {
                            final ranking = rankings[index];
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
              width: 32,
              child: position <= 3
                  ? Text(
                      position == 1
                          ? '🥇'
                          : position == 2
                              ? '🥈'
                              : '🥉',
                      style: const TextStyle(fontSize: 18),
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
              child: Text(
                ranking.artistName,
                style: TextStyle(
                  color: AppColors.blueDark,
                  fontWeight: position <= 3 ? FontWeight.w700 : FontWeight.w600,
                  fontSize: 13,
                  fontFamily: 'PlusJakartaSans',
                ),
              ),
            ),
            Container(
              width: 50,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.blueDarkLight,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                ranking.avgTotal > 0
                    ? ranking.avgTotal.toStringAsFixed(1).replaceAll('.', ',')
                    : '-',
                style: const TextStyle(
                  color: AppColors.blueDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  fontFamily: 'PlusJakartaSans',
                ),
              ),
            ),
            SizedBox(
              width: 50,
              child: Text(
                ranking.totalVoters.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontFamily: 'PlusJakartaSans',
                ),
              ),
            ),
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
            _buildScoreRow('Canto', ranking.avgCanto),
            const SizedBox(height: 8),
            _buildScoreRow('Testo', ranking.avgTesto),
            const SizedBox(height: 8),
            _buildScoreRow('Look', ranking.avgLook),
            const Divider(height: 24),
            _buildScoreRow('Media totale', ranking.avgTotal, isTotal: true),
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

  Widget _buildScoreRow(String label, double score, {bool isTotal = false}) {
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

  Widget _buildLoginPrompt(BuildContext context, WidgetRef ref) {
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
