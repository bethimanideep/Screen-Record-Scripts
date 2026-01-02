@echo off
setlocal enabledelayedexpansion
title Screen Recorder (One Window)

:: --- Timestamp for filenames (YYYYMMDD_HHMMSS) ---
for /f "tokens=1-4 delims=/ " %%a in ('date /t') do set mm=%%a& set dd=%%b& set yyyy=%%c
for /f "tokens=1-3 delims=:." %%a in ("%time%") do set hh=%%a& set nn=%%b& set ss=%%c

:: Remove spaces if any
set hh=%hh: =0%
set nn=%nn: =0%
set ss=%ss: =0%

set timestamp=%yyyy%%mm%%dd%_%hh%%nn%%ss%
set video_file=video_%timestamp%.mkv
set final_file=Recording_%timestamp%.mp4

echo ================================
echo   Auto Screen Recorder Started
echo ================================
echo Recording file: %video_file%
echo Press Ctrl+C to stop recording and process file.
echo.

:: --- Run FFmpeg in the same window silently ---
ffmpeg -y -f gdigrab -framerate 60 -i desktop -c:v h264_qsv -pix_fmt nv12 -b:v 8M -preset veryfast -vsync cfr -f matroska "%video_file%" -loglevel quiet -nostats

echo.
echo Recording stopped or interrupted.

:: --- POST-PROCESSING ---
echo ================================
echo Processing recorded file...
echo ================================

if not exist "%video_file%" (
    echo ❌ Error: Video file not found.
    pause
    exit /b 1
)

:: Convert to MP4 silently
ffmpeg -y -i "%video_file%" -c:v copy "%final_file%" -loglevel quiet -nostats

if exist "%final_file%" (
    del "%video_file%" >nul 2>&1
    echo ✅ Recording completed!
    echo Final file: %final_file%
) else (
    echo ❌ Conversion failed. Original MKV file kept.
    echo File: %video_file%
)

pause
exit /b
