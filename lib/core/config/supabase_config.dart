// lib/core/config/supabase_config.dart

/// Konfigurasi Layanan Supabase untuk Pengiriman & Verifikasi Email OTP SawitGuard IoT.
class SupabaseConfig {
  /// URL Proyek Supabase
  static const String supabaseUrl = 'https://qononsvlvthonrxbplgi.supabase.co';

  /// Anon / Public JWT API Key dari Supabase
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFvbm9uc3ZsdnRob25yeGJwbGdpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTQyODI5OTksImV4cCI6MjEwOTg1ODk5OX0.AdzhQlOKqxlOyVeO0_BiZR-4EQdoGPNnzSf_yDpXIkY';

  /// Publishable Key format baru
  static const String supabasePublishableKey =
      'sb_publishable_ECdNPLgKrhabCMIOWaApmA_j2-qSqKz';

  /// Cek apakah Supabase sudah dikonfigurasi dengan URL & Anon Key yang valid
  static bool get isConfigured {
    return supabaseUrl.isNotEmpty &&
        !supabaseUrl.contains('YOUR_PROJECT_ID') &&
        supabaseAnonKey.isNotEmpty &&
        !supabaseAnonKey.contains('YOUR_SUPABASE_ANON_KEY');
  }
}
