import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

final anonymousModeProvider =
    StateNotifierProvider<AnonymousModeNotifier, bool>((ref) {
  return AnonymousModeNotifier();
});

class AnonymousModeNotifier extends StateNotifier<bool> {
  static const _key = 'anonymous_mode';

  AnonymousModeNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? false;
  }

  Future<void> set(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}

/// Combina lo stream auth con un fallback sulla sessione corrente
/// per avere un valore corretto anche durante il caricamento iniziale.
final isLoggedInProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.whenOrNull(
        data: (state) => state.session != null,
      ) ??
      (Supabase.instance.client.auth.currentSession != null);
});
