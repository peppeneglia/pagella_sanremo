class SupabaseConfig {
  /// In sviluppo usa i valori di default.
  /// In produzione passali con:
  /// flutter build appbundle --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://wsckghpbmaeahytunibe.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndzY2tnaHBibWFlYWh5dHVuaWJlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA2MzE3MzIsImV4cCI6MjA4NjIwNzczMn0.kxBZwmNtpZw3FmmrCOA4gBPm0u9kMr1aQ7RiM_JVQFs',
  );
}
