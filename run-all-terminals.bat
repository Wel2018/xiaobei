@echo off
setlocal

set ROOT_DIR=%~dp0

echo.
echo ========================================
echo One-Click Start Xiaobei (2026-06-01)
echo ========================================
echo.

REM Check run scripts
if not exist "xiaobei-backend\run.bat" (
    echo [ERROR] xiaobei-backend\run.bat not found
    pause
    exit /b 1
)
if not exist "xiaobei-frontend\run.bat" (
    echo [ERROR] xiaobei-frontend\run.bat not found
    pause
    exit /b 1
)
if not exist "xiaobei-ext\run.bat" (
    echo [ERROR] xiaobei-ext\run.bat not found
    pause
    exit /b 1
)
if not exist "xiaobei-ext\run_ms.bat" (
    echo [ERROR] xiaobei-ext\run_ms.bat not found
    pause
    exit /b 1
)
if not exist "xiaobei-ext\run_fall_detector.bat" (
    echo [WARNING] xiaobei-ext\run_fall_detector.bat not found (optional)
)
if not exist "xiaobei-arm\1_run_ros.bat" (
    echo [ERROR] xiaobei-arm\1_run_ros.bat not found
    pause
    exit /b 1
)
if not exist "xiaobei-arm\2_run_srv.bat" (
    echo [ERROR] xiaobei-arm\2_run_srv.bat not found
    pause
    exit /b 1
)
if not exist "xiaobei-arm\3_run_fastapi.bat" (
    echo [ERROR] xiaobei-arm\3_run_fastapi.bat not found
    pause
    exit /b 1
)
if not exist "xiaobei-face\run.bat" (
    echo [ERROR] xiaobei-face\run.bat not found
    pause
    exit /b 1
)

REM Start services
echo Starting xiaobei-backend
start "xiaobei-backend" cmd /k "cd /d %ROOT_DIR%xiaobei-backend && call run.bat"
timeout /t 1 /nobreak

echo Starting xiaobei-frontend
start "xiaobei-frontend" cmd /k "cd /d %ROOT_DIR%xiaobei-frontend && call run.bat"
timeout /t 1 /nobreak

echo Starting xiaobei-ext - run_ms
start "xiaobei-ext - run_ms" cmd /k "cd /d %ROOT_DIR%xiaobei-ext && call run_ms.bat"
timeout /t 3 /nobreak

echo Starting xiaobei-ext - run
start "xiaobei-ext - run" cmd /k "cd /d %ROOT_DIR%xiaobei-ext && call run.bat"
timeout /t 3 /nobreak

REM echo Starting xiaobei-ext - run_fall_detector
REM start "xiaobei-ext - run_fall_detector" cmd /k "cd /d %ROOT_DIR%xiaobei-ext && call run_fall_detector.bat"
timeout /t 1 /nobreak

echo Starting xiaobei-arm - 1_run_ros
start "xiaobei-arm - 1_run_ros" cmd /k "cd /d %ROOT_DIR%xiaobei-arm && call 1_run_ros.bat"
timeout /t 15 /nobreak

echo Starting xiaobei-arm - 2_run_srv
start "xiaobei-arm - 2_run_srv" cmd /k "cd /d %ROOT_DIR%xiaobei-arm && call 2_run_srv.bat"
timeout /t 3 /nobreak

echo Starting xiaobei-arm - 3_run_fastapi
start "xiaobei-arm - 3_run_fastapi" cmd /k "cd /d %ROOT_DIR%xiaobei-arm && call 3_run_fastapi.bat"
timeout /t 3 /nobreak

echo Starting xiaobei-face
start "xiaobei-face" cmd /k "cd /d %ROOT_DIR%xiaobei-face && call run.bat"

echo.
echo All services started. Check new terminal windows.
echo.

endlocal
