import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pagella_sanremo/config/theme/app_theme.dart';
import 'package:pagella_sanremo/features/groups/models/group.dart';
import 'package:pagella_sanremo/features/groups/providers/groups_provider.dart';

const _inviteBg = Color(0x0D355DBF);
const _inviteBorder = Color(0x33355DBF);
const _memberHighlightBg = Color(0x0D355DBF);
const _memberHighlightBorder = Color(0x4D355DBF);

class GroupDetailPage extends ConsumerWidget {
  final Group group;

  const GroupDetailPage({super.key, required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(groupMembersProvider(group.id));
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isOwner = currentUserId == group.ownerId;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(group.emoji),
            const SizedBox(width: 8),
            Flexible(child: Text(group.name, overflow: TextOverflow.ellipsis)),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.blueDark,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'leave') {
                final confirm = await _showLeaveDialog(context);
                if (confirm == true) {
                  final service = ref.read(groupServiceProvider);
                  final success = await service.leaveGroup(group.id);
                  if (success && context.mounted) {
                    ref.invalidate(myGroupsProvider);
                    Navigator.pop(context);
                  }
                }
              } else if (value == 'delete') {
                final confirm = await _showDeleteDialog(context);
                if (confirm == true) {
                  final service = ref.read(groupServiceProvider);
                  final success = await service.deleteGroup(group.id);
                  if (success && context.mounted) {
                    ref.invalidate(myGroupsProvider);
                    Navigator.pop(context);
                  }
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'leave',
                child: Row(
                  children: [
                    Icon(Icons.exit_to_app, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Lascia gruppo'),
                  ],
                ),
              ),
              if (isOwner)
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Elimina gruppo'),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
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
                        'CODICE INVITO',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'PlusJakartaSans',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        group.code,
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
                          'Unisciti al mio gruppo "${group.name}" su Pagella Sanremo! Usa il codice: ${group.code}',
                    ));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Codice e messaggio copiato!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy, color: AppColors.blueDark),
                  tooltip: 'Copia codice',
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.leaderboard, color: AppColors.blueDark, size: 20),
                SizedBox(width: 8),
                Text(
                  'CLASSIFICA MEMBRI',
                  style: TextStyle(
                    color: AppColors.blueDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    fontFamily: 'PlusJakartaSans',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: membersAsync.when(
              data: (members) {
                if (members.isEmpty) {
                  return const Center(
                    child: Text('Nessun membro nel gruppo'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(groupMembersProvider(group.id));
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      final member = members[index];
                      final isCurrentUser = member.userId == currentUserId;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              isCurrentUser ? _memberHighlightBg : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isCurrentUser
                                ? _memberHighlightBorder
                                : Colors.grey.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 32,
                              child: index < 3
                                  ? Text(
                                      index == 0
                                          ? '🥇'
                                          : index == 1
                                              ? '🥈'
                                              : '🥉',
                                      style: const TextStyle(fontSize: 20),
                                    )
                                  : Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'PlusJakartaSans',
                                      ),
                                    ),
                            ),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          member.username,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: AppColors.blueDark,
                                            fontWeight: isCurrentUser
                                                ? FontWeight.w700
                                                : FontWeight.w600,
                                            fontSize: 14,
                                            fontFamily: 'PlusJakartaSans',
                                          ),
                                        ),
                                      ),
                                      if (isCurrentUser) ...[
                                        const SizedBox(width: 4),
                                        Text(
                                          '(Tu)',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 12,
                                            fontFamily: 'PlusJakartaSans',
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  Text(
                                    '${member.totalVotes} voti',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                      fontFamily: 'PlusJakartaSans',
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.blueDarkLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                member.averageScore != null
                                    ? member.averageScore!
                                        .toStringAsFixed(1)
                                        .replaceAll('.', ',')
                                    : '-',
                                style: const TextStyle(
                                  color: AppColors.blueDark,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  fontFamily: 'PlusJakartaSans',
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },

              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.blueDark),
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
                        ref.invalidate(groupMembersProvider(group.id));
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
    );
  }

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
}
