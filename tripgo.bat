@echo off
setlocal
cd /d "%~dp0"

rem ============================================================
rem  TripGo one-click APK builder
rem
rem  The Django backend is bundled into the APK, so the phone needs
rem  nothing else installed. Running this file:
rem    1. creates the Python env used to resolve the bundled packages
rem    2. downloads Flutter dependencies
rem    3. deletes the previous APK and builds a new self-contained one
rem  No options needed.
rem ============================================================

if "%FLUTTER_HOME%"=="" set "FLUTTER_HOME=C:\Users\mkail\flutter"
if not exist "%FLUTTER_HOME%\bin\flutter.bat" set "FLUTTER_HOME=%LOCALAPPDATA%\flutter"
if "%ANDROID_HOME%"=="" set "ANDROID_HOME=C:\Users\mkail\Android\Sdk"
set "ANDROID_SDK_ROOT=%ANDROID_HOME%"
set "PATH=%FLUTTER_HOME%\bin;%ANDROID_HOME%\platform-tools;%ANDROID_HOME%\cmdline-tools\latest\bin;%ANDROID_HOME%\build-tools\36.0.0;%PATH%"

set "BACKEND=%~dp0backend"
set "FRONTEND=%~dp0frontend"
rem NB: no delayed expansion here, so %BACKEND% (not !BACKEND!) must be used.
set "PY=%BACKEND%\.venv\Scripts\python.exe"
set "APK=%FRONTEND%\build\app\outputs\flutter-apk\app-release.apk"

echo.
echo  ============================================================
echo    TripGo: building the self-contained APK
echo  ============================================================

echo.
echo  [1/4] Preparing the Python env used to resolve the bundled packages...
if not exist "%PY%" (
  python -m venv "%BACKEND%\.venv"
  if errorlevel 1 (
    echo  [ERROR] Could not create the Python venv. Install Python 3.13 and try again.
    pause
    exit /b 1
  )
)
"%PY%" -m pip install --upgrade pip --quiet
if errorlevel 1 (
  echo  [ERROR] Could not upgrade pip.
  pause
  exit /b 1
)

echo.
echo  [2/4] Checking the toolchain...
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
for /f "delims=" %%v in ('"%PY%" -c "import sys;print('%%d.%%d' %% sys.version_info[:2])"') do set "PYVER=%%v"
echo  - Flutter:  %FLUTTER_HOME%
echo  - Android:  %ANDROID_HOME%
echo  - Python:   %PYVER% ^(must be 3.13, Chaquopy matches the bundled runtime to it^)

echo.
echo  [3/4] Downloading Flutter dependencies...
pushd "%FRONTEND%"
call "%FLUTTER_HOME%\bin\flutter.bat" pub get
if errorlevel 1 (
  popd
  echo  [ERROR] Flutter pub get failed.
  pause
  exit /b 1
)

echo.
echo  [4/4] Removing the old APK and building the new one...
if exist "%APK%" del /q "%APK%"
if exist "%FRONTEND%\build\app\outputs\apk\release" rd /s /q "%FRONTEND%\build\app\outputs\apk\release"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\fix_printing.ps1"
rem  No --dart-define on purpose: the app must keep the embedded 127.0.0.1 URL.
call "%FLUTTER_HOME%\bin\flutter.bat" build apk --release
set "BUILD_EXIT=%ERRORLEVEL%"
popd

if not "%BUILD_EXIT%"=="0" (
  echo.
  echo  [ERROR] APK build failed. See the messages above.
  pause
  exit /b 1
)

if not exist "%APK%" (
  echo.
  echo  [ERROR] The build reported success but %APK% is missing.
  pause
  exit /b 1
)

echo.
echo  ============================================================
echo    DONE! Your new self-contained APK is ready:
echo    %APK%
echo.
echo    The Django server starts by itself when the app opens and
echo    stops by itself when the app is closed. Install it on any
echo    Android phone - no other setup is needed.
echo  ============================================================
pause
