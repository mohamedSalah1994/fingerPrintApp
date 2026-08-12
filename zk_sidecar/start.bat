@echo off
cd /d "%~dp0"
if not exist config.json copy config.example.json config.json

set "PY="
if exist "%LocalAppData%\Programs\Python\Python312\python.exe" set "PY=%LocalAppData%\Programs\Python\Python312\python.exe"
if exist "%LocalAppData%\Programs\Python\Python313\python.exe" set "PY=%LocalAppData%\Programs\Python\Python313\python.exe"
if "%PY%"=="" set "PY=python"

echo Using: %PY%
"%PY%" -m pip install -r requirements.txt
echo.
echo Starting ZK sidecar on http://127.0.0.1:8765 ...
"%PY%" server.py
pause
