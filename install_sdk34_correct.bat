@echo off
set SDK_PATH=%LOCALAPPDATA%\Android\Sdk
set BIN_PATH=%SDK_PATH%\tools\bin

if not exist "%BIN_PATH%\sdkmanager.bat" (
    echo [!] sdkmanager still not found at %BIN_PATH%
    exit /b
)

echo Installing Android 34 Platform...
call "%BIN_PATH%\sdkmanager.bat" "platforms;android-34" "build-tools;34.0.0"

echo Accepting Licenses...
call "%BIN_PATH%\sdkmanager.bat" --licenses

echo Done.
