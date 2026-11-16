// lib/firebase_options.dart
//
// ═══════════════════════════════════════════════════════════════════════════
// FILE INI HARUS DIGENERATE ULANG MENGGUNAKAN FLUTTERFIRE CLI
// ═══════════════════════════════════════════════════════════════════════════
//
// Langkah-langkah:
// 1. Install FlutterFire CLI (jika belum):
//    dart pub global activate flutterfire_cli
//
// 2. Login ke Firebase (jika belum):
//    firebase login
//
// 3. Jalankan di folder proyek ini:
//    flutterfire configure --project=sawitguard-iot-prod
//
// 4. Pilih platform: Android
//
// File ini akan otomatis digenerate dengan konfigurasi proyek Firebase Anda.
// ═══════════════════════════════════════════════════════════════════════════
//
// SEMENTARA (untuk development tanpa Firebase): Uncomment blok di bawah
// dan isi dengan nilai dari Project Settings > General > Your Apps di Firebase Console.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions tidak dikonfigurasi untuk platform ini. '
          'Jalankan: flutterfire configure',
        );
    }
  }

  // ─── GANTI NILAI BERIKUT DENGAN NILAI DARI FIREBASE CONSOLE ─────────────
  // Project Settings > General > Your Apps > Android App > google-services.json
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCuuiNcnRFyi547nUhnOXfx51-b7GaQiik',
    appId: '1:60824220243:android:3bcad4b045a6dcf5820ca6',
    messagingSenderId: '60824220243',
    projectId: 'sawitguard-iot-prod',
    databaseURL: 'https://sawitguard-iot-prod-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'sawitguard-iot-prod.firebasestorage.app',
  );
  // ─────────────────────────────────────────────────────────────────────────
}
