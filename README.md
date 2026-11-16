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

### 1. Prasyarat
- Flutter SDK ≥ 3.32
- Android Studio / VS Code
- Firebase Account
- Node.js ≥ 20 (untuk Cloud Functions)

### 2. Setup Firebase
Ikuti panduan lengkap di **[SETUP_FIREBASE.md](SETUP_FIREBASE.md)**

### 3. Generate Firebase Options
```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=sawitguard-iot-prod
```

### 4. Konfigurasi Email OTP (SMTP Gmail)
Untuk pengujian verifikasi akun baru via OTP, salin template konfigurasi:
```bash
# Salin template ke file konfigurasi lokal
copy lib\core\config\email_config.example.dart lib\core\config\email_config.dart
```
> *Catatan: Untuk menjaga keamanan informasi pada repository publik, kredensial asli disembunyikan menggunakan `.gitignore`.*

### 5. Install Dependensi & Jalankan
```bash
flutter pub get
flutter run
```

---

## Download Aplikasi Android (APK Siap Pakai)

File APK installer terbaru dapat diunduh pada tab **[Releases](../../releases)** di repository GitHub ini atau hubungi pengembang untuk pengujian langsung pada perangkat fisik.

---

## Testing Tanpa Hardware

Gunakan **simulator gateway** untuk menguji seluruh alur tanpa perangkat keras fisik:

```powershell
# Edit dulu FIREBASE_PROJECT_ID dan DATABASE_SECRET di dalam file
powershell -ExecutionPolicy Bypass -File gateway_simulator.ps1
```

---

## Deploy Cloud Functions

```bash
cd cloud_functions
npm install
npm run build
firebase deploy --only functions
```

---

## Dokumen Pengujian

| Dokumen | Keterangan |
|:--------|:-----------|
| [MATRIKS_PENGUJIAN_BLACKBOX.md](MATRIKS_PENGUJIAN_BLACKBOX.md) | 37 test case untuk sidang skripsi |
| [SETUP_FIREBASE.md](SETUP_FIREBASE.md) | Panduan konfigurasi Firebase lengkap |
| [gateway_simulator.ps1](gateway_simulator.ps1) | Simulator payload gateway LoRa |

---

## Dependensi Utama

| Package | Versi | Fungsi |
|:--------|:------|:-------|
| `firebase_database` | ^11.3.5 | Streaming data realtime |
| `firebase_messaging` | ^15.2.5 | Push notifikasi FCM |
| `firebase_auth` | ^5.5.2 | Autentikasi pengguna |
| `provider` | ^6.1.5 | State management |
| `audioplayers` | ^6.4.0 | Sirine alarm audio |
| `flutter_animate` | ^4.5.2 | Animasi micro-interaction |
| `google_fonts` | ^6.2.1 | Tipografi Plus Jakarta Sans |
| `flutter_local_notifications` | ^18.0.1 | Notifikasi lokal + FCM channel |

---

