@echo off
setlocal enabledelayedexpansion

:: Temp file to capture FFmpeg output
set "tmpfile=%temp%\ff_devices.txt"

:: Run ffmpeg to list devices
ffmpeg -list_devices true -f dshow -i dummy >nul 2>"%tmpfile%"

echo ===========================================
echo   Available Audio Devices
echo ===========================================

set count=0
for /f "tokens=*" %%A in ('findstr /C:"(audio)" "%tmpfile%"') do (
    set /a count+=1
    set "device[!count!]=%%A"
    echo !count!. %%A
)

if %count%==0 (
    echo No audio devices found.
    pause
    goto :eof
)

echo ===========================================
set /p "choice=Select device number (1-%count%): "

if "%choice%"=="" (
    pause
    goto :eof
)

if %choice% gtr %count% (
    echo Invalid choice
    pause
    goto :eof
)

echo You selected: !device[%choice%]!

:: Alternative 3 - Using a temporary file (most reliable)
echo !device[%choice%]! > "%temp%\tempdevice.txt"
for /f "tokens=2 delims=^"" %%B in ('type "%temp%\tempdevice.txt"') do (
    echo Device name: "%%B"
)
del "%temp%\tempdevice.txt"

pause