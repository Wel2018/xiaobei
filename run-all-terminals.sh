#!/bin/bash
source ~/.bashrc

waiting....
sleep 10
starting...

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TERMINAL_CMD=""
TERMINAL_TYPE=""

function try_launch() {
    local title="$1"
    local workdir="$2"
    local script="$3"
    local cmd="cd \"$workdir\" && bash \"$script\"; exec bash"
    echo "启动 $1, $2, $3"

    case "$TERMINAL_TYPE" in
        gnome-terminal)
            gnome-terminal --title="$title" -- bash -lc "$cmd"
            ;;
        xfce4-terminal)
            xfce4-terminal --title="$title" --hold --command="bash -lc '$cmd'"
            ;;
        konsole)
            konsole --hold -p tabtitle="$title" -e bash -lc "$cmd"
            ;;
        xterm)
            xterm -T "$title" -hold -e bash -lc "$cmd"
            ;;
        *)
            echo "[WARN] 未检测到图形终端，改为在后台运行: $title"
            (cd "$workdir" && bash "$script") &
            ;;
    esac
}

function detect_terminal() {
    if command -v gnome-terminal &> /dev/null; then
        TERMINAL_TYPE="gnome-terminal"
        return
    fi
    if command -v xfce4-terminal &> /dev/null; then
        TERMINAL_TYPE="xfce4-terminal"
        return
    fi
    if command -v konsole &> /dev/null; then
        TERMINAL_TYPE="konsole"
        return
    fi
    if command -v xterm &> /dev/null; then
        TERMINAL_TYPE="xterm"
        return
    fi
    TERMINAL_TYPE="none"
}

function check_run_script() {
    local path="$1"
    if [ ! -x "$path" ]; then
        if [ -f "$path" ]; then
            chmod +x "$path"
        else
            echo "[ERROR] 找不到 $path"
            exit 1
        fi
    fi
}

cd "$ROOT_DIR"

# 启动前后端
check_run_script "xiaobei-backend/run.sh"
check_run_script "xiaobei-frontend/run.sh"

# 启动扩展服务：流媒体、跌倒检测
check_run_script "xiaobei-ext/run.sh"
check_run_script "xiaobei-ext/run_ms.sh"
check_run_script "xiaobei-ext/run_fall_detector.sh"

# 启动睿感机械臂服务
check_run_script "xiaobei-arm/1_run_ros.sh"
check_run_script "xiaobei-arm/2_run_srv.sh"
check_run_script "xiaobei-arm/3_run_fastapi.sh"

# 启动面部动画
check_run_script "xiaobei-face/run.sh"

detect_terminal

printf "========================================\n"
printf "一键启动 xiaobei (2026-05-28) \n"
printf "========================================\n"
printf "使用终端：%s\n" "$TERMINAL_TYPE"
#printf "按回车继续..."
#read -r

#######################################################################
# 启动前后端
try_launch "xiaobei-backend" "$ROOT_DIR/xiaobei-backend" "run.sh"
sleep 1
try_launch "xiaobei-frontend" "$ROOT_DIR/xiaobei-frontend" "run.sh"
sleep 1

#######################################################################
# 启动扩展服务：流媒体、跌倒检测
try_launch "xiaobei-ext - run_ms" "$ROOT_DIR/xiaobei-ext" "run_ms.sh"  # mediamtx
sleep 3
try_launch "xiaobei-ext - run" "$ROOT_DIR/xiaobei-ext" "run.sh"
sleep 3
# try_launch "xiaobei-ext - run_fall_detector" "$ROOT_DIR/xiaobei-ext" "run_fall_detector.sh"
sleep 1

#######################################################################
# 启动睿感机械臂服务
try_launch "xiaobei-arm - 1_run_ros" "$ROOT_DIR/xiaobei-arm" "1_run_ros.sh"
sleep 15
try_launch "xiaobei-arm - 2_run_srv" "$ROOT_DIR/xiaobei-arm" "2_run_srv.sh"
sleep 3
try_launch "xiaobei-arm - 3_run_fastapi" "$ROOT_DIR/xiaobei-arm" "3_run_fastapi.sh"
sleep 3

#######################################################################
# 启动面部动画
try_launch "xiaobei-face" "$ROOT_DIR/xiaobei-face" "run.sh"

#######################################################################
printf "\n启动完成。\n"
if [ "$TERMINAL_TYPE" = "none" ]; then
    printf "当前系统未检测到可用图形终端，脚本已在后台启动。\n"
else
    printf "请查看新打开的终端窗口。\n"
fi
