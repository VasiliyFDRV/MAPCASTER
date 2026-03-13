@echo off
setlocal
cd /d "%~dp0"
set MAPCASTER_3D_PROBE=1

where python >nul 2>nul
if %errorlevel%==0 (
  python -m app.main
) else (
  py -3 -m app.main
)

echo.
echo [3D PROBE] Exit code: %errorlevel%
pause
endlocal
