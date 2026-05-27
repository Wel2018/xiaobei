# 摄像头实时预览功能 - 快速启动指南

## 前置要求

确保已安装以下依赖：

### 后端
```bash
cd xiaobei-backend
pip install -r requirements.txt
# 或使用 uv
uv sync
```

### 前端
```bash
cd xiaobei-frontend
pnpm install
```

## 启动步骤

### 1. 启动后端服务

```bash
cd xiaobei-backend
python main.py
```

或使用启动脚本：
```bash
# Windows
start.bat

# Linux/Mac
./start.sh
```

后端将在 `http://localhost:8000` 启动

### 2. 启动前端开发服务器

```bash
cd xiaobei-frontend
pnpm dev
```

前端将在 `http://localhost:5173` 启动（或其他端口）

### 3. 访问应用

打开浏览器访问前端地址，导航到监控仪表板页面。

## 使用摄像头功能

### 首次使用

1. **打开相机配置**
   - 在右侧面板找到"预览"区域
   - 点击 ⚙️ 配置按钮

2. **选择相机**
   - 查看可用相机设备列表
   - 每个设备显示：
     - 设备名称
     - 类型（RealSense / USB）
     - 分辨率
     - 帧率

3. **打开相机**
   - 点击设备旁边的"打开"按钮
   - 等待预览画面加载
   - 实时视频开始显示（10fps）

4. **拍照**
   - 点击"拍照"按钮
   - 照片自动下载为 JPG 文件
   - 文件名格式：`capture_时间戳.jpg`

### 切换相机

1. 点击 ⚙️ 配置按钮
2. 在列表中选择其他相机
3. 点击"切换"按钮
4. 系统自动关闭当前相机并打开新相机

### 关闭相机

1. 点击 ⚙️ 配置按钮
2. 找到当前打开的相机（绿色边框标识）
3. 点击"关闭"按钮
4. 预览区域恢复为空状态

## 故障排除

### 问题 1：无法获取设备列表

**症状：** 配置对话框显示"未检测到相机设备"

**解决方案：**
```bash
# 检查后端是否运行
curl http://localhost:8000/health

# 检查相机设备 API
curl http://localhost:8000/api/v1/camera-devices/devices

# 重启后端服务
python main.py
```

### 问题 2：相机无法打开

**症状：** 点击"打开"按钮后提示错误

**可能原因：**
- pyrealsense2 未安装
- 相机被其他程序占用
- USB 连接问题

**解决方案：**
```bash
# 重新安装 pyrealsense2
pip install pyrealsense2

# 检查相机连接
# Windows: 设备管理器
# Linux: lsusb | grep Intel

# 运行测试脚本
cd xiaobei-backend
python test_realsense_d455.py
```

### 问题 3：预览画面不更新

**症状：** 打开相机后预览区域显示"加载中..."但不更新

**解决方案：**
1. 检查浏览器控制台是否有错误
2. 验证网络连接
3. 检查后端日志
4. 尝试刷新页面

### 问题 4：CORS 错误

**症状：** 浏览器控制台显示 CORS 错误

**解决方案：**
后端已配置允许所有来源，如果仍有问题：

```python
# 检查 xiaobei-backend/app/core/config.py
ALLOWED_ORIGINS: List[str] = ["*"]  # 确保是 "*"
```

### 问题 5：拍照失败

**症状：** 点击拍照按钮无反应或提示错误

**解决方案：**
1. 确保相机已打开
2. 检查预览画面是否正常显示
3. 查看浏览器控制台错误信息
4. 验证后端 API 响应

## API 测试

### 使用 curl 测试后端 API

```bash
# 获取设备列表
curl http://localhost:8000/api/v1/camera-devices/devices

# 打开相机（假设设备 ID 为 0）
curl -X POST http://localhost:8000/api/v1/camera-devices/devices/0/open

# 捕获帧
curl http://localhost:8000/api/v1/camera-devices/devices/0/frame?frame_type=color

# 关闭相机
curl -X POST http://localhost:8000/api/v1/camera-devices/devices/0/close
```

### 使用 Python 测试

```python
import requests

# 获取设备列表
response = requests.get('http://localhost:8000/api/v1/camera-devices/devices')
print(response.json())

# 打开相机
response = requests.post('http://localhost:8000/api/v1/camera-devices/devices/0/open')
print(response.json())

# 捕获帧
response = requests.get('http://localhost:8000/api/v1/camera-devices/devices/0/frame?frame_type=color')
frame = response.json()
print(f"Frame size: {len(frame['data'])} bytes")
```

## 性能调优

### 调整刷新率

编辑 `RightPanel.vue`，修改刷新间隔：

```typescript
// 当前：10fps (100ms)
refreshTimer = window.setInterval(..., 100)

// 更高帧率：20fps (50ms)
refreshTimer = window.setInterval(..., 50)

// 更低帧率：5fps (200ms)
refreshTimer = window.setInterval(..., 200)
```

### 优化图像质量

在后端 `camera_manager.py` 中调整 JPEG 质量：

```python
# 当前质量：85
_, buffer = cv2.imencode('.jpg', frame, [cv2.IMWRITE_JPEG_QUALITY, 85])

# 更高质量：95
_, buffer = cv2.imencode('.jpg', frame, [cv2.IMWRITE_JPEG_QUALITY, 95])

# 更低质量（更快）：70
_, buffer = cv2.imencode('.jpg', frame, [cv2.IMWRITE_JPEG_QUALITY, 70])
```

## 开发提示

### 查看实时日志

```bash
# 后端日志
tail -f logs/backend.log

# 前端日志
# 浏览器开发者工具 -> Console
```

### 调试模式

```bash
# 后端启用调试模式
export DEBUG=True
python main.py

# 前端热重载已默认启用
pnpm dev
```

## 相关文件

- 前端组件: `xiaobei-frontend/src/components/monitor/RightPanel.vue`
- 后端 API: `xiaobei-backend/app/api/camera_devices.py`
- 相机管理: `xiaobei-backend/app/services/camera_manager.py`
- 功能文档: `xiaobei-frontend/CAMERA_PREVIEW_FEATURE.md`
- D455 更新: `xiaobei-backend/REALSENSE_D455_UPDATE.md`

## 下一步

- [ ] 实现 WebSocket 实时流（替代轮询）
- [ ] 添加深度图预览
- [ ] 支持多相机同时预览
- [ ] 添加录像功能
- [ ] 优化性能和用户体验

## 支持

如有问题，请查看：
1. 浏览器控制台错误
2. 后端日志输出
3. API 文档: http://localhost:8000/docs

## 更新日期

2026-04-09
