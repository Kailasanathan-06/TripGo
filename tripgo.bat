@echo off
setlocal
cd /d "%~dp0"

rem ============================================================
rem  TripGo one-click builder
rem  Running this file directly builds the mobile APK:
rem    1. creates the Python env + installs requirements
rem    2. builds the release APK
rem  No options needed.
rem ============================================================

if "%FLUTTER_HOME%"=="" set "FLUTTER_HOME=C:\Users\mkail\flutter"
if not exist "%FLUTTER_HOME%\bin\flutter.bat" set "FLUTTER_HOME=%LOCALAPPDATA%\flutter"
if "%ANDROID_HOME%"=="" set "ANDROID_HOME=C:\Users\mkail\Android\Sdk"
set "ANDROID_SDK_ROOT=%ANDROID_HOME%"
set "PATH=%FLUTTER_HOME%\bin;%ANDROID_HOME%\platform-tools;%ANDROID_HOME%\cmdline-tools\latest\bin;%ANDROID_HOME%\build-tools\36.0.0;%PATH%"

set "BACKEND=%~dp0backend"
set "FRONTEND=%~dp0frontend"
set "PY=!BACKEND!\.venv\Scripts\python.exe"

echo.
echo  ============================================================
echo    TripGo: building the mobile APK
echo  ============================================================

echo.
echo  [1/3] Creating Python env and installing requirements...
if not exist "%PY%" (
  python -m venv "%BACKEND%\.venv"
  if errorlevel 1 (
    echo  [ERROR] Could not create the Python venv. Install Python and try again.
    pause
    exit /b 1
  )
)
"%PY%" -m pip install --upgrade pip --quiet
"%PY%" -m pip install -r "%BACKEND%\requirements.txt"
echo  [1/3] Requirements installed.

echo.
echo  [2/3] Downloading Flutter dependencies...
if not exist "%FLUTTER_HOME%\bin\flutter.bat" (
  echo  [ERROR] Flutter not found at %FLUTTER_HOME%. Set FLUTTER_HOME to your SDK.
  pause
  exit /b 1
)
if not exist "%ANDROID_HOME%\platforms\android-36" (
  echo  [ERROR] Android SDK not found at %ANDROID_HOME%. Set ANDROID_HOME.
  pause
  exit /b 1
)
pushd "%FRONTEND%"
call "%FLUTTER_HOME%\bin\flutter.bat" pub get
if errorlevel 1 (
  popd
  echo  [ERROR] Flutter pub get failed.
  pause
  exit /b 1
)

echo.
echo  [3/3] Building the release APK (first run downloads Gradle)...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\fix_printing.ps1"
call "%FLUTTER_HOME%\bin\flutter.bat" build apk --release
set "BUILD_EXIT=%ERRORLEVEL%"
popd

if not "%BUILD_EXIT%"=="0" (
  echo.
  echo  [ERROR] APK build failed. See the messages above.
  pause
  exit /b 1
)

echo.
echo  ============================================================
echo    DONE! Your mobile APK is ready:
echo    %FRONTEND%\build\app\outputs\flutter-apk\app-release.apk
echo.
echo    Copy it to an Android phone and install it.
echo  ============================================================
pause