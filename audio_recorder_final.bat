@echo off
setlocal enabledelayedexpansion

echo Audio Recording Script
echo =====================

:: List available audio devices
echo.
echo Available audio devices:
echo 1. Headset (EarPods)
echo 2. Microphone (Realtek(R) Audio)
echo 3. Stereo Mix (Realtek(R) Audio)

:: User selection
echo.
set /p device_nums="Enter numbers of audio devices (comma separated, e.g., 1,3): "
if "!device_nums!"=="" (
    echo No selection made. Exiting.
    pause
    exit /b
)

:: Map device numbers to names
set device1=Headset (EarPods)
set device2=Microphone (Realtek(R) Audio)
set device3=Stereo Mix (Realtek(R) Audio)

:: Build audio inputs
echo.
echo --- Selected Devices ---
set audio_inputs=
set device_count=0

for %%d in (!device_nums!) do (
    set /a device_count+=1
    if %%d==1 set "current_device=!device1!"
    if %%d==2 set "current_device=!device2!"
    if %%d==3 set "current_device=!device3!"
    
    echo Device %%d = !current_device!
    set "audio_inputs=!audio_inputs! -f dshow -i audio=^"!current_device!^""
)

:: Build FFmpeg command
echo.
echo --- FFmpeg Command ---
echo Device count: !device_count!

if !device_count! GTR 1 (
    :: Multiple devices - mix them
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

:: Confirm and start recording
echo.
set /p start_recording="Start recording? (y/n): "
if /i "!start_recording!" NEQ "y" (
    echo Recording cancelled.
    pause
    exit /b
)

echo.
echo Starting audio recording... Press Ctrl+C to stop recording.
echo Output file: audio_recording.mkv
echo.

if !device_count! GTR 1 (
    ffmpeg !audio_inputs! -filter_complex "!filter_complex!" -map "[aout]" -c:a aac -b:a 192k "audio_recording.mkv"
) else (
    ffmpeg !audio_inputs! -c:a aac -b:a 192k "audio_recording.mkv"
)

if !errorlevel! EQU 0 (
    echo.
    echo Recording completed successfully!
    echo File saved as: audio_recording.mkv
) else (
    echo.
    echo Recording failed or was interrupted.
)

pause
