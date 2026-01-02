@echo off
setlocal enabledelayedexpansion

:: =============================================
:: Audio Device Selection and Recording Script
:: =============================================

:: --- Configuration ---
set OUTPUT_FOLDER=Recordings
if not exist "%OUTPUT_FOLDER%" mkdir "%OUTPUT_FOLDER%"

:: --- List available audio devices ---
:listDevices
cls
echo.
echo ===== AVAILABLE AUDIO INPUT DEVICES =====
echo.

:: Get devices using ffmpeg
ffmpeg -list_devices true -f dshow -i dummy 2> devices.txt
find "audio" devices.txt > audio_devices.txt

:: Display numbered list
set /a counter=0
for /f "tokens=2 delims=^"" %%a in ('type audio_devices.txt ^| find "audio" ^| find /v "Alternative"') do (
    set /a counter+=1
    set "device_!counter!=%%a"
    echo [!counter!] %%a
)

if %counter%==0 (
    echo No audio input devices found!
    echo.
    echo Troubleshooting:
    echo 1. Check microphone is connected/enabled
    echo 2. Verify Windows sound settings
    echo 3. Try running as Administrator
    echo.
    pause
    exit /b 1
)

:: --- User selection ---
echo.
echo INSTRUCTIONS:
echo 1. For microphone only: select its number
echo 2. For system audio only: select "Stereo Mix"
echo 3. For both: select both numbers (e.g., 1,3)
echo.
set /p device_nums="Enter device numbers (comma separated): "
if "!device_nums!"=="" (
    echo No selection made. Please try again.
    timeout /t 2 >nul
    goto listDevices
)

:: --- Validate selection ---
set invalid=0
for %%d in (!device_nums!) do (
    if %%d LSS 1 (
        set invalid=1
    ) else if %%d GTR !counter! (
        set invalid=1
    )
)

if !invalid!==1 (
    echo Invalid selection. Numbers must be between 1 and !counter!
    timeout /t 2 >nul
    goto listDevices
)

:: --- Build FFmpeg command ---
set audio_inputs=
set filter_inputs=
set device_count=0

echo.
echo === SELECTED DEVICES ===
for %%d in (!device_nums!) do (
    set /a device_count+=1
    set "current_device=!device_%%d!"
    
    :: Properly escape quotes in device name
    set "current_device=!current_device:"=""!"
    
    echo Device !device_count!: !current_device!
    set audio_inputs=!audio_inputs! -f dshow -i audio="!current_device!"
    set filter_inputs=!filter_inputs![%device_count%-1:a]
)

:: Build filter complex if multiple devices
if !device_count! GTR 1 (
    set filter_complex=!filter_inputs!amix=inputs=!device_count!:duration=longest[aout]
    set map_audio=-map "[aout]"
    echo Audio Mixing: Enabled (combining !device_count! inputs)
) else (
    set filter_complex=
    set map_audio=
    echo Audio Mixing: Disabled (single input)
)

:: --- File naming ---
for /f "tokens=1-4 delims=/ " %%a in ('date /t') do set mm=%%a& set dd=%%b& set yyyy=%%c
for /f "tokens=1-2 delims=: " %%a in ('time /t') do set hh=%%a& set nn=%%b
set timestamp=%yyyy%%mm%%dd%_%hh%%nn%
set audio_file="%OUTPUT_FOLDER%\audio_%timestamp%.mkv"

:: --- Show final command ---
echo.
echo === FFMPEG COMMAND ===
if !device_count! GTR 1 (
    echo ffmpeg !audio_inputs! -filter_complex "!filter_complex!" !map_audio! -c:a aac -b:a 192k !audio_file!
) else (
    echo ffmpeg !audio_inputs! -c:a aac -b:a 192k !audio_file!
)

:: --- Start recording ---
echo.
set /p confirm="Start recording with these settings? (Y/N): "
if /i "!confirm!" NEQ "Y" (
    echo Recording cancelled.
    pause
    exit /b
)

echo.
echo Starting audio recording...
echo Output file: !audio_file!
echo Press Ctrl+C to stop recording.
echo.

if !device_count! GTR 1 (
    ffmpeg !audio_inputs! -filter_complex "!filter_complex!" !map_audio! -c:a aac -b:a 192k !audio_file!
) else (
    ffmpeg !audio_inputs! -c:a aac -b:a 192k !audio_file!
)

if errorlevel 1 (
    echo.
    echo ERROR: Recording failed!
) else (
    echo.
    echo Recording completed successfully!
)

:: Cleanup
del devices.txt audio_devices.txt 2>nul
pause