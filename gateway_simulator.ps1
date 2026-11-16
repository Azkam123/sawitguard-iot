# ============================================================
# SawitGuard IoT - Simulator Gateway LoRa (Mock Hardware)
# ============================================================
# Script ini mensimulasikan pengiriman data dari Gateway ESP32
# ke Firebase Realtime Database tanpa membutuhkan hardware fisik.
#
# CARA PENGGUNAAN:
# 1. Isi variabel konfigurasi di bawah ini
# 2. Jalankan: powershell -ExecutionPolicy Bypass -File gateway_simulator.ps1
# ============================================================

# ─── KONFIGURASI (WAJIB DIISI) ──────────────────────────────
$FIREBASE_PROJECT_ID = "YOUR_FIREBASE_PROJECT_ID"  # Ganti dengan ID proyek Firebase
$DATABASE_SECRET = "YOUR_DATABASE_SECRET"           # Dari Project Settings > Service Accounts
$NODE_ID = "node_selatan_01"                       # ID node yang disimulasikan
# ─────────────────────────────────────────────────────────────

$BASE_URL = "https://$FIREBASE_PROJECT_ID.firebaseio.com"
$AUTH_QUERY = "auth=$DATABASE_SECRET"

function Get-UnixTimestamp {
    return [int][double]::Parse((Get-Date -UFormat "%s"))
}

function Send-NodeUpdate($nodeId, $status, $battery, $rssi) {
    $ts = Get-UnixTimestamp
    $body = @{
        status       = $status
        baterai      = $battery
        sinyal_rssi  = $rssi
        last_updated = $ts
    } | ConvertTo-Json

    $url = "$BASE_URL/devices/$nodeId.json?$AUTH_QUERY"
    try {
        $response = Invoke-RestMethod -Method Patch -Uri $url `
            -Body $body -ContentType "application/json"
        Write-Host "[$ts] Node '$nodeId' -> Status: $status | Baterai: $battery% | RSSI: $rssi dBm" -ForegroundColor $(
            if ($status -eq "INTRUSI") { "Red" } else { "Green" }
        )
    } catch {
        Write-Host "ERROR: Gagal kirim ke Firebase: $_" -ForegroundColor Red
    }
}

function Write-IntrusionLog($nodeId, $lokasi) {
    $ts = Get-UnixTimestamp
    $logId = "log_$ts"
    $body = @{
        device_id  = $nodeId
        lokasi     = $lokasi
        status     = "INTRUSI"
        timestamp  = $ts
        keterangan = "Sensor PIR (panas tubuh) dan Radar Microwave (gerak kinetik) terpicu bersamaan. Simulasi Gateway."
    } | ConvertTo-Json

    $url = "$BASE_URL/history_logs/$logId.json?$AUTH_QUERY"
    try {
        Invoke-RestMethod -Method Put -Uri $url `
            -Body $body -ContentType "application/json" | Out-Null
        Write-Host "[$ts] LOG TERTULIS -> ID: $logId" -ForegroundColor Yellow
    } catch {
        Write-Host "ERROR: Gagal tulis log: $_" -ForegroundColor Red
    }
}

# ─── MENU SIMULASI ────────────────────────────────────────────
function Show-Menu {
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║   SawitGuard IoT - Gateway Simulator     ║" -ForegroundColor Cyan
    Write-Host "╠══════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host "║  [1] Kirim Status AMAN (kondisi normal)  ║" -ForegroundColor Cyan
    Write-Host "║  [2] Kirim INTRUSI (simulasi penyusup)   ║" -ForegroundColor Cyan
    Write-Host "║  [3] Simulasi False Alarm PIR saja       ║" -ForegroundColor Cyan
    Write-Host "║  [4] Simulasi False Alarm Radar saja     ║" -ForegroundColor Cyan
    Write-Host "║  [5] Skenario Malam Penuh (auto loop)    ║" -ForegroundColor Cyan
    Write-Host "║  [Q] Keluar                              ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Start-NightSimulation {
    Write-Host "`n[SIMULASI MALAM PENUH DIMULAI]" -ForegroundColor Magenta
    Write-Host "Kirim update baterai + status AMAN setiap 30 detik..." -ForegroundColor DarkGray

    $batLevel = 95
    $iteration = 0

    while ($true) {
        $iteration++
        $batLevel = [Math]::Max(10, $batLevel - 1)

        # Malam normal
        Send-NodeUpdate $NODE_ID "AMAN" $batLevel -104

        # Simulasi intrusi di iterasi ke-5
        if ($iteration -eq 5) {
            Write-Host "`n!!! NINJA SAWIT TERDETEKSI - PIR + RADAR = HIGH !!!" -ForegroundColor Red -BackgroundColor DarkRed
            Start-Sleep -Seconds 2
            Send-NodeUpdate $NODE_ID "INTRUSI" $batLevel -98
            Write-IntrusionLog $NODE_ID "Blok Selatan Parit Gajah"
        }

        Write-Host "  Berikutnya: 10 detik..." -ForegroundColor DarkGray
        Start-Sleep -Seconds 10

        if ($Host.UI.RawUI.KeyAvailable) {
            $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            if ($key.Character -eq 'q' -or $key.Character -eq 'Q') {
                Write-Host "`nSimulasi malam dihentikan." -ForegroundColor Yellow
                break
            }
        }
    }
}

# ─── MAIN LOOP ────────────────────────────────────────────────
if ($FIREBASE_PROJECT_ID -eq "YOUR_FIREBASE_PROJECT_ID") {
    Write-Host "`n[PERHATIAN] Harap isi variabel konfigurasi di bagian atas script!" -ForegroundColor Red
    Write-Host "Edit: `$FIREBASE_PROJECT_ID dan `$DATABASE_SECRET" -ForegroundColor Yellow
    exit 1
}

Write-Host "`nTerhubung ke Firebase: $FIREBASE_PROJECT_ID" -ForegroundColor Green
Write-Host "Node yang disimulasikan: $NODE_ID" -ForegroundColor Green

do {
    Show-Menu
    $choice = Read-Host "Pilihan"

    switch ($choice.ToUpper()) {
        "1" {
            $bat = Get-Random -Minimum 70 -Maximum 100
            Send-NodeUpdate $NODE_ID "AMAN" $bat -104
        }
        "2" {
            Send-NodeUpdate $NODE_ID "INTRUSI" 82 -98
            Write-IntrusionLog $NODE_ID "Blok Selatan Parit Gajah"
            Write-Host "`n>> Cek aplikasi Flutter sekarang! Alarm harus berbunyi <<" -ForegroundColor Red
        }
        "3" {
            Write-Host "`n[FALSE ALARM TEST] Hanya PIR aktif (angin panas/sinar matahari)" -ForegroundColor Yellow
            Write-Host "Sistem SawitGuard harus MENGABAIKAN ini (status tetap AMAN)" -ForegroundColor Yellow
            # Gateway ESP32 akan memfilter ini di level mikrokontroler
            # Tidak ada kiriman ke Firebase karena Boolean AND Gate = 0
            Write-Host ">> Node TIDAK mengirim sinyal (PIR=1, Radar=0 -> Boolean AND = 0) <<" -ForegroundColor DarkGray
        }
        "4" {
            Write-Host "`n[FALSE ALARM TEST] Hanya Radar aktif (dahan sawit bergoyang)" -ForegroundColor Yellow
            Write-Host "Sistem SawitGuard harus MENGABAIKAN ini (status tetap AMAN)" -ForegroundColor Yellow
            Write-Host ">> Node TIDAK mengirim sinyal (PIR=0, Radar=1 -> Boolean AND = 0) <<" -ForegroundColor DarkGray
        }
        "5" { Start-NightSimulation }
        "Q" { Write-Host "`nSimulator dihentikan." -ForegroundColor Cyan; exit 0 }
        default { Write-Host "Pilihan tidak valid." -ForegroundColor Red }
    }

} while ($true)
