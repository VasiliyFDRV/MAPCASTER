@echo off
cd /d "%~dp0"
where python >nul 2>nul
if %errorlevel%==0 (
  python -m app.main
) else (
  py -3 -m app.main
)
pause
