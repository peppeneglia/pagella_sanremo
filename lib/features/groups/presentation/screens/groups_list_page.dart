import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pagella_sanremo/config/theme/app_theme.dart';
import 'package:pagella_sanremo/features/auth/providers/auth_providers.dart';
import 'package:pagella_sanremo/features/groups/models/group.dart';
import 'package:pagella_sanremo/features/groups/providers/groups_provider.dart';
import 'package:pagella_sanremo/features/voting/providers/voting_providers.dart';
import 'package:pagella_sanremo/features/voting/widgets/date_button.dart';
import 'package:pagella_sanremo/features/rankings/providers/ranking_provider.dart';
import 'package:pagella_sanremo/features/rankings/services/community_ranking_service.dart';

const _cardShadow = Color(0x26355DBF);
const _inviteBg = Color(0x0D355DBF);
const _inviteBorder = Color(0x33355DBF);

class GroupsListPage extends ConsumerStatefulWidget {
  const GroupsListPage({super.key});

  @override
  ConsumerState<GroupsListPage> createState() => _GroupsListPageState();
}

class _GroupsListPageState extends ConsumerState<GroupsListPage> {
  RankingType _selectedType = RankingType.total;

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
    final isAnonymous = ref.watch(anonymousModeProvider);
    if (isAnonymous) return _buildLoginPrompt(context);

    final groupsAsync = ref.watch(myGroupsProvider);

    return groupsAsync.when(
      data: (groups) {
        if (groups.isEmpty) return _buildEmptyState(context);

        // Auto-select first group if none selected or selected group no longer exists
        final selectedId = ref.watch(selectedGroupIdProvider);
        final validIds = groups.map((g) => g.id).toSet();
        if (selectedId == null || !validIds.contains(selectedId)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(selectedGroupIdProvider.notifier).state = groups.first.id;
          });
          // Show loading while we set the initial group
          if (selectedId == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.blueDark),
            );
          }
        }

        final currentGroup = groups.firstWhere(
          (g) => g.id == selectedId,
          orElse: () => groups.first,
        );

        return _buildGroupRanking(context, currentGroup, groups);
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.blueDark),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade400, size: 40),
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
              onPressed: () => ref.invalidate(myGroupsProvider),
              child: const Text('Riprova'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Ranking view for the selected group ──

  Widget _buildGroupRanking(
      BuildContext context, Group group, List<Group> allGroups) {
    final selectedDate = ref.watch(selectedDateProvider);
    final rankingsAsync = ref.watch(groupRankingsProvider(group.id));

    return Column(
      children: [
        // Date selector
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

        // Header: tappable group name + vote count + refresh
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.leaderboard, color: AppColors.blueDark, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => _showGroupSelector(context, group, allGroups),
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          'CLASSIFICA "${group.name}"',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.blueDark,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            fontFamily: 'PlusJakartaSans',
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.blueDark,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
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
                onTap: () => ref.invalidate(groupRankingsProvider(group.id)),
                child: Icon(
                  Icons.refresh,
                  color: Colors.grey.shade500,
                  size: 20,
                ),
              ),
            ],
          ),
        ),

        // Category filters
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

        // Ranking table
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
                // Table header
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
                      ] else if (_selectedType ==
                          RankingType.singingAndText) ...[
                        _buildHeaderColumn('CANTO'),
                        _buildHeaderColumn('TESTO'),
                      ],
                      _buildHeaderColumn('MEDIA'),
                    ],
                  ),
                ),

                // Artist list
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

                      if (sorted.isEmpty) {
                        return const Center(
                          child: Text(
                            'Nessun voto per questa categoria',
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
                          ref.invalidate(groupRankingsProvider(group.id));
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
                              groupId: group.id,
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
                          Icon(Icons.error_outline,
                              color: Colors.red.shade400, size: 40),
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
                              ref.invalidate(groupRankingsProvider(group.id));
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

  // ── Group selector bottom sheet ──

  void _showGroupSelector(
      BuildContext context, Group currentGroup, List<Group> allGroups) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isOwner = currentUserId == currentGroup.ownerId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              const Text(
                'I MIEI GRUPPI',
                style: TextStyle(
                  color: AppColors.blueDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  fontFamily: 'PlusJakartaSans',
                ),
              ),
              const SizedBox(height: 16),

              // Group list
              ...allGroups.map((g) {
                final isSelected = g.id == currentGroup.id;
                return _buildGroupTile(ctx, g, isSelected);
              }),

              const SizedBox(height: 16),

              // Invite code for current group
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _inviteBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _inviteBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CODICE INVITO — ${currentGroup.name}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'PlusJakartaSans',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentGroup.code,
                            style: const TextStyle(
                              color: AppColors.blueDark,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 4,
                              fontFamily: 'PlusJakartaSans',
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(
                          text:
                              'Unisciti al mio gruppo "${currentGroup.name}" su Pagella Sanremo! Usa il codice: ${currentGroup.code}',
                        ));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Codice e messaggio copiato!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon:
                          const Icon(Icons.copy, color: AppColors.blueDark),
                      tooltip: 'Copia codice',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),

              // Create group
              ListTile(
                leading: const Icon(Icons.add_circle_outline,
                    color: AppColors.blueDark),
                title: const Text(
                  'Crea nuovo gruppo',
                  style: TextStyle(
                    color: AppColors.blueDark,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'PlusJakartaSans',
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showCreateGroupDialog(context);
                },
              ),

              // Join group
              ListTile(
                leading:
                    const Icon(Icons.link, color: AppColors.blueDark),
                title: const Text(
                  'Unisciti con codice',
                  style: TextStyle(
                    color: AppColors.blueDark,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'PlusJakartaSans',
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showJoinGroupDialog(context);
                },
              ),

              const Divider(),

              // Leave group
              ListTile(
                leading:
                    const Icon(Icons.exit_to_app, color: Colors.orange),
                title: const Text(
                  'Lascia gruppo',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'PlusJakartaSans',
                  ),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  final confirm = await _showLeaveDialog(context);
                  if (confirm == true) {
                    final service = ref.read(groupServiceProvider);
                    final success =
                        await service.leaveGroup(currentGroup.id);
                    if (success) {
                      ref.read(selectedGroupIdProvider.notifier).state =
                          null;
                      ref.invalidate(myGroupsProvider);
                    }
                  }
                },
              ),

              // Delete group (owner only)
              if (isOwner)
                ListTile(
                  leading:
                      const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    'Elimina gruppo',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'PlusJakartaSans',
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final confirm =
                        await _showDeleteDialog(context);
                    if (confirm == true) {
                      final service = ref.read(groupServiceProvider);
                      final success =
                          await service.deleteGroup(currentGroup.id);
                      if (success) {
                        ref.read(selectedGroupIdProvider.notifier).state =
                            null;
                        ref.invalidate(myGroupsProvider);
                      }
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupTile(BuildContext ctx, Group group, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.blueDark.withValues(alpha: 0.05)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.blueDark : Colors.grey.shade200,
        ),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.blueDarkLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(group.emoji, style: const TextStyle(fontSize: 20)),
          ),
        ),
        title: Text(
          group.name,
          style: TextStyle(
            color: AppColors.blueDark,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            fontSize: 15,
            fontFamily: 'PlusJakartaSans',
          ),
        ),
        subtitle: Text(
          '${group.memberCount} membri',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
            fontFamily: 'PlusJakartaSans',
          ),
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: AppColors.blueDark)
            : null,
        onTap: () {
          ref.read(selectedGroupIdProvider.notifier).state = group.id;
          Navigator.pop(ctx);
        },
      ),
    );
  }

  // ── Create group dialog ──

  void _showCreateGroupDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    String selectedEmoji = '\u{1F465}';
    bool isLoading = false;

    const emojis = [
      '\u{1F465}', '\u{1F3E0}', '\u{1F355}', '\u{1F4BC}', '\u{1F3B5}',
      '\u26BD', '\u{1F3AE}', '\u2764\uFE0F', '\u{1F31F}', '\u{1F389}',
      '\u{1F3B8}', '\u{1F3A4}', '\u{1F3AF}', '\u{1F3C6}', '\u{1F525}',
      '\u2728', '\u{1F3B6}', '\u{1F3A7}', '\u{1F3B9}', '\u{1F3AC}',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Crea nuovo gruppo',
            style: TextStyle(
              color: AppColors.blueDark,
              fontWeight: FontWeight.w700,
              fontFamily: 'PlusJakartaSans',
            ),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: 'Es. Gruppo Amici',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontWeight: FontWeight.w400,
                      ),
                      labelText: 'Nome del gruppo',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Inserisci un nome';
                      }
                      if (value.trim().length < 3) {
                        return 'Almeno 3 caratteri';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Scegli un\'icona',
                    style: TextStyle(
                      color: AppColors.blueDark,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      fontFamily: 'PlusJakartaSans',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: emojis.map((emoji) {
                      final isEmojiSelected = emoji == selectedEmoji;
                      return GestureDetector(
                        onTap: () =>
                            setDialogState(() => selectedEmoji = emoji),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isEmojiSelected
                                ? AppColors.blueDark.withValues(alpha: 0.1)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isEmojiSelected
                                  ? AppColors.blueDark
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child:
                                Text(emoji, style: const TextStyle(fontSize: 20)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(ctx),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => isLoading = true);
                      final service = ref.read(groupServiceProvider);
                      final group = await service.createGroup(
                        name: nameController.text.trim(),
                        emoji: selectedEmoji,
                      );
                      if (!ctx.mounted) return;
                      if (group != null) {
                        Navigator.pop(ctx);
                        ref.invalidate(myGroupsProvider);
                        ref.read(selectedGroupIdProvider.notifier).state =
                            group.id;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Gruppo "${group.name}" creato!'),
                            backgroundColor: AppColors.blueDark,
                          ),
                        );
                      } else {
                        setDialogState(() => isLoading = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                const Text('Errore nella creazione del gruppo'),
                            backgroundColor: Colors.red.shade400,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blueDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Crea'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Join group dialog ──

  void _showJoinGroupDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final codeController = TextEditingController();
    bool isLoading = false;
    String? errorMessage;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Unisciti a un gruppo',
            style: TextStyle(
              color: AppColors.blueDark,
              fontWeight: FontWeight.w700,
              fontFamily: 'PlusJakartaSans',
            ),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: codeController,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(6),
                  ],
                  decoration: InputDecoration(
                    hintText: 'Es. ABC123',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      letterSpacing: 2,
                    ),
                    labelText: 'Codice invito',
                  ),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 4,
                    fontFamily: 'PlusJakartaSans',
                  ),
                  textAlign: TextAlign.center,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Inserisci il codice';
                    }
                    if (value.trim().length != 6) {
                      return 'Il codice deve essere di 6 caratteri';
                    }
                    return null;
                  },
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline,
                            color: Colors.red.shade700, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            errorMessage!,
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 13,
                              fontFamily: 'PlusJakartaSans',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(ctx),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() {
                        isLoading = true;
                        errorMessage = null;
                      });
                      final service = ref.read(groupServiceProvider);
                      final result = await service
                          .joinGroup(codeController.text.trim());
                      if (!ctx.mounted) return;
                      if (result.group != null) {
                        if (result.alreadyMember) {
                          setDialogState(() {
                            isLoading = false;
                            errorMessage =
                                'Fai già parte di questo gruppo';
                          });
                        } else {
                          Navigator.pop(ctx);
                          ref.invalidate(myGroupsProvider);
                          ref.read(selectedGroupIdProvider.notifier).state =
                              result.group!.id;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('Unito al gruppo "${result.group!.name}"!'),
                              backgroundColor: AppColors.blueDark,
                            ),
                          );
                        }
                      } else {
                        setDialogState(() {
                          isLoading = false;
                          errorMessage =
                              'Codice non valido o gruppo non trovato';
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blueDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Unisciti'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Ranking UI helpers ──

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
    required String groupId,
  }) {
    return InkWell(
      onTap: () => _showArtistDetailSheet(context, ranking, groupId),
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

  void _showArtistDetailSheet(
      BuildContext context, CommunityRanking ranking, String groupId) {
    final selectedDate = ref.read(selectedDateProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Artist name
              Text(
                ranking.artistName,
                style: const TextStyle(
                  color: AppColors.blueDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  fontFamily: 'PlusJakartaSans',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${ranking.totalVoters} ${ranking.totalVoters == 1 ? 'voto' : 'voti'} nel gruppo',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                  fontFamily: 'PlusJakartaSans',
                ),
              ),

              const SizedBox(height: 16),

              // Average scores
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.blueDark.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MEDIA GRUPPO',
                      style: TextStyle(
                        color: AppColors.blueDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        fontFamily: 'PlusJakartaSans',
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow('Canto', ranking.avgCanto),
                    const SizedBox(height: 8),
                    _buildDetailRow('Testo', ranking.avgTesto),
                    const SizedBox(height: 8),
                    _buildDetailRow('Look', ranking.avgLook),
                    const Divider(height: 24),
                    _buildDetailRow('Media totale', ranking.avgTotal,
                        isTotal: true),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Individual votes header
              const Text(
                'VOTI DEI MEMBRI',
                style: TextStyle(
                  color: AppColors.blueDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  fontFamily: 'PlusJakartaSans',
                ),
              ),
              const SizedBox(height: 12),

              // Individual votes list
              Consumer(
                builder: (context, ref, _) {
                  final votesAsync = ref.watch(artistMemberVotesProvider((
                    groupId: groupId,
                    artistName: ranking.artistName,
                    date: selectedDate,
                  )));

                  return votesAsync.when(
                    data: (votes) {
                      if (votes.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'Nessun voto per questo artista',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 14,
                              fontFamily: 'PlusJakartaSans',
                            ),
                          ),
                        );
                      }

                      votes.sort((a, b) {
                        final aAvg = a.average ?? 0;
                        final bAvg = b.average ?? 0;
                        return bAvg.compareTo(aAvg);
                      });

                      return Column(
                        children: votes
                            .map((vote) => _buildMemberVoteRow(vote))
                            .toList(),
                      );
                    },
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.blueDark,
                        ),
                      ),
                    ),
                    error: (_, __) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Errore nel caricamento dei voti',
                        style: TextStyle(
                          color: Colors.red.shade400,
                          fontSize: 14,
                          fontFamily: 'PlusJakartaSans',
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemberVoteRow(MemberArtistVote vote) {
    String formatScore(double? score) {
      if (score == null) return '-';
      return score.toStringAsFixed(1).replaceAll('.', ',');
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.blueDarkLight,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Text(
                vote.username.isNotEmpty
                    ? vote.username[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: AppColors.blueDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  fontFamily: 'PlusJakartaSans',
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Username
          Expanded(
            child: Text(
              vote.username,
              style: const TextStyle(
                color: AppColors.blueDark,
                fontWeight: FontWeight.w600,
                fontSize: 14,
                fontFamily: 'PlusJakartaSans',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Scores
          _buildMiniScore('C', vote.canto),
          const SizedBox(width: 6),
          _buildMiniScore('T', vote.testo),
          const SizedBox(width: 6),
          _buildMiniScore('L', vote.look),
          const SizedBox(width: 8),
          // Average
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.blueDark,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              formatScore(vote.average),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
                fontFamily: 'PlusJakartaSans',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniScore(String label, double? score) {
    final text = score != null
        ? score.toStringAsFixed(1).replaceAll('.', ',')
        : '-';
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            fontFamily: 'PlusJakartaSans',
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: 36,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.blueDarkLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.blueDark,
              fontWeight: FontWeight.w600,
              fontSize: 11,
              fontFamily: 'PlusJakartaSans',
            ),
          ),
        ),
      ],
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

  // ── Confirmation dialogs ──

  Future<bool?> _showLeaveDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Lasciare il gruppo?'),
        content: const Text('Potrai unirti di nuovo con il codice invito.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Lascia'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showDeleteDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Eliminare il gruppo?'),
        content: const Text(
          'Questa azione è irreversibile. Tutti i membri verranno rimossi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
  }

  // ── Empty & login states ──

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.groups_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Nessun gruppo',
              style: TextStyle(
                color: AppColors.blueDark,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                fontFamily: 'PlusJakartaSans',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea un gruppo per confrontare\ni tuoi voti con gli amici',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                fontFamily: 'PlusJakartaSans',
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showCreateGroupDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Crea nuovo gruppo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blueDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showJoinGroupDialog(context),
                icon: const Icon(Icons.link),
                label: const Text('Unisciti con codice'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.blueDark,
                  side: const BorderSide(color: AppColors.blueDark),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Accedi per creare\no unirti a gruppi',
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
              'Confronta i tuoi voti\ncon gli amici',
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Accedi o registrati',
                style: TextStyle(fontSize: 16, fontFamily: 'PlusJakartaSans'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
