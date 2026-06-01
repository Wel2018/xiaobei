#!/bin/bash

set -euo pipefail

echo "正在关闭所有 gnome-terminal 进程..."

pids=$(ps -eo pid=,comm= | awk '$2 ~ /^gnome-terminal/ {print $1}')

if [ -n "$pids" ]; then
    echo "$pids" | xargs -r kill -9
    echo "已关闭所有 gnome-terminal 进程。"
else
    echo "当前没有发现 gnome-terminal 进程。"
fi
