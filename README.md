SawitGuard IoT 

> **Sistem Deteksi Intrusi Perkebunan Kelapa Sawit Berbasis IoT**  
> Menggunakan Fusi Sensor Boolean, Komunikasi LoRa, dan Ekosistem Flutter-Firebase

---

## Tentang Aplikasi

SawitGuard IoT adalah aplikasi Android yang berfungsi sebagai **antarmuka pengguna akhir** untuk sistem keamanan perkebunan kelapa sawit berbasis IoT. Aplikasi ini dirancang untuk:

- **Memantau** status sensor di lapangan secara *real-time*
- **Membunyikan alarm** secara instan ketika intrusi terdeteksi
- **Membangunkan HP** petani di malam hari meski layar terkunci
- **Mencatat riwayat** kejadian sebagai bukti audit permanen

---

## Arsitektur Sistem End-to-End

```
[Sensor PIR + Radar] → [Mikrokontroler (Boolean AND)] → [LoRa Radio]
       ↓
[Gateway ESP32 + WiFi] → [Firebase Realtime DB]
       ↓
[Cloud Functions] → [FCM High Priority]
       ↓
[Aplikasi Flutter Android] ← Streaming WebSocket
```

---

## Struktur Kode (Clean Architecture / MVVM)

```
lib/
├── core/
│   ├── constants/app_constants.dart      # Firebase paths, status strings
│   ├── theme/app_theme.dart              # Dark theme, warna, tipografi
│   └── utils/date_formatter.dart         # Format tanggal Indonesia
├── data/
│   ├── models/
│   │   ├── device_model.dart             # Node sensor IoT
│   │   ├── log_model.dart                # Riwayat kejadian
│   │   └── user_model.dart               # Profil petani + FCM token
│   └── services/
│       ├── firebase_auth_service.dart    # Login/logout
│       ├── realtime_db_service.dart      # Stream & write Firebase RTDB
│       ├── fcm_service.dart              # Notifikasi push (3 state)
│       └── audio_alert_service.dart      # Sirine + getaran
├── providers/
│   ├── auth_provider.dart                # State otentikasi
│   └── device_provider.dart             # State perangkat + alarm lifecycle
├── screens/
│   ├── splash/splash_screen.dart         # Splash + routing otomatis
│   ├── auth/login_screen.dart            # Form login
│   ├── dashboard/dashboard_screen.dart   # Monitoring realtime
│   ├── alert/alert_screen.dart           # Layar merah darurat
│   └── history/history_screen.dart       # Audit trail intrusi
├── firebase_options.dart                 # Konfigurasi Firebase (generate dengan FlutterFire CLI)
└── main.dart                             # Entry point + dependency injection
```

---

## Langkah Setup

1. Prasyarat
- Flutter SDK ≥ 3.32
- Android Studio / VS Code
- Firebase Account
- Node.js ≥ 20 (untuk Cloud Functions)

2. Setup Firebase
Ikuti panduan lengkap di **[SETUP_FIREBASE.md](SETUP_FIREBASE.md)**

3. Generate Firebase Options
```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=sawitguard-iot-prod
```

4. Konfigurasi Email OTP (SMTP Gmail)
Untuk pengujian verifikasi akun baru via OTP, salin template konfigurasi:
```bash
# Salin template ke file konfigurasi lokal
copy lib\core\config\email_config.example.dart lib\core\config\email_config.dart
```
> *Catatan: Untuk menjaga keamanan informasi pada repository publik, kredensial asli disembunyikan menggunakan `.gitignore`.*

5. Install Dependensi & Jalankan
```bash
flutter pub get
flutter run
```

---

Download Aplikasi Android APK Siap Pakai

File APK installer terbaru dapat diunduh pada tab **[Releases](../../releases)** di repository GitHub ini atau hubungi pengembang untuk pengujian langsung pada perangkat fisik.



