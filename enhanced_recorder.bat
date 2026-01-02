@echo off
setlocal enabledelayedexpansion

echo ================================
echo Enhanced Screen + Audio Recorder
echo ================================
echo.

:: --- DEVICE SELECTION PHASE ---
echo Step 1: Audio Device Selection
echo ==============================

:: List available audio devices
echo Available audio devices:
echo 1. Headset (EarPods)
echo 2. Microphone (Realtek(R) Audio)  
echo 3. Stereo Mix (Realtek(R) Audio)

:: User selection
echo.
set /p device_nums="Enter numbers of audio devices (comma separated, e.g., 1,3): "
if "!device_nums!"=="" (
    echo No audio devices selected. Exiting.
    pause
    exit /b
)

:: Map device numbers to names
set device1=Headset (EarPods)
set device2=Microphone (Realtek(R) Audio)
set device3=Stereo Mix (Realtek(R) Audio)

:: Build audio inputs
echo.
echo Selected Devices:
set audio_inputs=
set device_count=0

for %%d in (!device_nums!) do (
    set /a device_count+=1
    if %%d==1 set "current_device=!device1!"
    if %%d==2 set "current_device=!device2!"
    if %%d==3 set "current_device=!device3!"
    
    echo - Device %%d: !current_device!
    set "audio_inputs=!audio_inputs! -f dshow -i audio=^"!current_device!^""
)

:: Build audio command based on device count
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
    set filter_complex=-filter_complex "!amix_inputs!amix=inputs=!device_count!:duration=longest[aout]"
    set map_audio=-map "[aout]"
) else (
    :: Single device
    set filter_complex=
    set map_audio=
)

echo.
echo Audio command preview:
if !device_count! GTR 1 (
    echo ffmpeg !audio_inputs! !filter_complex! !map_audio! -c:a aac -b:a 192k [audio_file]
) else (
    echo ffmpeg !audio_inputs! -c:a aac -b:a 192k [audio_file]
)

:: --- RECORDING PREPARATION PHASE ---
echo.
echo Step 2: Recording Preparation
echo ==============================

:: Timestamp generation
for /f "tokens=1-4 delims=/ " %%a in ('date /t') do set mm=%%a& set dd=%%b& set yyyy=%%c
for /f "tokens=1-2 delims=: " %%a in ('time /t') do set hh=%%a& set nn=%%b
set timestamp=%yyyy%%mm%%dd%_%hh%%nn%
set video_file=video_%timestamp%.mkv
set audio_file=audio_%timestamp%.mkv
set final_file=Recording_%timestamp%.mp4

echo Video file: %video_file%
echo Audio file: %audio_file%
echo Final file: %final_file%

:: Confirm start
echo.
set /p start_recording="Start recording? (y/n): "
if /i "!start_recording!" NEQ "y" (
    echo Recording cancelled.
    pause
    exit /b
)

:: --- RECORDING EXECUTION PHASE ---
echo.
echo Step 3: Starting Recording
echo ===========================

:: Start audio recording with selected devices
echo Starting audio recording...
if !device_count! GTR 1 (
    start "Audio Recording" /min cmd /c "ffmpeg !audio_inputs! !filter_complex! !map_audio! -c:a aac -b:a 192k -f matroska %audio_file% && echo Audio recording finished && pause"
) else (
    start "Audio Recording" /min cmd /c "ffmpeg !audio_inputs! -c:a aac -b:a 192k -f matroska %audio_file% && echo Audio recording finished && pause"
)

:: Wait before starting screen recording
echo Waiting 2 seconds before starting screen recording...
timeout /t 2 >nul

:: Start screen recording
echo Starting screen recording...
start "Screen Recording" /min cmd /c "ffmpeg -f gdigrab -framerate 60 -i desktop -c:v h264_qsv -pix_fmt yuv420p -b:v 8M -preset veryfast -vsync cfr -f matroska %video_file% && echo Screen recording finished && pause"

echo.
echo ========================================
echo Recording started successfully!
echo ========================================
echo.
echo INSTRUCTIONS:
echo 1. Press Ctrl+C in BOTH recording windows to stop recording
echo 2. Wait for both windows to show "finished" message  
echo 3. Press any key in each window to close them
echo 4. Then press ENTER here to merge the files
echo.
echo Press ENTER when both recording windows are closed...
pause >nul

:: --- PROCESSING PHASE ---
echo.
echo Step 4: Processing Files
echo ========================

:: Enhanced waiting loop - check for actual FFmpeg processes
echo Checking for remaining FFmpeg processes...
:waitLoop
tasklist /fi "imagename eq ffmpeg.exe" 2>nul | find /i "ffmpeg.exe" >nul
if %errorlevel%==0 (
    echo FFmpeg processes still running... waiting
    timeout /t 2 >nul
    goto waitLoop
)

:: Additional wait to ensure file handles are released
echo All FFmpeg processes stopped. Waiting for file handles to be released...
timeout /t 3 >nul

:: File validation
echo Validating recorded files...
if not exist "%video_file%" (
    echo ERROR: Video file does not exist!
    pause
    exit /b 1
)
if not exist "%audio_file%" (
    echo ERROR: Audio file does not exist!
    pause
    exit /b 1
)

:: Check file sizes
for %%i in ("%video_file%") do set video_size=%%~zi
for %%i in ("%audio_file%") do set audio_size=%%~zi

if %video_size%==0 (
    echo ERROR: Video file is empty!
    pause
    exit /b 1
)
if %audio_size%==0 (
    echo ERROR: Audio file is empty!
    pause
    exit /b 1
)

echo ✓ Video file: %video_size% bytes
echo ✓ Audio file: %audio_size% bytes
echo.

:: --- MERGE PHASE ---
echo Step 5: Merging Files
echo =====================

echo Merging video and audio files...
ffmpeg -y -i "%video_file%" -i "%audio_file%" -c:v copy -c:a copy "%final_file%"

if %errorlevel%==0 (
    echo.
    echo ✓ Merge successful!
    echo.
    echo Cleaning up temporary files...
    del "%video_file%" "%audio_file%"
    echo.
    echo ========================================
    echo RECORDING COMPLETED SUCCESSFULLY!
    echo ========================================
    echo.
    echo Final file: %final_file%
    
    :: Show final file info
    for %%i in ("%final_file%") do set final_size=%%~zi
    echo File size: %final_size% bytes
    
    :: Open file location
    echo.
    set /p open_folder="Open file location? (y/n): "
    if /i "!open_folder!"=="y" (
        explorer /select,"%final_file%"
    )
) else (
    echo.
    echo ERROR: Merge failed! 
    echo Temporary files kept for debugging:
    echo - Video: %video_file%
    echo - Audio: %audio_file%
)

echo.
pause
