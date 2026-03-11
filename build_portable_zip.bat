@echo off
setlocal
cd /d "%~dp0"

echo [1/3] Building EXE...
call build_exe.bat --no-pause
if %errorlevel% neq 0 (
  echo Build failed.
  exit /b 1
)

echo [2/3] Creating portable ZIP...
if not exist "dist\\DnD_MAPS\\DnD_MAPS.exe" (
  echo EXE not found: dist\\DnD_MAPS\\DnD_MAPS.exe
  exit /b 1
)

if exist "dist\\DnD_MAPS_portable.zip" del /f /q "dist\\DnD_MAPS_portable.zip"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Compress-Archive -Path 'dist\\DnD_MAPS\\*' -DestinationPath 'dist\\DnD_MAPS_portable.zip' -Force"
if %errorlevel% neq 0 (
  echo ZIP creation failed.
  exit /b 1
)

echo [3/3] Done.
echo Portable archive: dist\\DnD_MAPS_portable.zip
pause
