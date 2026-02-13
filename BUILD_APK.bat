@echo off
setlocal

echo ===================================================
echo   MANUAL BUILD SCRIPT FOR SIMPLE MUSIC APP
echo ===================================================

:: Ensure we are in the script's directory (Project Root)
cd /d "%~dp0"

:: 1. SET JAVA HOME (Hardcoded to found path)
set "JAVA_HOME=C:\Program Files\Eclipse Adoptium\jdk-17.0.18.8-hotspot"
set "PATH=%JAVA_HOME%\bin;%PATH%"
echo [Step 1] Java configured: %JAVA_HOME%

:: 2. SET FLUTTER PATH (Hardcoded to found path)
set "FLUTTER_BIN=C:\FLUTTER\flutter\bin\flutter.bat"
echo [Step 2] Flutter configured: %FLUTTER_BIN%

:: 3. CLEAN PROJECT
echo.
echo [Step 3] Cleaning project...
call "%FLUTTER_BIN%" clean
if %errorlevel% neq 0 (
    echo [ERROR] Clean failed.
    pause
    exit /b %errorlevel%
)

:: 4. GET DEPENDENCIES
echo.
echo [Step 4] Getting dependencies...
call "%FLUTTER_BIN%" pub get
if %errorlevel% neq 0 (
    echo [ERROR] Pub get failed.
    pause
    exit /b %errorlevel%
)

:: 5. BUILD APK
echo.
echo [Step 5] Building APK (Release)...
call "%FLUTTER_BIN%" build apk --release
if %errorlevel% neq 0 (
    echo [ERROR] Build failed.
    pause
    exit /b %errorlevel%
)

echo.
echo ===================================================
echo   BUILD SUCCESSFUL!
echo ===================================================
echo.
echo APK Location:
echo simple_music_app\build\app\outputs\flutter-apk\app-release.apk
echo.
pause==================================================
pause
