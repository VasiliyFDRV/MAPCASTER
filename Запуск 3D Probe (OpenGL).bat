@echo off
setlocal
cd /d "%~dp0"
set MAPCASTER_3D_PROBE=1
set MAPCASTER_GFX_API=opengl
python -m app.main
if errorlevel 1 py -3 -m app.main

echo.
echo [3D PROBE][OpenGL] Exit code: %errorlevel%
pause
endlocal
