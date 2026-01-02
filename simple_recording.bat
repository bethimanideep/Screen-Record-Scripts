echo.
echo --- FFmpeg audio command ---
if !device_count! GTR 1 (
    echo ffmpeg !audio_inputs! -filter_complex "!filter_complex!" !map_audio! -c:a aac -b:a 192k -f matroska "%audio_file%"
) else (
    echo ffmpeg !audio_inputs! -c:a aac -b:a 192k -f matroska "%audio_file%"
)
echo.
pause
