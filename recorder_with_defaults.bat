@echo off
setlocal enabledelayedexpansion

:: Step 1: List all audio devices
echo Listing available audio devices...
echo.
ffmpeg -list_devices true -f dshow -i dummy 2> devices.txt

:: Step 2: Extract only audio devices
findstr /C:"Alternative name" devices.txt >nul
if %errorlevel% equ 0 (
    :: For newer FFmpeg builds
    findstr /C:"\"audio=" devices.txt > audio_devices.txt
) else (
    :: For older FFmpeg builds
    findstr /C:"  \" audio devices.txt > audio_devices.txt
)

:: Step 3: Build menu dynamically
set count=0
echo Available audio devices:
for /f "tokens=* delims=" %%A in (audio_devices.txt) do (
    set /a count+=1
    set "device!count!=%%A"
    echo !count!. %%A
)

:: Step 4: Ask user to choose device
set /p choice="Enter the number of the audio device to record: "

if not defined device%choice% (
    echo Invalid choice!
    exit /b
)

set selected=!device%choice%!

:: Step 5: Clean up device name
set selected=%selected:~,-1%
set selected=%selected:audio=%
set selected=%selected:"=%

echo.
echo Recording from: %selected%
echo Press CTRL+C to stop recording.
echo.

:: Step 6: Run ffmpeg with chosen device
ffmpeg -f dshow -i audio="%selected%" -c:a aac -b:a 192k output_audio.mp4
