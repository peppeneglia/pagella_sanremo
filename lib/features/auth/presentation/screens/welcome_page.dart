import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pagella_sanremo/config/theme/app_theme.dart';
import 'package:pagella_sanremo/features/auth/providers/auth_providers.dart';
import 'package:pagella_sanremo/features/auth/presentation/screens/login_page.dart';

class WelcomePage extends ConsumerWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: constraints.maxHeight * 0.12),

                    const Text(
                '🎵',
                style: TextStyle(fontSize: 64),
              ),
              const SizedBox(height: 16),
              const Text(
                'PAGELLA SANREMO',
                style: TextStyle(
                  color: AppColors.blueDark,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  fontStyle: FontStyle.italic,
                  fontFamily: 'PlusJakartaSans',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Vota i cantanti di Sanremo\ne scopri cosa pensa la community',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                  fontFamily: 'PlusJakartaSans',
                ),
              ),

              SizedBox(height: constraints.maxHeight * 0.08),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LoginPage(isRegistration: false),
                      ),
                    );
                  },
                  icon: const Icon(Icons.email_outlined),
                  label: const Text('Accedi con Email'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blueDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LoginPage(isRegistration: true),
                      ),
                    );
                  },
                  icon: const Icon(Icons.person_add_outlined),
                  label: const Text('Crea account'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.blueDark,
                    side: const BorderSide(color: AppColors.blueDark),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'oppure',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontFamily: 'PlusJakartaSans',
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ],
              ),

              const SizedBox(height: 24),

              TextButton(
                onPressed: () {
                  ref.read(anonymousModeProvider.notifier).set(true);
                },
                child: Text(
                  'Continua senza account',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 15,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Senza account puoi votare ma non accedi\na classifiche community e gruppi',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 12,
                  fontFamily: 'PlusJakartaSans',
                ),
              ),

              const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
