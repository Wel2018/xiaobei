@echo off
echo ========================================
echo 小北机器人完整服务 一键启动脚本
echo weikang 2026-04-22
echo ========================================
echo.

echo [提示] 将启动两个独立的服务：
echo   1. 主服务 (端口 8000) - 底盘、机械臂、地图等
echo   2. 扩展服务 (端口 8001) - 摄像头等
echo   2. 界面服务 (端口 5173) - Vite App 等
echo.
echo [提示] 每个服务将在独立的窗口中运行
echo [提示] 关闭窗口即可停止对应服务
echo.
pause

echo.
echo ========================================
echo 启动主服务 (端口 8000)...
echo ========================================
start "主服务" cmd /k "cd xiaobei-backend && uv run python main.py"
@REM timeout /t 3 /nobreak >nul

echo.
echo ========================================
echo 启动流媒体服务 mediamtx
echo ========================================
start "流媒体服务" cmd /k "cd xiaobei-ext/runtime/mediamtx && mediamtx.exe"

echo.
echo ========================================
echo 启动扩展服务 (端口 8001)...
echo ========================================
start "扩展服务" cmd /k "cd xiaobei-ext && uv run python main.py"


echo.
echo ========================================
echo 启动界面服务 (端口 5173)...
echo ========================================
start "界面服务" cmd /k "cd xiaobei-frontend && pnpm dev"


echo.
echo ========================================
echo 启动 WebApp...
echo ========================================
@REM start "WebApp" cmd /k "cd xiaobei-backend && uv run python webapp.py"


echo.
echo ========================================
echo 服务启动完成！
echo ========================================
echo.
echo 主服务:   http://localhost:8000
echo API 文档: http://localhost:8000/docs
echo.
echo 设备服务: http://localhost:8001
echo API 文档: http://localhost:8001/docs
echo.
echo 前端服务: http://localhost:5173
echo.
pause
