@echo off
setlocal
cd /d "%~dp0"
set MAPCASTER_WEB_DICE_PROBE=1

where python >nul 2>nul
if %errorlevel%==0 (
  python -m app.main
) else (
  py -3 -m app.main
)

echo.
echo [WEB DICE PROBE] Exit code: %errorlevel%
pause
endlocal
