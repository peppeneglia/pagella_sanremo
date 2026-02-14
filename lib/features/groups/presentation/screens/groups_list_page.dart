import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pagella_sanremo/config/theme/app_theme.dart';
import 'package:pagella_sanremo/features/auth/providers/auth_providers.dart';
import 'package:pagella_sanremo/features/groups/models/group.dart';
import 'package:pagella_sanremo/features/groups/providers/groups_provider.dart';
import 'package:pagella_sanremo/features/groups/presentation/screens/create_group_page.dart';
import 'package:pagella_sanremo/features/groups/presentation/screens/join_group_page.dart';
import 'package:pagella_sanremo/features/groups/presentation/screens/group_detail_page.dart';

class GroupsListPage extends ConsumerWidget {
  const GroupsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAnonymous = ref.watch(anonymousModeProvider);
    final groupsAsync = ref.watch(myGroupsProvider);

    if (isAnonymous) {
      return _buildLoginPrompt(context, ref);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.groups, color: AppColors.blueDark, size: 24),
              const SizedBox(width: 8),
              const Text(
                'I MIEI GRUPPI',
                style: TextStyle(
                  color: AppColors.blueDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  fontFamily: 'PlusJakartaSans',
                ),
              ),
              const Spacer(),
              groupsAsync.when(
                data: (groups) => Text(
                  '${groups.length} gruppi',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontFamily: 'PlusJakartaSans',
                  ),
                ),
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
              ),
            ],
          ),
        ),

        Expanded(
          child: groupsAsync.when(
            data: (groups) {
              if (groups.isEmpty) return _buildEmptyState(context);

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(myGroupsProvider);
                },
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    return _buildGroupCard(context, ref, groups[index]);
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
                    onPressed: () => ref.invalidate(myGroupsProvider),
                    child: const Text('Riprova'),
                  ),
                ],
              ),
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CreateGroupPage()),
                    );
                    if (result == true) ref.invalidate(myGroupsProvider);
                  },
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
                  onPressed: () async {
                    final result = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(builder: (_) => const JoinGroupPage()),
                    );
                    if (result == true) ref.invalidate(myGroupsProvider);
                  },
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
      ],
    );
  }

  Widget _buildGroupCard(BuildContext context, WidgetRef ref, Group group) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => GroupDetailPage(group: group)),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.blueDarkLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child:
                      Text(group.emoji, style: const TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: const TextStyle(
                        color: AppColors.blueDark,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        fontFamily: 'PlusJakartaSans',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${group.memberCount} membri',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                        fontFamily: 'PlusJakartaSans',
                      ),
                    ),
                  ],
                ),
              ),

              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

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
          ],
        ),
      ),
    );
  }

  Widget _buildLoginPrompt(BuildContext context, WidgetRef ref) {
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
