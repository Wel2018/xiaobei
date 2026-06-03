#############################
# 发布项目
#############################

#!/bin/bash

# 设置时间戳
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
DIST_DIR="dist"

# 创建 dist 目录
mkdir -p "$DIST_DIR"

echo "开始打包项目..."
echo "时间戳: $TIMESTAMP"
echo "输出目录: $DIST_DIR"

# 直接打包三个项目到一个压缩包
echo "打包所有项目到 xiaobei_${TIMESTAMP}.tar.gz..."
tar -czf "$DIST_DIR/xiaobei_${TIMESTAMP}.tar.gz" \
    --exclude='.venv' \
    --exclude='node_modules' \
    xiaobei-backend/ \
    xiaobei-ext/ \
    xiaobei-frontend/

if [ $? -eq 0 ]; then
    echo "✓ 打包成功"
else
    echo "✗ 打包失败"
    exit 1
fi

echo ""
echo "最终生成的文件："
ls -lh "$DIST_DIR"/xiaobei_${TIMESTAMP}.tar.gz
echo ""
echo "发布完成！"
