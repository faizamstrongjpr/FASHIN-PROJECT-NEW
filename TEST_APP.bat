@echo off
setlocal

echo ===================================================
echo   TEST APP (DEBUG MODE)
echo ===================================================

:: 1. SETUP ENV (Same as Build Script)
set "JAVA_HOME=C:\Program Files\Eclipse Adoptium\jdk-17.0.18.8-hotspot"
set "PATH=%JAVA_HOME%\bin;%PATH%"
set "FLUTTER_BIN=C:\FLUTTER\flutter\bin\flutter.bat"

:: Ensure we are in project root
cd /d "%~dp0"

echo.
echo [1] Check connected devices...
call "%FLUTTER_BIN%" devices

echo.
echo ===================================================
echo   PILIH PERANGKAT:
echo   Lihat daftar "Connected devices" di atas.
echo   Copy ID perangkat yg mau dipakai.
echo.
echo   Contoh ID:
echo   - 23071FDF6000HG  (untuk Pixel 6 Anda)
echo   - windows         (untuk PC)
echo ===================================================
set /p DEVICE_ID="Ketik/Paste Device ID di sini: "

echo.
echo Menjalankan di perangkat: %DEVICE_ID% ...
echo (Proses ini butuh waktu beberapa menit untuk compile)
call "%FLUTTER_BIN%" run -d %DEVICE_ID%

pause
