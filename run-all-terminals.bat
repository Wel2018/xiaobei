@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul

set ROOT_DIR=%~dp0
set CONFIG_FILE=%ROOT_DIR%boot_items.yaml

echo.
echo ========================================
echo One-Click Start Xiaobei (2026-06-03)
echo ========================================
echo Config: %CONFIG_FILE%
echo ========================================
echo.

REM Check Python availability
where python >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Python is required to parse YAML config
    pause
    exit /b 1
)

REM Check config file exists
if not exist "%CONFIG_FILE%" (
    echo [ERROR] Config file not found: %CONFIG_FILE%
    pause
    exit /b 1
)

REM Parse YAML config and generate launch list
set "temp_file=%TEMP%\xiaobei_launch_list.txt"

python "%ROOT_DIR%parse_config.py" "%CONFIG_FILE%" "%temp_file%"
if errorlevel 1 (
    echo [ERROR] Failed to parse config file
    pause
    exit /b 1
)

REM Process each line from the launch list
for /f "usebackq delims=" %%i in ("%temp_file%") do (
    call :process_line "%%i"
)

REM Clean up temp file
if exist "%temp_file%" del "%temp_file%"

echo.
echo All services started. Check new terminal windows.
echo.

endlocal
exit /b 0

:process_line
setlocal
set "input=%~1"

REM Skip empty lines
if "%input%"=="" (
    endlocal
    exit /b 0
)

REM Parse line data: module|script|wait_time|status
for /f "tokens=1,2,3,4 delims=|" %%a in ("%input%") do (
    set "module=%%a"
    set "script=%%b"
    set "wait_time=%%c"
    set "status=%%d"
)

REM Handle skip
if "%status%"=="skip" (
    echo [INFO] Skipped: %module%
    endlocal
    exit /b 0
)

if "%script%"=="__skip__" (
    endlocal
    exit /b 0
)

REM Determine script path
set "script_path=%ROOT_DIR%%module%\%script%.bat"

REM Check if script exists
if not exist "%script_path%" (
    echo [WARNING] Script not found, skipped: %script_path%
    endlocal
    exit /b 0
)

REM Default wait time
if "%wait_time%"=="" set "wait_time=1"

REM Launch service
echo Starting %module% - %script% (wait %wait_time%s)
start "%module% - %script%" cmd /k "cd /d %ROOT_DIR%%module% && call %script%.bat"

REM Wait using ping method (more reliable than timeout in some contexts)
ping 127.0.0.1 -n %wait_time% -w 1000 >nul 2>&1

endlocal
exit /b 0
