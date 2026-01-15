@echo off
echo ===================================================
echo      Fixing Android Environment (Round 2)
echo ===================================================

set SDK_PATH=%LOCALAPPDATA%\Android\Sdk
set CMDLINE_TOOLS_PATH=%SDK_PATH%\cmdline-tools
set BIN_PATH=%CMDLINE_TOOLS_PATH%\latest\bin

if not exist "%BIN_PATH%\sdkmanager.bat" (
    echo [!] sdkmanager still not found. Please ensure the previous run completed.
    pause
    exit /b
)

echo [OK] sdkmanager found.
echo.
echo ===================================================
echo      Installing Missing Components
echo ===================================================
echo.
echo This may take a few minutes. Please wait...
echo.

call "%BIN_PATH%\sdkmanager.bat" "platform-tools" "platforms;android-34" "platforms;android-35" "build-tools;34.0.0" "build-tools;35.0.0"

echo.
echo ===================================================
echo      Accepting Licenses (Again to be safe)
echo ===================================================
echo.
call "%BIN_PATH%\sdkmanager.bat" --licenses

echo.
echo ===================================================
echo      Fix Complete!
echo ===================================================
echo You can now run the app.
pause
