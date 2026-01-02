@echo off
setlocal enabledelayedexpansion

:: --- List audio devices ---
echo Available audio devices:

:: Create temporary file to store device info
if exist devices.tmp del devices.tmp
set count=0

for /f "tokens=2 delims=\""" %%a in ('ffmpeg -list_devices true -f dshow -i dummy 2^>^&1 ^| findstr /R /C:"\".*\" (audio)"') do (
    set /a count+=1
    echo !count!. %%a
    echo %%a>>devices.tmp
)

:: --- User selects devices ---
echo.
set /p device_nums="Enter numbers of audio devices (comma separated, e.g., 1,3): "
if "!device_nums!"=="" (
    echo No selection made. Exiting.
    if exist devices.tmp del devices.tmp
    pause
    exit /b
)

:: --- Build audio inputs ---
echo.
echo --- DEBUG: Selected audio devices ---

set audio_inputs=
set device_count=0

for %%d in (!device_nums!) do (
    set /a device_count+=1
    set line_num=0
    
    for /f "usebackq delims=" %%i in ("devices.tmp") do (
        set /a line_num+=1
        if !line_num! EQU %%d (
            echo Device %%d = %%i
            set "audio_inputs=!audio_inputs! -f dshow -i audio=""%%i"""
        )
    )
)

:: Clean up
if exist devices.tmp del devices.tmp

:: --- Build FFmpeg command ---
echo.
echo --- DEBUG: FFmpeg command ---
echo Device count: !device_count!
echo Audio inputs: !audio_inputs!

if !device_count! GTR 1 (
    :: Multiple devices - need to mix them
    set amix_inputs=
    set counter=0
    for %%d in (!device_nums!) do (
        if !counter! EQU 0 (
            set amix_inputs=[!counter!:a]
        ) else (
            set amix_inputs=!amix_inputs![!counter!:a]
        )
        set /a counter+=1
    )
    set filter_complex=!amix_inputs!amix=inputs=!device_count!:duration=longest[aout]
    echo Filter: !filter_complex!
    echo Command: ffmpeg !audio_inputs! -filter_complex "!filter_complex!" -map "[aout]" -c:a aac -b:a 192k "audio_recording.mkv"
) else (
    :: Single device
    echo Command: ffmpeg !audio_inputs! -c:a aac -b:a 192k "audio_recording.mkv"
)

echo.
set /p start_recording="Start recording? (y/n): "
if /i "!start_recording!" NEQ "y" (
    echo Recording cancelled.
    pause
    exit /b
)

:: --- Execute recording ---
echo.
echo Starting audio recording... Press Ctrl+C to stop.
if !device_count! GTR 1 (
    ffmpeg !audio_inputs! -filter_complex "!filter_complex!" -map "[aout]" -c:a aac -b:a 192k "audio_recording.mkv"
) else (
    ffmpeg !audio_inputs! -c:a aac -b:a 192k "audio_recording.mkv"
)

echo.
echo Recording completed! File saved as audio_recording.mkv
pause
