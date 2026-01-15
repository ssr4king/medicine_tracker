@echo off
set SDK_PATH=%LOCALAPPDATA%\Android\Sdk
set CMDLINE_TOOLS_PATH=%SDK_PATH%\cmdline-tools
set BIN_PATH=%CMDLINE_TOOLS_PATH%\latest\bin

if not exist "%BIN_PATH%\sdkmanager.bat" (
    echo [!] sdkmanager not found.
    exit /b
)

echo Installing Android 34 Platform...
call "%BIN_PATH%\sdkmanager.bat" "platforms;android-34" "build-tools;34.0.0"

echo Accepting Licenses...
call "%BIN_PATH%\sdkmanager.bat" --licenses

echo Done.
