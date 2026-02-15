import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pagella_sanremo/config/theme/app_theme.dart';
import 'package:pagella_sanremo/features/auth/providers/auth_providers.dart';


class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(isLoggedInProvider);
    final user = Supabase.instance.client.auth.currentUser;

    final displayName = user?.userMetadata?['full_name'] as String?
        ?? user?.userMetadata?['name'] as String?
        ?? user?.email?.split('@').first
        ?? 'Anonimo';

    final email = user?.email;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilo'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.blueDark,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 24),

              // Avatar
              CircleAvatar(
                radius: 48,
                backgroundColor: AppColors.blueDarkLight,
                child: Text(
                  isLoggedIn ? displayName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: AppColors.blueDark,
                    fontFamily: 'PlusJakartaSans',
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Nome
              Text(
                isLoggedIn ? displayName : 'Modalità anonima',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'PlusJakartaSans',
                  color: AppColors.blueDark,
                ),
              ),

              if (email != null) ...[
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'PlusJakartaSans',
                    color: Colors.grey.shade500,
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Card info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14355DBF),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildInfoRow(
                      icon: Icons.sync,
                      label: 'Sincronizzazione',
                      value: isLoggedIn ? 'Attiva' : 'Non attiva',
                      valueColor: isLoggedIn ? Colors.green.shade600 : Colors.orange.shade600,
                    ),
                    Divider(color: Colors.grey.shade200, height: 24),
                    _buildInfoRow(
                      icon: Icons.smartphone,
                      label: 'Voti salvati',
                      value: isLoggedIn ? 'Online' : 'Solo locale',
                      valueColor: isLoggedIn ? Colors.green.shade600 : Colors.grey.shade600,
                    ),
                    if (isLoggedIn) ...[
                      Divider(color: Colors.grey.shade200, height: 24),
                      _buildInfoRow(
                        icon: Icons.verified_user_outlined,
                        label: 'Account',
                        value: 'Verificato',
                        valueColor: Colors.green.shade600,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Azioni
              if (isLoggedIn) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmLogout(context, ref),
                    icon: const Icon(Icons.logout, size: 20),
                    label: const Text('Esci dall\'account'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade400,
                      side: BorderSide(color: Colors.red.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ref.read(anonymousModeProvider.notifier).set(false);
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    icon: const Icon(Icons.login, size: 20),
                    label: const Text('Registrati o accedi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blueDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Accedi per sincronizzare i voti, vedere la classifica\ncommunity e creare gruppi con i tuoi amici.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'PlusJakartaSans',
                    color: Colors.grey.shade500,
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Versione app
              Text(
                'Pagella Sanremo v1.0.0',
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'PlusJakartaSans',
                  color: Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.blueDark),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'PlusJakartaSans',
              color: AppColors.blueDark,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: 'PlusJakartaSans',
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Esci dall\'account'),
        content: const Text('Sei sicuro di voler uscire?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Esci'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await Supabase.instance.client.auth.signOut();
      // auth_wrapper.dart invalida votesProvider al cambio stato auth
      if (context.mounted) {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    }
  }
}
