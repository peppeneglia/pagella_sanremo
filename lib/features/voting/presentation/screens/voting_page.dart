import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pagella_sanremo/config/theme/app_theme.dart';
import 'package:pagella_sanremo/features/voting/providers/voting_providers.dart';
import 'package:pagella_sanremo/features/voting/widgets/date_button.dart';
import 'package:pagella_sanremo/features/voting/widgets/voting_row.dart';

class VotingPage extends ConsumerWidget {
  const VotingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final artists = ref.watch(artistsForDateProvider(selectedDate));

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
                  onTap: () {
                    FocusScope.of(context).unfocus();
                    ref.read(selectedDateProvider.notifier).state = date;
                  },
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 16),

        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x26355DBF),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: const Row(
                    children: [
                      Expanded(
                        flex: 2,
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
                      Expanded(
                        child: Text(
                          'CANTO',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.blueDark,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            fontFamily: 'PlusJakartaSans',
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'TESTO',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.blueDark,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            fontFamily: 'PlusJakartaSans',
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'LOOK',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.blueDark,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            fontFamily: 'PlusJakartaSans',
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'TOTALE',
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

                Container(
                  height: 1,
                  color: AppColors.blueDark,
                ),

                Expanded(
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
                    child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: artists.length,
                    itemBuilder: (context, index) {
                      final artist = artists[index];
                      return VotingRow(
                        key: ValueKey('${selectedDate}_${artist.name}'),
                        artistName: artist.name,
                        subtitle: artist.song,
                        guest: artist.guest,
                        coverSong: artist.coverSong,
                        date: selectedDate,
                      );
                    },
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
}
