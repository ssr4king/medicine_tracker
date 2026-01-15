@echo off
set SDK_PATH=%LOCALAPPDATA%\Android\Sdk
set TOOLS_PATH=%SDK_PATH%\tools\bin

if not exist "%TOOLS_PATH%\sdkmanager.bat" (
    echo [!] sdkmanager not found at %TOOLS_PATH%
    exit /b 1
)

echo Installing build-tools;30.0.3...
call "%TOOLS_PATH%\sdkmanager.bat" "build-tools;30.0.3"

echo Done.
exit /b 0
