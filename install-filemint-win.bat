@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
title FileMint - Windows Desktop Installer

echo ==================================================================
echo             ⚙️  Installing FileMint Desktop Engine
echo ==================================================================
echo.

:: 1. Script Location & Public Directory Resolution
set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

:: Resolve parent directory (Repository Root or Release Package Root)
for %%I in ("%SCRIPT_DIR%\..") do set "REPO_ROOT=%%~fI"

echo [*] Installer Location: %SCRIPT_DIR%
echo [*] Repository Root:   %REPO_ROOT%
echo.

:: 2. Target Directory Definitions
set "APP_DIR=%LOCALAPPDATA%\FileMint"
set "CONFIG_DIR=%APPDATA%\FileMint"
set "DESKTOP_DIR=%USERPROFILE%\Desktop"
set "START_MENU_DIR=%APPDATA%\Microsoft\Windows\Start Menu\Programs"

echo [*] Setting up installation folder: %APP_DIR%
if not exist "%APP_DIR%" mkdir "%APP_DIR%"
if not exist "%CONFIG_DIR%" mkdir "%CONFIG_DIR%"

:: 3. Python Runtime Audit
set "PYTHON_CMD="
where python >nul 2>nul
if !ERRORLEVEL! equ 0 (
    set "PYTHON_CMD=python"
) else (
    where py >nul 2>nul
    if !ERRORLEVEL! equ 0 set "PYTHON_CMD=py"
)

if defined PYTHON_CMD (
    echo [+] Python Runtime detected:
    %PYTHON_CMD% --version
) else (
    echo [!] Python command not found in System PATH. Checking for pre-compiled binary...
)

:: 4. Deploy Application Files & Configurations
echo.
echo [*] Deploying FileMint application files...

set "DEPLOYED_BIN=0"

:: Check for compiled binary in releases\ or package root
for %%F in ("%REPO_ROOT%\releases\FileMint-*.exe") do (
    if exist "%%~fF" (
        copy /Y "%%~fF" "%APP_DIR%\FileMint.exe" >nul
        echo [+] Deployed compiled executable: FileMint.exe
        set "DEPLOYED_BIN=1"
        goto :bin_found
    )
)

for %%F in ("%REPO_ROOT%\FileMint-*.exe") do (
    if exist "%%~fF" (
        copy /Y "%%~fF" "%APP_DIR%\FileMint.exe" >nul
        echo [+] Deployed compiled executable from package root.
        set "DEPLOYED_BIN=1"
        goto :bin_found
    )
)

:bin_found
if "!DEPLOYED_BIN!"=="0" (
    if exist "%REPO_ROOT%\filemint.py" (
        copy /Y "%REPO_ROOT%\filemint.py" "%APP_DIR%\filemint.py" >nul
        if exist "%REPO_ROOT%\core.py" copy /Y "%REPO_ROOT%\core.py" "%APP_DIR%\core.py" >nul
        if exist "%REPO_ROOT%\gui.py" copy /Y "%REPO_ROOT%\gui.py" "%APP_DIR%\gui.py" >nul
        echo [+] Deployed Python application scripts.
    ) else (
        echo [!] Warning: Neither compiled binary nor filemint.py source found.
    )
)


:: Deploy configuration templates
if exist "%REPO_ROOT%\config\appConfig.json" (
    copy /Y "%REPO_ROOT%\config\appConfig.json" "%CONFIG_DIR%\appConfig.json" >nul
    copy /Y "%REPO_ROOT%\config\appConfig.json" "%APP_DIR%\appConfig.json" >nul
    echo [+] Deployed appConfig.json configuration.
)
if exist "%REPO_ROOT%\config\fileOpsConfig.json" (
    copy /Y "%REPO_ROOT%\config\fileOpsConfig.json" "%CONFIG_DIR%\fileOpsConfig.json" >nul
    copy /Y "%REPO_ROOT%\config\fileOpsConfig.json" "%APP_DIR%\fileOpsConfig.json" >nul
    echo [+] Deployed fileOpsConfig.json configuration.
)

:: Deploy icon assets (.ico preferred for Windows shortcuts, .png as fallback)
set "ICON_FILE="
if exist "%REPO_ROOT%\assets\icons\filemint.ico" (
    copy /Y "%REPO_ROOT%\assets\icons\filemint.ico" "%APP_DIR%\filemint.ico" >nul
    set "ICON_FILE=%APP_DIR%\filemint.ico"
    echo [+] Deployed Windows icon asset (.ico).
) else if exist "%REPO_ROOT%\icons\filemint.ico" (
    copy /Y "%REPO_ROOT%\icons\filemint.ico" "%APP_DIR%\filemint.ico" >nul
    set "ICON_FILE=%APP_DIR%\filemint.ico"
    echo [+] Deployed Windows icon asset (.ico).
)

if exist "%REPO_ROOT%\assets\icons\filemint.png" (
    copy /Y "%REPO_ROOT%\assets\icons\filemint.png" "%APP_DIR%\filemint.png" >nul
    if exist "%REPO_ROOT%\assets\icons\icon.png" copy /Y "%REPO_ROOT%\assets\icons\icon.png" "%APP_DIR%\icon.png" >nul
    echo [+] Deployed PNG icon assets.
) else if exist "%REPO_ROOT%\icons\filemint.png" (
    copy /Y "%REPO_ROOT%\icons\filemint.png" "%APP_DIR%\filemint.png" >nul
    echo [+] Deployed PNG icon assets.
)

:: If no .ico exists but compiled .exe is present, use the executable's embedded icon
if not defined ICON_FILE (
    if exist "%APP_DIR%\FileMint.exe" (
        set "ICON_FILE=%APP_DIR%\FileMint.exe"
    )
)

:: 5. Create Quiet Background Launcher Script
echo [*] Creating background launcher script...
if "!PYTHON_CMD!"=="py" (
    set "LAUNCH_CMD=pyw"
) else (
    set "LAUNCH_CMD=pythonw"
)

if exist "%APP_DIR%\FileMint.exe" (
    (
        echo @echo off
        echo cd /d "%APP_DIR%"
        echo start "" "%APP_DIR%\FileMint.exe" %%*
    ) > "%APP_DIR%\launch_filemint.bat"
) else (
    (
        echo @echo off
        echo cd /d "%APP_DIR%"
        echo start "" !LAUNCH_CMD! "%APP_DIR%\filemint.py" %%*
    ) > "%APP_DIR%\launch_filemint.bat"
)


:: 6. Register Desktop & Start Menu Shortcuts via Temporary VBScript Helper
echo [*] Registering Desktop & Start Menu shortcuts...
set "VBS_SCRIPT=%TEMP%\CreateFileMintShortcuts.vbs"

(
    echo Set oWS = WScript.CreateObject("WScript.Shell"^)
    echo Set oLink = oWS.CreateShortcut("%DESKTOP_DIR%\FileMint.lnk"^)
    echo oLink.TargetPath = "%APP_DIR%\launch_filemint.bat"
    echo oLink.WorkingDirectory = "%APP_DIR%"
    echo oLink.Description = "File Consolidation and Archiving Engine"
    if defined ICON_FILE (
        echo oLink.IconLocation = "%ICON_FILE%"
    )
    echo oLink.Save

    echo Set oStartLink = oWS.CreateShortcut("%START_MENU_DIR%\FileMint.lnk"^)
    echo oStartLink.TargetPath = "%APP_DIR%\launch_filemint.bat"
    echo oStartLink.WorkingDirectory = "%APP_DIR%"
    echo oStartLink.Description = "File Consolidation and Archiving Engine"
    if defined ICON_FILE (
        echo oStartLink.IconLocation = "%ICON_FILE%"
    )
    echo oStartLink.Save
) > "%VBS_SCRIPT%"

cscript //nologo "%VBS_SCRIPT%"
del /f /q "%VBS_SCRIPT%" >nul 2>&1

echo.
echo ==================================================================
echo 🎉 FileMint successfully installed on Windows!
echo ==================================================================
echo 📁 Application Directory:  %APP_DIR%
echo ⚙️ Configuration Directory: %CONFIG_DIR%
echo 🖥️ Desktop Shortcut:      %DESKTOP_DIR%\FileMint.lnk
echo 📌 Start Menu Entry:      %START_MENU_DIR%\FileMint.lnk
echo ==================================================================
echo.
pause
