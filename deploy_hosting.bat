@echo off
cd /d "%~dp0"
echo Building Flutter web...
call flutter build web --release
if errorlevel 1 exit /b 1
echo.
echo Deploying to Firebase Hosting...
call firebase deploy --only hosting --project fingerprint-app-2026
pause
