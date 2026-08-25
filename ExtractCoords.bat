@echo off
setlocal EnableExtensions DisableDelayedExpansion

rem === Basic settings ===
set "SCRIPT_DIR=%~dp0"
set "OUTPUT_FILE=%~dp0BlockLocator_Coordinates.txt"

set "LOG_FILE="
set "CANDIDATE_LOG="
set "FOUND_GAME_FOLDER=0"

echo Searching for latest.log in recognized Minecraft folders...

set "SEARCH_DIR=%SCRIPT_DIR%"

:find_loop
rem Normalize current directory path
for %%I in ("%SEARCH_DIR%.") do set "CURRENT_DIR=%%~fI"

rem Get current folder name
set "FOLDER_NAME="
for %%I in ("%CURRENT_DIR%") do set "FOLDER_NAME=%%~nxI"

rem === Recognized Minecraft folder names ===
rem You can add more folder names here if needed.
if /I "%FOLDER_NAME%"==".minecraft" set "FOUND_GAME_FOLDER=1"
if /I "%FOLDER_NAME%"=="minecraft" set "FOUND_GAME_FOLDER=1"
if /I "%FOLDER_NAME%"=="Minecraft" set "FOUND_GAME_FOLDER=1"
if /I "%FOLDER_NAME%"=="Minecraft Launcher" set "FOUND_GAME_FOLDER=1"

rem Try to find the nearest logs\latest.log while going upward
if not defined CANDIDATE_LOG (
    if exist "%CURRENT_DIR%\logs\latest.log" (
        set "CANDIDATE_LOG=%CURRENT_DIR%\logs\latest.log"
    )
)

rem Use the found log only if a recognized Minecraft folder was found
if "%FOUND_GAME_FOLDER%"=="1" (
    if defined CANDIDATE_LOG (
        set "LOG_FILE=%CANDIDATE_LOG%"
        goto found_log
    )
)

rem Go to parent folder
for %%I in ("%CURRENT_DIR%\..") do set "PARENT_DIR=%%~fI"

rem If parent is the same as current folder, the drive root has been reached
if /I "%PARENT_DIR%"=="%CURRENT_DIR%" goto no_auto_log

set "SEARCH_DIR=%PARENT_DIR%"
goto find_loop

:no_auto_log
echo.
if "%FOUND_GAME_FOLDER%"=="1" (
    echo A Minecraft folder was recognized, but latest.log was not found.
    echo Run Minecraft at least once or specify the log file path manually.
) else (
    echo The script is not inside a recognized Minecraft folder.
    echo Move the script into the game folder or specify the path to latest.log manually.
)

if defined CANDIDATE_LOG (
    echo Possible log file found: "%CANDIDATE_LOG%"
)

:manual_input
echo.
set "USER_LOG="
set /p USER_LOG="Enter full path to latest.log or press Enter to exit: "

if not defined USER_LOG goto end

rem Remove surrounding quotes if the user dragged and dropped the file
set "USER_LOG=%USER_LOG:"=%"

rem Allow entering the game folder, the logs folder, or the file itself
if exist "%USER_LOG%\logs\latest.log" set "USER_LOG=%USER_LOG%\logs\latest.log"
if exist "%USER_LOG%\latest.log" set "USER_LOG=%USER_LOG%\latest.log"

if not exist "%USER_LOG%" (
    echo Invalid path: "%USER_LOG%"
    goto manual_input
)

set "LOG_FILE=%USER_LOG%"
goto found_log

:found_log
echo.
echo Log file selected:
echo "%LOG_FILE%"

if exist "%OUTPUT_FILE%" del "%OUTPUT_FILE%"

echo Extracting coordinates...

powershell -NoProfile -ExecutionPolicy Bypass -Command "$lines = @(Select-String -LiteralPath $env:LOG_FILE -Pattern '(?i)blocklocator' -Encoding UTF8 | ForEach-Object { $_.Line -replace '(?i)^.*?(blocklocator.*)$', '$1' }); if ($lines.Count -gt 0) { $lines | Set-Content -LiteralPath $env:OUTPUT_FILE -Encoding UTF8; exit 0 } else { exit 1 }"

set "PS_EXIT=%ERRORLEVEL%"
set "FILE_SIZE=0"

if exist "%OUTPUT_FILE%" (
    for %%A in ("%OUTPUT_FILE%") do set "FILE_SIZE=%%~zA"
)

if %PS_EXIT% equ 0 (
    if %FILE_SIZE% gtr 0 (
        echo.
        echo Success! Coordinates have been saved to:
        echo "%OUTPUT_FILE%"
        goto end
    )
)

echo.
echo No lines containing "blocklocator" were found in the log.
if exist "%OUTPUT_FILE%" del "%OUTPUT_FILE%"
goto end

:end
echo.
pause
endlocal
exit /b