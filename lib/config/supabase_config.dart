/// Configurazione Supabase letta a compile-time.
///
/// I valori non sono versionati: vanno passati con `--dart-define` oppure con
/// `--dart-define-from-file=env.json` (vedi `env.example.json`).
///
/// ```sh
/// flutter run --dart-define-from-file=env.json
/// ```
class SupabaseConfig {
  const SupabaseConfig._();

  static const String url = String.fromEnvironment('SUPABASE_URL');

  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// `true` se entrambi i valori sono stati forniti a compile-time.
  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
