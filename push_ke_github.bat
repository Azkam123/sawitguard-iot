@echo off
chcp 65001 >nul
title Auto Push SawitGuard IoT ke GitHub
color 0A
echo ================================================================
echo               SAWITGUARD IOT - AUTO PUSH GITHUB
echo ================================================================
echo.
echo [1/3] Menyiapkan perubahan kodingan...
git add .
echo.
set /p msg="Masukkan catatan perubahan (tekan ENTER untuk otomatis): "
if "%msg%"=="" (
    set msg=Pembaruan sistem SawitGuard IoT: %date% %time%
)
echo.
echo [2/3] Menyimpan riwayat perubahan (commit)...
git commit -m "%msg%"
echo.
echo [3/3] Mengunggah perubahan ke GitHub...
git push origin main
echo.
echo ================================================================
echo   BERHASIL! Kodingan terbaru sudah tersinkronisasi di GitHub.
echo ================================================================
echo.
pause
