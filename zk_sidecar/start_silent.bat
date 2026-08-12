@echo off
REM Starts the ZK sidecar minimized if it is not already healthy.
cd /d "%~dp0"

if not exist config.json copy /Y config.example.json config.json >nul

set "PY="
if exist "%LocalAppData%\Programs\Python\Python312\python.exe" set "PY=%LocalAppData%\Programs\Python\Python312\python.exe"
if exist "%LocalAppData%\Programs\Python\Python313\python.exe" set "PY=%LocalAppData%\Programs\Python\Python313\python.exe"
if "%PY%"=="" set "PY=python"

powershell -NoProfile -ExecutionPolicy Bypass -Command "try { $r = Invoke-WebRequest -Uri 'http://127.0.0.1:8765/health' -UseBasicParsing -TimeoutSec 2; if ($r.StatusCode -eq 200) { exit 0 }; exit 1 } catch { exit 1 }"
if %ERRORLEVEL%==0 exit /b 0

start "MECMS-ZK-Sidecar" /MIN "%PY%" "%~dp0server.py"
exit /b 0
