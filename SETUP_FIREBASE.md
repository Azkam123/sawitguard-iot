# SawitGuard IoT — Panduan Setup Firebase

Dokumen ini berisi panduan langkah-langkah konfigurasi Firebase yang **wajib** dilakukan sebelum menjalankan aplikasi.

---

## Langkah 1: Buat Proyek Firebase

1. Buka [Firebase Console](https://console.firebase.google.com/)
2. Klik **"Add project"** → beri nama: `sawitguard-iot-prod`
3. Aktifkan Google Analytics (opsional)

---

## Langkah 2: Daftarkan Aplikasi Android

1. Di Firebase Console, klik ikon **Android**
2. **Android package name:** `id.sawitguard.sawitguard_iot`
3. **App nickname:** `SawitGuard IoT`
4. Download file **`google-services.json`**
5. Letakkan file di: `android/app/google-services.json`

---

## Langkah 3: Aktifkan Layanan Firebase

### A. Authentication
1. Buka **Authentication → Sign-in method**
2. Aktifkan **Email/Password**

### B. Realtime Database
1. Buka **Realtime Database → Create database**
2. Pilih lokasi: `asia-southeast1 (Singapore)` untuk latensi rendah ke Indonesia
3. Pilih mode: **Start in test mode** (akan diperketat dengan Security Rules)

### C. Cloud Messaging (FCM)
- Sudah aktif otomatis. Pastikan ada **Server key** di **Project Settings → Cloud Messaging**

---

## Langkah 4: Pasang Security Rules Realtime Database

Salin rules berikut ke **Realtime Database → Rules**:

```json
{
  "rules": {
    "users": {
      "$uid": {
        ".read": "$uid === auth.uid",
        ".write": "$uid === auth.uid"
      }
    },
    "devices": {
      ".read": "auth != null",
      ".write": "auth != null"
    },
    "history_logs": {
      ".read": "auth != null",
      ".write": "auth != null"
    }
  }
}
```

---

## Langkah 5: Inisialisasi Skema Database

Masukkan data awal ini secara manual di **Realtime Database → Data**:

```json
{
  "devices": {
    "node_selatan_01": {
      "nama_lokasi": "Blok Selatan Parit Gajah",
      "status": "AMAN",
      "baterai": 88,
      "sinyal_rssi": -98,
      "last_updated": 1726733245
    },
    "node_utara_02": {
      "nama_lokasi": "Blok Utara Jalan Traktor",
      "status": "AMAN",
      "baterai": 94,
      "sinyal_rssi": -104,
      "last_updated": 1726733245
    }
  }
}
```

---

## Langkah 6: Buat Akun Pengguna

1. Buka **Authentication → Users → Add user**
2. Masukkan **Email** dan **Password** pemilik kebun
3. Catat UID yang dihasilkan
4. Tambahkan data profil ke database:
   - Path: `/users/{UID}`
   - Data:
     ```json
     {
       "nama": "Nama Pemilik Kebun",
       "no_hp": "081234567890"
     }
     ```

---

## Langkah 7: Tambahkan `google-services.json` ke Gradle

Pastikan file `android/app/build.gradle` sudah memiliki plugin google-services.
Jalankan: `flutter pub get` lalu `flutter run`

---

## Langkah 8: Simulasi Trigger Intrusi (Untuk Testing)

Untuk menguji sistem tanpa hardware fisik, ubah status node di Firebase Console:

1. Buka **Realtime Database → Data → devices → node_selatan_01**
2. Klik nilai `status` → ubah dari `"AMAN"` menjadi `"INTRUSI"`
3. Simpan → aplikasi Flutter akan **langsung bereaksi** (alarm + layar merah berkedip)

Atau gunakan script PowerShell berikut (isi dengan URL database Anda):
```powershell
$url = "https://YOUR-PROJECT-ID.firebaseio.com/devices/node_selatan_01/status.json"
Invoke-RestMethod -Method Patch -Uri $url -Body '"INTRUSI"' -ContentType "application/json"
```

---

## Catatan Penting untuk Gateway ESP32

Gateway ESP32 di rumah petani cukup mengirim HTTP PATCH ke endpoint ini setiap kali menerima sinyal LoRa dari node sensor:

```
PATCH https://{PROJECT_ID}.firebaseio.com/devices/{node_id}.json
Authorization: Bearer {DATABASE_SECRET}
Content-Type: application/json

{
  "status": "INTRUSI",
  "baterai": 85,
  "last_updated": {UNIX_TIMESTAMP}
}
```
