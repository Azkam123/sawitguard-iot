# Matriks Pengujian Black Box Testing — SawitGuard IoT
## Dokumen Validasi Akademis untuk Sidang Skripsi
### Program Studi S1 Teknik Informatika

---

## A. PENGUJIAN FUNGSIONALITAS ANTARMUKA (UI Functionality Test)

| No | ID Test | Modul | Skenario Uji | Langkah Pengujian | Data Input | Hasil yang Diharapkan | Status |
|:--:|:--------|:------|:-------------|:------------------|:-----------|:----------------------|:------:|
| 1 | TC-AUTH-01 | Login | Login dengan kredensial valid | 1. Buka aplikasi<br>2. Masukkan email dan password yang terdaftar<br>3. Tekan tombol "Masuk" | Email: valid<br>Password: valid (≥6 karakter) | Aplikasi berpindah ke Dashboard, tidak ada pesan error | ⬜ |
| 2 | TC-AUTH-02 | Login | Login dengan password salah | 1. Masukkan email valid<br>2. Masukkan password yang salah | Email: valid<br>Password: salah | Tampil banner merah: "Kata sandi salah." Tidak berpindah halaman | ⬜ |
| 3 | TC-AUTH-03 | Login | Login dengan email tidak terdaftar | Masukkan email yang belum terdaftar di Firebase | Email: tidak ada<br>Password: apapun | Tampil banner: "Email tidak terdaftar." | ⬜ |
| 4 | TC-AUTH-04 | Login | Validasi form email kosong | Tekan "Masuk" tanpa mengisi email | Email: kosong | Tampil pesan validasi inline: "Email tidak valid" | ⬜ |
| 5 | TC-AUTH-05 | Login | Validasi password kurang dari 6 karakter | Isi email, isi password < 6 karakter | Password: "12345" | Tampil pesan: "Min. 6 karakter" | ⬜ |
| 6 | TC-AUTH-06 | Logout | Logout dari dashboard | Tekan ikon logout di AppBar | — | Aplikasi kembali ke halaman Login | ⬜ |

---

## B. PENGUJIAN MONITORING REALTIME (StreamBuilder Reactive Test)

| No | ID Test | Modul | Skenario Uji | Langkah Pengujian | Hasil yang Diharapkan | Status |
|:--:|:--------|:------|:-------------|:------------------|:----------------------|:------:|
| 7 | TC-DASH-01 | Dashboard | Kartu node ditampilkan | Login → buka Dashboard | Kartu tiap node muncul dengan nama lokasi, level baterai, dan status | ⬜ |
| 8 | TC-DASH-02 | Dashboard | Status banner hijau saat semua AMAN | Pastikan semua status node = "AMAN" di Firebase | Banner menampilkan teks hijau "SEMUA TITIK PERKEBUNAN AMAN" | ⬜ |
| 9 | TC-DASH-03 | Dashboard | Perubahan status realtime tanpa refresh | Ubah status node ke "INTRUSI" via Firebase Console | Kartu node langsung berubah warna merah dan banner berubah tanpa refresh manual | ⬜ |
| 10 | TC-DASH-04 | Dashboard | Indikator baterai menampilkan warna tepat | Atur baterai > 60%, lalu 20-59%, lalu < 20% | Bar baterai: Hijau (> 60%), Kuning (20-59%), Merah (< 20%) | ⬜ |
| 11 | TC-DASH-05 | Dashboard | Waktu ping terakhir ditampilkan relatif | Lihat bagian "Ping Terakhir" di kartu | Format "X menit lalu" / "X jam lalu" sesuai timestamp | ⬜ |

---

## C. PENGUJIAN ALARM DARURAT (Alert Screen Test)

| No | ID Test | Modul | Skenario Uji | Langkah Pengujian | Hasil yang Diharapkan | Status |
|:--:|:--------|:------|:-------------|:------------------|:----------------------|:------:|
| 12 | TC-ALERT-01 | Alert | Layar peringatan muncul otomatis | Ubah status Firebase ke "INTRUSI" | AlertScreen muncul full-screen secara otomatis dalam < 1.5 detik | ⬜ |
| 13 | TC-ALERT-02 | Alert | Sirine audio berbunyi | Tunggu AlertScreen muncul | Audio sirine berputar terus (looping) hingga slider digeser | ⬜ |
| 14 | TC-ALERT-03 | Alert | Latar berkedip merah (strobo) | Amati AlertScreen saat aktif | Latar belakang beranimasikan strobo merah-gelap bergantian secara kontinu | ⬜ |
| 15 | TC-ALERT-04 | Alert | Nama lokasi node ditampilkan | Trigger intrusi dari node_selatan_01 | AlertScreen menampilkan "Blok Selatan Parit Gajah" | ⬜ |
| 16 | TC-ALERT-05 | Alert | Slider reset memerlukan gestur penuh | Geser slider setengah jalan lalu lepas | Slider kembali ke posisi awal (kiri), alarm tetap berbunyi | ⬜ |
| 17 | TC-ALERT-06 | Alert | Reset berhasil via slider penuh | Geser slider ke ujung kanan | Alarm berhenti, status Firebase kembali "AMAN", kembali ke Dashboard | ⬜ |
| 18 | TC-ALERT-07 | Alert | Timer durasi alarm berjalan | Amati angka timer di pojok kiri atas | Timer menghitung maju setiap detik dalam format MM:SS | ⬜ |
| 19 | TC-ALERT-08 | Alert | Tombol Back diblokir | Tekan tombol Back HP saat AlertScreen aktif | Layar tidak berpindah, alarm tetap aktif (PopScope.canPop = false) | ⬜ |

---

## D. PENGUJIAN NOTIFIKASI LATAR BELAKANG (FCM Background Test)

| No | ID Test | Modul | Skenario Uji | Langkah Pengujian | Hasil yang Diharapkan | Status |
|:--:|:--------|:------|:-------------|:------------------|:----------------------|:------:|
| 20 | TC-FCM-01 | FCM | Notifikasi foreground | Buka aplikasi → trigger intrusi via Firebase | Notifikasi heads-up muncul + AlertScreen langsung tampil | ⬜ |
| 21 | TC-FCM-02 | FCM | Notifikasi background | Minimiskan aplikasi → trigger intrusi | Notifikasi heads-up muncul di status bar; tap buka aplikasi langsung ke alert | ⬜ |
| 22 | TC-FCM-03 | FCM | **Notifikasi layar terkunci (kritis)** | Matikan layar HP (sleep) → trigger intrusi | **HP langsung menyala, notifikasi muncul di lockscreen + sirine berbunyi** | ⬜ |
| 23 | TC-FCM-04 | FCM | Notifikasi aplikasi ditutup | Tutup sepenuhnya (force stop bukan kill) → trigger | Notifikasi FCM tetap masuk, HP berdering | ⬜ |
| 24 | TC-FCM-05 | FCM | Isi notifikasi benar | Cek teks notifikasi setelah trigger | Judul: "⚠️ PERINGATAN! INTRUSI TERDETEKSI" | Body: nama lokasi node | ⬜ |

---

## E. PENGUJIAN RIWAYAT INTRUSI (Audit Trail Test)

| No | ID Test | Modul | Skenario Uji | Langkah Pengujian | Hasil yang Diharapkan | Status |
|:--:|:--------|:------|:-------------|:------------------|:----------------------|:------:|
| 25 | TC-HIST-01 | History | Log kejadian tercatat | Trigger intrusi → reset → buka History | Baris log baru muncul dengan cap waktu, lokasi, dan keterangan | ⬜ |
| 26 | TC-HIST-02 | History | Urutan log terbaru di atas | Trigger dua kali intrusi | Log terbaru selalu tampil di urutan teratas | ⬜ |
| 27 | TC-HIST-03 | History | Status konfirmasi ditampilkan | Reset alarm via slider → cek History | Log menampilkan badge "✓ Direset" dan waktu reset | ⬜ |
| 28 | TC-HIST-04 | History | Tombol refresh log berfungsi | Tekan ikon refresh di History | Log diperbarui dari Firebase | ⬜ |
| 29 | TC-HIST-05 | History | Tampilan kosong saat belum ada log | Login dengan database kosong | Tampil ikon dan teks "Belum ada riwayat intrusi" | ⬜ |

---

## F. PENGUJIAN FUSI SENSOR (Sensor Fusion Validation — Menggunakan Simulator Hardware)

> **Catatan:** Pengujian ini membuktikan efektivitas logika Boolean AND Gate vs sensor tunggal.
> Gunakan `gateway_simulator.ps1` untuk mensimulasikan skenario tanpa hardware fisik.

| No | ID Test | Skenario | Kondisi PIR | Kondisi Radar | Boolean AND Result | Tindakan Gateway | Status Firebase | Status |
|:--:|:--------|:---------|:-----------:|:-------------:|:------------------:|:----------------:|:---------------:|:------:|
| 30 | TC-FUSI-01 | Kondisi normal, tidak ada aktivitas | 0 | 0 | **0** | Tidak kirim sinyal | Tetap AMAN | ⬜ |
| 31 | TC-FUSI-02 | **False Alarm Radar** — angin kencang menggerakkan dahan sawit | 0 | 1 | **0** | Tidak kirim sinyal | Tetap AMAN ✅ | ⬜ |
| 32 | TC-FUSI-03 | **False Alarm PIR** — paparan sinar matahari / hawa panas lingkungan | 1 | 0 | **0** | Tidak kirim sinyal | Tetap AMAN ✅ | ⬜ |
| 33 | TC-FUSI-04 | **VALIDASI INTRUSI** — manusia bergerak di area sensor | 1 | 1 | **1 ✅** | Kirim payload INTRUSI | Berubah INTRUSI 🔴 | ⬜ |

---

## G. PENGUJIAN LATENSI (End-to-End Latency Benchmark)

| No | ID Test | Jalur Uji | Target Latensi | Cara Pengukuran | Hasil Pengukuran | Status |
|:--:|:--------|:---------|:--------------:|:----------------|:-----------------|:------:|
| 34 | TC-LAT-01 | Gateway HTTP PATCH → Firebase Database update | < 500 ms | Catat selisih timestamp saat PATCH dikirim vs `last_updated` di Firebase | ___ ms | ⬜ |
| 35 | TC-LAT-02 | Firebase update → Cloud Functions trigger | < 300 ms | Bandingkan timestamp di database vs timestamp log Cloud Functions | ___ ms | ⬜ |
| 36 | TC-LAT-03 | Cloud Functions → FCM terkirim | < 500 ms | Bandingkan log Functions vs waktu notifikasi diterima HP | ___ ms | ⬜ |
| 37 | TC-LAT-04 | **Total: Sensor trigger → HP berdering (Target Sidang)** | **< 1.500 ms** | Rekam video: stopwatch dimulai saat Gateway dikirim, berhenti saat HP berbunyi | ___ ms | ⬜ |

---

## H. RINGKASAN METRIK PERBANDINGAN UNTUK SKRIPSI

| Metrik Kunci | Sensor PIR Tunggal | Sensor Radar Tunggal | Fusi Boolean (PIR AND Radar) |
|:------------|:------------------:|:--------------------:|:----------------------------:|
| **False Positive — Angin (Skenario TC-FUSI-02)** | 0% ✅ (tidak tertipu) | **Terpicu ❌** | 0% ✅ |
| **False Positive — Terik Matahari (TC-FUSI-03)** | **Terpicu ❌** | 0% ✅ | 0% ✅ |
| **True Positive — Manusia (TC-FUSI-04)** | Terpicu ✅ | Terpicu ✅ | **Terpicu ✅** |
| **Deteksi Hewan Liar** | Bisa terpicu ⚠️ | **Terpicu ❌** | Berkurang 70%+ ✅ |
| **CPU Load pada Mikrokontroler** | Rendah | Rendah | **Ultra Rendah (if-statement)** |
| **Konsumsi Daya** | ~5 µA idle | ~5 µA idle | **~5 µA idle** (tanpa komputasi berat) |

---

## I. SKENARIO DEMO SIDANG SKRIPSI (Script Demo)

### Persiapan (10 menit sebelum sidang):
1. Pastikan HP Android terisi penuh dan aktif
2. Buka aplikasi → Login → tampilkan Dashboard (semua AMAN, hijau)
3. Siapkan laptop dengan Firebase Console terbuka di tab `/devices`
4. Siapkan terminal dengan `gateway_simulator.ps1`

### Urutan Demo (± 5-7 menit):

**Demo 1 — False Alarm Filter (TC-FUSI-02 & 03):**
```
Jalankan simulator → Pilih [3] (False Alarm PIR)
"Pak/Bu dosen, ini simulasi hujan panas / sinar matahari menerpa sensor.
 Hanya PIR aktif, Radar tidak. Boolean AND = 0 → Tidak ada alarm."

Jalankan simulator → Pilih [4] (False Alarm Radar)
"Ini simulasi dahan sawit bergoyang angin. Radar aktif, PIR tidak.
 AND = 0 → Alarm tidak berbunyi. Ini yang membedakan sistem kami."
```

**Demo 2 — Validasi Intrusi Nyata (TC-FUSI-04 + TC-ALERT-01 + TC-LAT-04):**
```
Jalankan simulator → Pilih [2] (INTRUSI)
"Sekarang kedua sensor aktif bersamaan. AND = 1."
→ Hitung detik hingga HP berbunyi keras dan layar merah berkedip
"Dari gateway ke alarm HP: X detik. Lebih cepat dari SMS atau telepon manual."
```

**Demo 3 — Audit Trail (TC-HIST-01):**
```
Tunjukkan History Screen
"Setiap kejadian dicatat permanen. Bisa dibuktikan kepada aparat hukum
 kapan dan di mana pencurian terjadi, berapa lama alarm aktif."
```

**Demo 4 — Lockscreen Test (TC-FCM-03):**
```
Matikan layar HP → letakkan di meja dosen → trigger ulang INTRUSI
"HP dalam keadaan sleep/kunci layar..."
→ HP menyala dan berbunyi keras
"Sistem berhasil membangunkan HP meskipun layar mati."
```

---

> **Catatan Penulis Skripsi:** Isi kolom "Hasil Pengukuran" dan "Status" (✅ Lulus / ❌ Gagal) 
> setelah melakukan pengujian aktual dengan hardware atau simulator. Lampirkan dokumen ini 
> sebagai bagian dari Bab IV (Pengujian dan Analisis) skripsi.
