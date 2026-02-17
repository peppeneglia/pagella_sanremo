import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pagella_sanremo/config/theme/app_theme.dart';
import 'package:pagella_sanremo/features/auth/providers/auth_providers.dart';
import 'package:pagella_sanremo/features/auth/presentation/screens/privacy_policy_page.dart';


class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _isDeleting = false;

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Elimina account',
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontWeight: FontWeight.w700,
            color: AppColors.blueDark,
          ),
        ),
        content: const Text(
          'Tutti i tuoi dati (voti, gruppi, profilo) verranno eliminati definitivamente. Questa azione non può essere annullata.\n\nPotrai registrarti di nuovo in futuro.',
          style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 14),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Annulla',
                style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    color: Colors.grey.shade600)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Elimina',
                style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontWeight: FontWeight.w700,
                    color: Colors.red.shade600)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);

    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;

      // Cancella tutti i dati + utente auth tramite funzione RPC server-side
      await client.rpc('delete_user_account');

      // Pulisci cache locale
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('votes_$userId');

      if (!mounted) return;

      Navigator.popUntil(context, (route) => route.isFirst);
      await client.auth.signOut();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account eliminato con successo')),
        );
      }
    } catch (e) {
      debugPrint('Errore eliminazione account: $e');
      if (mounted) {
        setState(() => _isDeleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    onPressed: () {
                      Navigator.of(context).pop();
                      Supabase.instance.client.auth.signOut();
                    },
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
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: _isDeleting ? null : _deleteAccount,
                    icon: _isDeleting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(Icons.delete_forever, size: 18, color: Colors.red.shade300),
                    label: Text(
                      _isDeleting ? 'Eliminazione...' : 'Elimina account',
                      style: TextStyle(
                        fontSize: 13,
                        fontFamily: 'PlusJakartaSans',
                        color: Colors.red.shade300,
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

              const SizedBox(height: 16),

              // Privacy Policy
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PrivacyPolicyPage(),
                      ),
                    );
                  },
                  icon: Icon(Icons.shield_outlined,
                      size: 18, color: Colors.grey.shade600),
                  label: Text(
                    'Privacy Policy',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'PlusJakartaSans',
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

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

}
