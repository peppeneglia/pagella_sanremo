import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pagella_sanremo/features/auth/providers/auth_providers.dart';
import 'package:pagella_sanremo/features/core/presentation/screens/main_scaffold.dart';
import 'package:pagella_sanremo/features/auth/presentation/screens/welcome_page.dart';
import 'package:pagella_sanremo/features/voting/providers/voting_providers.dart';
import 'package:pagella_sanremo/features/groups/providers/groups_provider.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final isAnonymous = ref.watch(anonymousModeProvider);

    // Quando cambia lo stato auth, resetta tutti i provider utente
    ref.listen(authStateProvider, (prev, next) {
      ref.invalidate(votesProvider);
      ref.invalidate(myGroupsProvider);
      ref.invalidate(selectedGroupIdProvider);
    });

    if (isAnonymous) {
      return const MainScaffold();
    }

    return authState.when(
      data: (state) {
        if (state.session != null) {
          return const MainScaffold();
        }
        return const WelcomePage();
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => const WelcomePage(),
    );
  }
}
