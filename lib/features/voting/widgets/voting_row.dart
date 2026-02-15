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
  bool _syncing = false;

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
    _syncScores(votes);
  }

  /// Sincronizza i controller/scores locali con lo stato del provider.
  /// Il flag _syncing evita che il set di controller.text triggheri
  /// onChanged → updateVote → loop infinito.
  void _syncScores(Map<String, Map<String, Map<String, double>>> votes) {
    final artistVotes = votes[widget.date]?[widget.artistName] ?? {};

    _syncing = true;
    bool changed = false;
    for (final cat in _categories) {
      final score = artistVotes[cat];
      if (_scores[cat] != score) {
        _scores[cat] = score;
        changed = true;
        final newText = score != null ? _scoreToText(score) : '';
        if (_controllers[cat]!.text != newText) {
          _controllers[cat]!.text = newText;
        }
      }
    }
    _syncing = false;

    if (changed) setState(() {});
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
    // Ascolta i cambiamenti del provider (es. caricamento asincrono da cache/Supabase)
    ref.listen(votesProvider, (_, next) => _syncScores(next));

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

  /// 7.0 → "7", 7.5 → "7.5"
  String _scoreToText(double score) {
    return score == score.roundToDouble()
        ? score.toInt().toString()
        : score.toStringAsFixed(1);
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
        child: TextFormField(
              controller: _controllers[category],
              textAlign: TextAlign.center,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                LengthLimitingTextInputFormatter(4),
                TextInputFormatter.withFunction((oldValue, newValue) {
                  if (newValue.text.isEmpty) return newValue;
                  final text = newValue.text.replaceAll(',', '.');

                  // Stato intermedio "X." (l'utente sta per scrivere .5)
                  if (text.endsWith('.')) {
                    if (text.indexOf('.') != text.lastIndexOf('.')) {
                      return oldValue;
                    }
                    final prefix =
                        text.substring(0, text.length - 1);
                    final n = int.tryParse(prefix);
                    if (n == null || n < 1 || n > 9) return oldValue;
                    return newValue;
                  }

                  final value = double.tryParse(text);
                  if (value == null || value < 1 || value > 10) {
                    return oldValue;
                  }

                  // Solo interi o .5
                  final remainder = value % 1;
                  if (remainder != 0.0 && remainder != 0.5) {
                    return oldValue;
                  }

                  return newValue;
                }),
              ],
              style: const TextStyle(
                color: AppColors.blueDark,
                fontSize: 13,
                fontFamily: 'PlusJakartaSans',
                height: 1.0,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
                isDense: true,
              ),
              onChanged: (value) {
                if (_syncing) return;

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
                final parsed = value.replaceAll(',', '.');
                // Ignora stato intermedio "X." (utente sta digitando .5)
                if (parsed.endsWith('.')) return;
                final score = double.tryParse(parsed);
                if (score != null) {
                  HapticFeedback.selectionClick();
                  setState(() => _scores[category] = score);
                  ref.read(votesProvider.notifier).updateVote(
                        widget.date,
                        widget.artistName,
                        category,
                        score,
                      );
                }
              },
            ),
      ),
    );
  }
}
