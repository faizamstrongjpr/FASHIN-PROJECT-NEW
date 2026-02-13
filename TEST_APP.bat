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
echo   [KHUSUS WIRELESS / TANPA KABEL]
echo   Ketik "wireless" jika ingin setting koneksi WiFi dulu.
echo.
echo   Contoh ID:
echo   - 23071FDF6000HG  (untuk Pixel 6 Anda)
echo   - windows         (untuk PC)
echo ===================================================
set /p DEVICE_ID="Ketik ID atau 'wireless': "

if /i "%DEVICE_ID%"=="wireless" goto SETUP_WIRELESS
goto RUN_APP

:SETUP_WIRELESS
echo.
echo ===================================================
echo   SETUP WIRELESS DEBUGGING
echo   1. Pastikan HP colok USB dulu sekarang.
echo   2. Pastikan HP dan PC di WiFi yang sama.
echo ===================================================
pause

echo Mengaktifkan mode TCPIP...
"C:\Users\Administrator\AppData\Local\Android\Sdk\platform-tools\adb.exe" tcpip 5555

echo.
echo SEKARANG CABUT KABEL USB ANDA.
echo Lalu cek IP Address HP Anda (di Settings -> About Phone -> Status).
echo.
set /p IP_ADDRESS="Masukkan IP Address HP (misal 192.168.1.5): "

echo Menghubungkan ke %IP_ADDRESS%...
"C:\Users\Administrator\AppData\Local\Android\Sdk\platform-tools\adb.exe" connect %IP_ADDRESS%:5555

echo.
echo Jika sukses, silakan close dan buka lagi TEST_APP.bat
pause
exit

:RUN_APP
echo.
echo Menjalankan di perangkat: %DEVICE_ID% ...
echo (Proses ini butuh waktu beberapa menit untuk compile)
call "%FLUTTER_BIN%" run -d %DEVICE_ID%

pause
