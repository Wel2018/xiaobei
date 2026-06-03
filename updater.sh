#!/bin/bash

#############################
# 更新项目
#############################

DIST_DIR="dist"
OLD_DIR="old"
PROJECTS=("xiaobei-backend" "xiaobei-ext" "xiaobei-frontend")

echo "=========================================="
echo "开始更新项目..."
echo "=========================================="

# 检查 dist 目录是否存在
if [ ! -d "$DIST_DIR" ]; then
    echo "✗ 错误: dist 目录不存在"
    exit 1
fi

# 查找最新的 xiaobei_*.tar.gz 文件
LATEST_PACKAGE=$(ls -t "$DIST_DIR"/xiaobei_*.tar.gz 2>/dev/null | head -n 1)

if [ -z "$LATEST_PACKAGE" ]; then
    echo "✗ 错误: 在 dist 目录下未找到 xiaobei_*.tar.gz 文件"
    exit 1
fi

echo "✓ 找到最新安装包: $(basename "$LATEST_PACKAGE")"

# 解压到临时目录
TEMP_DIR="temp_update_$$"
echo ""
echo "正在解压..."
mkdir -p "$TEMP_DIR"
tar -xzf "$LATEST_PACKAGE" -C "$TEMP_DIR"

if [ $? -ne 0 ]; then
    echo "✗ 解压失败"
    rm -rf "$TEMP_DIR"
    exit 1
fi

echo "✓ 解压成功"

# 创建 old 目录用于备份
mkdir -p "$OLD_DIR"

# 获取解压后的文件夹名称（应该是 xiaobei_时间戳）
XIAOBEI_DIR=$(ls "$TEMP_DIR" | head -n 1)
XIAOBEI_PATH="$TEMP_DIR/$XIAOBEI_DIR"

if [ ! -d "$XIAOBEI_PATH" ]; then
    echo "✗ 错误: 解压后的目录结构不正确"
    rm -rf "$TEMP_DIR"
    exit 1
fi

echo "✓ 解压成功，包含以下文件夹："
ls -lh "$XIAOBEI_PATH/"

echo ""
echo "开始更新各个项目..."

# 遍历每个项目
for PROJECT in "${PROJECTS[@]}"; do
    echo ""
    echo "处理 $PROJECT..."
    
    # 检查当前目录是否存在该项目
    if [ -d "$PROJECT" ]; then
        # 移动到 old 目录，添加时间戳避免冲突
        BACKUP_NAME="${PROJECT}_$(date +%Y%m%d_%H%M%S)"
        echo "  备份现有版本到 $OLD_DIR/$BACKUP_NAME"
        mv "$PROJECT" "$OLD_DIR/$BACKUP_NAME"
        
        if [ $? -ne 0 ]; then
            echo "  ✗ 备份失败，跳过此项目"
            continue
        fi
        echo "  ✓ 备份成功"
    else
        echo "  ℹ 当前目录不存在 $PROJECT，无需备份"
    fi
    
    # 从解压的目录中移动新版本文件夹
    SOURCE_PATH="$XIAOBEI_PATH/$PROJECT"
    
    if [ -d "$SOURCE_PATH" ]; then
        echo "  移动新版本..."
        mv "$SOURCE_PATH" .
        
        if [ $? -eq 0 ]; then
            echo "  ✓ $PROJECT 更新成功"
        else
            echo "  ✗ $PROJECT 移动失败"
            # 如果移动失败，尝试恢复备份
            if [ -d "$OLD_DIR/$BACKUP_NAME" ]; then
                echo "  尝试恢复备份..."
                mv "$OLD_DIR/$BACKUP_NAME" "$PROJECT"
            fi
        fi
    else
        echo "  ✗ 错误: 找不到 $SOURCE_PATH"
        # 如果移动失败，尝试恢复备份
        if [ -d "$OLD_DIR/$BACKUP_NAME" ]; then
            echo "  尝试恢复备份..."
            mv "$OLD_DIR/$BACKUP_NAME" "$PROJECT"
        fi
    fi
done

# 清理临时目录
echo ""
echo "清理临时文件..."
rm -rf "$TEMP_DIR"

echo ""
echo "=========================================="
echo "更新完成！"
echo "=========================================="
echo ""
echo "旧版本已备份到: $OLD_DIR/"
ls -lh "$OLD_DIR/" 2>/dev/null
echo ""
echo "当前项目目录："
for PROJECT in "${PROJECTS[@]}"; do
    if [ -d "$PROJECT" ]; then
        echo "  ✓ $PROJECT"
    else
        echo "  ✗ $PROJECT (缺失)"
    fi
done
