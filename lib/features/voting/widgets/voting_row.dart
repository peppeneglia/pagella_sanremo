import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pagella_sanremo/config/theme/app_theme.dart';
import 'package:pagella_sanremo/features/voting/providers/voting_providers.dart';

// Colori precalcolati per evitare withOpacity() nel build
const _blueLightBorder = Color(0x4D1F64E5);
const _blueDarkBg = Color(0x1A355DBF);
const _blueDarkText80 = Color(0xCC355DBF);

class VotingRow extends ConsumerStatefulWidget {
  final String artistName;
  final String subtitle;
  final String? guest;
  final String? coverSong;
  final String date;

  const VotingRow({
    super.key,
    required this.artistName,
    required this.subtitle,
    this.guest,
    this.coverSong,
    required this.date,
  });

  @override
  ConsumerState<VotingRow> createState() => _VotingRowState();
}

class _VotingRowState extends ConsumerState<VotingRow> {
  final _controllers = <String, TextEditingController>{};
  final _scores = <String, double?>{};
  static const _categories = ['CANTO', 'TESTO', 'LOOK'];

  @override
  void initState() {
    super.initState();
    for (final cat in _categories) {
      _controllers[cat] = TextEditingController();
      _scores[cat] = null;
    }
    _loadVotes();
  }

  @override
  void didUpdateWidget(covariant VotingRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.date != widget.date ||
        oldWidget.artistName != widget.artistName) {
      _loadVotes();
    }
  }

  void _loadVotes() {
    final votes = ref.read(votesProvider);
    final artistVotes = votes[widget.date]?[widget.artistName] ?? {};

    for (final cat in _categories) {
      final score = artistVotes[cat];
      _controllers[cat]!.text = score != null ? score.round().toString() : '';
      _scores[cat] = score;
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCoverNight = widget.date == 'VEN 27';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.artistName,
                  style: const TextStyle(
                    color: AppColors.blueDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    fontFamily: 'PlusJakartaSans',
                  ),
                ),
                if (isCoverNight && widget.guest != null) ...[
                  Text(
                    'con ${widget.guest}',
                    style: const TextStyle(
                      color: _blueDarkText80,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'PlusJakartaSans',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.coverSong ?? '',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      fontFamily: 'PlusJakartaSans',
                    ),
                  ),
                ] else
                  Text(
                    widget.subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 11,
                      fontFamily: 'PlusJakartaSans',
                    ),
                  ),
              ],
            ),
          ),

          ..._categories.map(_buildVoteField),

          Expanded(
            child: Container(
              height: 36,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _blueDarkBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _blueLightBorder),
              ),
              child: Text(
                _calculateTotal(),
                style: const TextStyle(
                  color: AppColors.blueDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'PlusJakartaSans',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _calculateTotal() {
    final validScores = _scores.values.whereType<double>().toList();
    if (validScores.isEmpty) return '-';

    final sum = validScores.reduce((a, b) => a + b);
    final average = sum / validScores.length;

    return average == average.roundToDouble()
        ? average.toInt().toString()
        : average.toStringAsFixed(1).replaceAll('.', ',');
  }

  Widget _buildVoteField(String category) {
    return Expanded(
      child: Container(
        height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _blueLightBorder),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: IntrinsicWidth(
            child: TextFormField(
              controller: _controllers[category],
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(2),
                TextInputFormatter.withFunction((oldValue, newValue) {
                  if (newValue.text.isEmpty) return newValue;
                  final value = int.tryParse(newValue.text);
                  if (value == null || value > 10) return oldValue;
                  return newValue;
                }),
              ],
              style: const TextStyle(
                color: AppColors.blueDark,
                fontSize: 13,
                fontFamily: 'PlusJakartaSans',
                height: 1.0,
              ),
              // Bordi gestiti dal Container esterno
              decoration: const InputDecoration(
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
                isCollapsed: true,
              ),
              onChanged: (value) {
                if (value.isEmpty) {
                  HapticFeedback.lightImpact();
                  setState(() => _scores[category] = null);
                  ref.read(votesProvider.notifier).removeVote(
                        widget.date,
                        widget.artistName,
                        category,
                      );
                  return;
                }
                final score = int.tryParse(value);
                if (score != null) {
                  HapticFeedback.selectionClick();
                  setState(() => _scores[category] = score.toDouble());
                  ref.read(votesProvider.notifier).updateVote(
                        widget.date,
                        widget.artistName,
                        category,
                        score.toDouble(),
                      );
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}
