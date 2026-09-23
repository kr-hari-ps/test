@echo off
setlocal enabledelayedexpansion

title FileMint - Windows Uninstaller

echo ==================================================================
echo             ⚙️  Uninstalling FileMint Desktop Engine
echo ==================================================================
echo.

set "APP_DIR=%LOCALAPPDATA%\FileMint"
set "CONFIG_DIR=%APPDATA%\FileMint"
set "DESKTOP_LINK=%USERPROFILE%\Desktop\FileMint.lnk"
set "START_LINK=%APPDATA%\Microsoft\Windows\Start Menu\Programs\FileMint.lnk"

echo [!] This will completely remove FileMint application binaries,
echo     local settings, and desktop/start menu shortcuts.
echo.
set /p "CONFIRM=Are you sure you want to uninstall FileMint? (y/N): "
if /i not "!CONFIRM!"=="y" (
    echo.
    echo 🛑 Uninstallation cancelled by user.
    echo.
    pause
    exit /b 0
)

echo.
echo [*] Removing application binaries: %APP_DIR%
if exist "%APP_DIR%" rmdir /s /q "%APP_DIR%"

echo [*] Removing application configuration: %CONFIG_DIR%
if exist "%CONFIG_DIR%" rmdir /s /q "%CONFIG_DIR%"

echo [*] Removing shortcuts...
if exist "%DESKTOP_LINK%" del /f /q "%DESKTOP_LINK%"
if exist "%START_LINK%" del /f /q "%START_LINK%"

echo.
echo ==================================================================
echo 🎉 FileMint successfully uninstalled from Windows!
echo ==================================================================
echo.
pause
