@echo off
REM One-time setup: custom URL protocol + Windows Startup so the admin panel
REM can auto-start the helper when you open Devices.
cd /d "%~dp0"
set "SCRIPT=%~dp0start_silent.bat"

echo Registering mecms-zk:// protocol ...
reg add "HKCU\Software\Classes\mecms-zk" /ve /d "URL:MECMS ZK Helper" /f >nul
reg add "HKCU\Software\Classes\mecms-zk" /v "URL Protocol" /d "" /f >nul
reg add "HKCU\Software\Classes\mecms-zk\shell\open\command" /ve /d "\"%SCRIPT%\" \"%%1\"" /f >nul

echo Adding Startup shortcut ...
set "STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
copy /Y "%SCRIPT%" "%STARTUP%\MECMS_ZK_Helper.bat" >nul

echo.
echo Done. Protocol: mecms-zk://start
echo Helper will also start with Windows.
echo Starting helper now...
call "%SCRIPT%"
exit /b 0
