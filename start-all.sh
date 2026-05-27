#!/bin/bash

echo "========================================"
echo "启动小北机器人 - 完整服务"
echo "========================================"
echo ""

# 检查 Python 是否安装
if ! command -v python3 &> /dev/null; then
    echo "[错误] 未找到 Python3，请先安装 Python 3.10+"
    exit 1
fi

echo "[提示] 将启动两个独立的服务："
echo "  1. 主服务 (端口 8000) - 底盘、机械臂、地图等"
echo "  2. 设备服务 (端口 8001) - 摄像头"
echo ""
echo "[提示] 每个服务将在独立的终端中运行"
echo "[提示] 按 Ctrl+C 可停止服务"
echo ""
read -p "按回车键继续..."

echo ""
echo "========================================"
echo "启动主服务 (端口 8000)..."
echo "========================================"
gnome-terminal --title="小北机器人 - 主服务" -- bash -c "cd xiaobei-backend && python3 main.py; exec bash" 2>/dev/null || \
xterm -title "小北机器人 - 主服务" -e "cd xiaobei-backend && python3 main.py; exec bash" 2>/dev/null || \
osascript -e 'tell app "Terminal" to do script "cd xiaobei-backend && python3 main.py"' 2>/dev/null || \
(cd xiaobei-backend && python3 main.py &)

sleep 3

echo ""
echo "========================================"
echo "启动设备服务 (端口 8001)..."
echo "========================================"
gnome-terminal --title="小北机器人 - 设备服务" -- bash -c "cd xiaobei-devices && python3 main.py; exec bash" 2>/dev/null || \
xterm -title "小北机器人 - 设备服务" -e "cd xiaobei-devices && python3 main.py; exec bash" 2>/dev/null || \
osascript -e 'tell app "Terminal" to do script "cd xiaobei-devices && python3 main.py"' 2>/dev/null || \
(cd xiaobei-devices && python3 main.py &)

echo ""
echo "========================================"
echo "服务启动完成！"
echo "========================================"
echo ""
echo "主服务:   http://localhost:8000"
echo "API 文档: http://localhost:8000/docs"
echo ""
echo "设备服务: http://localhost:8001"
echo "API 文档: http://localhost:8001/docs"
echo ""
echo "前端应用: 请手动启动 xiaobei-frontend"
echo ""
