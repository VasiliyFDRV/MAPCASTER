@echo off
setlocal
cd /d "%~dp0"
set "NO_PAUSE="
if /I "%~1"=="--no-pause" set "NO_PAUSE=1"

echo [1/4] Checking Python...
where python >nul 2>nul
if %errorlevel% neq 0 (
  echo Python is not found in PATH.
  echo Install Python 3.10+ and run this script again.
  pause
  exit /b 1
)

echo [2/4] Installing dependencies...
python -m pip install --upgrade pip
if %errorlevel% neq 0 exit /b 1
python -m pip install PySide6
if %errorlevel% neq 0 exit /b 1
python -m pip install pyinstaller
if %errorlevel% neq 0 exit /b 1

echo [3/4] Building EXE...
python -m PyInstaller ^
  --noconfirm ^
  --clean ^
  --windowed ^
  --name "DnD_MAPS" ^
  --collect-all PySide6 ^
  --add-data "app\\ui\\qml;app\\ui\\qml" ^
  app\\main.py
if %errorlevel% neq 0 exit /b 1

echo [4/4] Preparing portable folders...
if not exist "dist\\DnD_MAPS\\adventures" mkdir "dist\\DnD_MAPS\\adventures"
if not exist "dist\\DnD_MAPS\\app_data" mkdir "dist\\DnD_MAPS\\app_data"

echo.
echo Build complete.
echo EXE: dist\\DnD_MAPS\\DnD_MAPS.exe
echo Copy the whole folder "dist\\DnD_MAPS" to another PC.
if not defined NO_PAUSE pause
