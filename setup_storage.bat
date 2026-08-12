@echo off
REM Run AFTER enabling Storage once in Firebase Console:
REM https://console.firebase.google.com/project/fingerprint-app-2026/storage
REM Click "Get Started" then come back and run this file.

cd /d "%~dp0"
firebase deploy --only storage --project fingerprint-app-2026
if errorlevel 1 (
  echo.
  echo Deploy failed. Make sure Storage was enabled in the Console first.
  pause
  exit /b 1
)
echo.
echo Storage rules deployed successfully.
pause
