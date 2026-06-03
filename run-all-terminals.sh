#!/bin/bash
source ~/.bashrc

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$ROOT_DIR/boot_items.yaml"
TERMINAL_TYPE=""
PARSE_SCRIPT="$ROOT_DIR/parse_config.py"
TEMP_FILE="/tmp/xiaobei_launch_list.txt"

# 检查 Python 是否可用
if ! command -v python3 &> /dev/null; then
    echo "[ERROR] 需要 python3 来解析 YAML 配置"
    exit 1
fi

# 检查配置文件是否存在
if [ ! -f "$CONFIG_FILE" ]; then
    echo "[ERROR] 配置文件不存在: $CONFIG_FILE"
    exit 1
fi

# 检查解析脚本是否存在
if [ ! -f "$PARSE_SCRIPT" ]; then
    echo "[ERROR] 解析脚本不存在: $PARSE_SCRIPT"
    exit 1
fi

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

function try_launch() {
    local title="$1"
    local workdir="$2"
    local script="$3"
    local wait_time="${4:-1}"
    local cmd="cd \"$workdir\" && bash \"$script\"; exec bash"
    
    echo "启动: $title (等待 ${wait_time}s)"

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
    
    sleep "$wait_time"
}

function check_run_script() {
    local path="$1"
    if [ ! -f "$path" ]; then
        echo "[ERROR] 找不到 $path"
        return 1
    fi
    if [ ! -x "$path" ]; then
        chmod +x "$path"
    fi
    return 0
}

# 主流程
cd "$ROOT_DIR"
detect_terminal

printf "========================================\n"
printf "一键启动 xiaobei (2026-06-03) \n"
printf "========================================\n"
printf "使用终端：%s\n" "$TERMINAL_TYPE"
printf "配置文件：%s\n" "$CONFIG_FILE"
printf "========================================\n\n"

# 使用 Python 解析配置并生成启动列表
python3 "$PARSE_SCRIPT" "$CONFIG_FILE" "$TEMP_FILE"
if [ $? -ne 0 ]; then
    echo "[ERROR] 解析配置文件失败"
    exit 1
fi

# 检查临时文件是否存在
if [ ! -f "$TEMP_FILE" ]; then
    echo "[ERROR] 未能生成启动列表"
    exit 1
fi

# 逐行处理启动项
while IFS='|' read -r module script wait_time status; do
    # 跳过空行
    [ -z "$module" ] && continue
    
    # 处理 skip
    if [ "$status" = "skip" ]; then
        echo "[INFO] 跳过: $module"
        continue
    fi
    
    if [ "$script" = "__skip__" ]; then
        continue
    fi
    
    # 根据平台确定脚本扩展名
    script_ext=".sh"
    script_path="$ROOT_DIR/$module/$script$script_ext"
    
    # 检查脚本是否存在
    if ! check_run_script "$script_path"; then
        echo "[WARNING] 脚本不存在，跳过: $script_path"
        continue
    fi
    
    # 启动服务
    try_launch "$module - $script" "$ROOT_DIR/$module" "$script$script_ext" "$wait_time"
    
done < "$TEMP_FILE"

# 清理临时文件
rm -f "$TEMP_FILE"

printf "\n========================================\n"
printf "启动完成。\n"
if [ "$TERMINAL_TYPE" = "none" ]; then
    printf "当前系统未检测到可用图形终端，脚本已在后台启动。\n"
else
    printf "请查看新打开的终端窗口。\n"
fi
printf "========================================\n"
