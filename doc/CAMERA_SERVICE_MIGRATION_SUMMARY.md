# 摄像头服务独立化 - 完成总结

## ✅ 已完成的工作

### 1. 项目结构创建

创建了独立的 `xiaobei-devices` 项目，包含完整的目录结构：

```
xiaobei-devices/
├── app/
│   ├── api/
│   │   ├── __init__.py
│   │   ├── camera.py              # 摄像头 API 路由
│   │   └── camera_devices.py      # 设备管理 API 路由
│   ├── models/
│   │   ├── __init__.py
│   │   └── camera.py              # 数据模型
│   └── services/
│       ├── __init__.py
│       ├── camera_manager.py      # 相机管理器
│       └── camera_service.py      # WebSocket 服务
├── main.py                        # 应用入口（端口 8001）
├── requirements.txt               # Python 依赖
├── pyproject.toml                 # 项目配置
├── .gitignore                     # Git 忽略文件
├── start.bat                      # Windows 启动脚本
├── start.sh                       # Linux/Mac 启动脚本
└── README.md                      # 项目文档
```

### 2. 核心功能迁移

从 `xiaobei-backend` 迁移了以下模块：

- ✅ `app/api/camera.py` - 摄像头 API
- ✅ `app/api/camera_devices.py` - 设备管理 API
- ✅ `app/models/camera.py` - 数据模型
- ✅ `app/services/camera_manager.py` - 相机管理器
- ✅ `app/services/camera_service.py` - WebSocket 服务

### 3. 独立配置

- ✅ 独立端口：**8001**（主服务使用 8000）
- ✅ 独立依赖管理
- ✅ 独立 CORS 配置
- ✅ 独立生命周期管理

### 4. 前端更新

- ✅ 更新 `RightPanel.vue` 中的 API 基础 URL
  - 从 `http://127.0.0.1:8000/api/v1/camera-devices`
  - 改为 `http://127.0.0.1:8001/api/v1/camera-devices`

### 5. 文档创建

- ✅ `xiaobei-devices/README.md` - 设备服务完整文档
- ✅ `MIGRATION_GUIDE.md` - 迁移指南
- ✅ `start-all.bat/sh` - 一键启动所有服务

## 🎯 架构变化

### 之前：单体架构

```
┌─────────────────────────────────┐
│     xiaobei-backend (8000)      │
│  ┌──────────┬────────────────┐  │
│  │ 业务逻辑  │   摄像头模块    │  │
│  └──────────┴────────────────┘  │
└─────────────────────────────────┘
         ↓
    前端应用
```

**问题：**
- 摄像头处理阻塞主服务
- 资源竞争
- 故障影响范围大
- 难以独立扩展

### 现在：微服务架构

```
┌──────────────────────┐    ┌──────────────────────┐
│ xiaobei-backend      │    │ xiaobei-devices      │
│ (端口 8000)          │    │ (端口 8001)          │
│                      │    │                      │
│ • 底盘控制           │    │ • RealSense D455     │
│ • 机械臂控制         │    │ • USB 相机           │
│ • 地图信息           │    │ • 设备管理           │
│ • 头部舵机           │    │ • 视频流             │
└──────────────────────┘    └──────────────────────┘
         ↓                            ↓
         └────────┬──────────────────┘
                  ↓
            前端应用
```

**优势：**
- ✅ 服务隔离，互不影响
- ✅ 独立部署和扩展
- ✅ 故障隔离
- ✅ 资源优化
- ✅ 便于维护

## 📊 服务对比

| 特性 | xiaobei-backend | xiaobei-devices |
|------|----------------|-----------------|
| 端口 | 8000 | 8001 |
| 功能 | 底盘、机械臂、地图、舵机 | 摄像头设备管理 |
| 依赖 | FastAPI, Zenoh | FastAPI, OpenCV, pyrealsense2 |
| 资源消耗 | 低 | 中高（图像处理） |
| 启动时间 | 快 | 中等（相机初始化） |

## 🔌 API 端点

### 主服务 (8000)

- `/api/v1/chassis/*` - 底盘控制
- `/api/v1/robotic-arm/*` - 机械臂控制
- `/api/v1/map/*` - 地图信息
- `/api/v1/head-servo/*` - 头部舵机

### 设备服务 (8001)

- `/api/v1/camera/*` - 摄像头流
  - `GET /status` - 获取状态
  - `GET /color/frame` - 彩色帧
  - `GET /depth/frame` - 深度帧
  - `GET /config` - 配置信息
  - `WS /ws/camera` - WebSocket 实时流

- `/api/v1/camera-devices/*` - 设备管理
  - `GET /devices` - 设备列表
  - `POST /devices/{id}/open` - 打开相机
  - `POST /devices/{id}/close` - 关闭相机
  - `GET /devices/{id}/frame` - 捕获帧

## 🚀 启动方式

### 方式一：分别启动

**终端 1 - 主服务：**
```bash
cd xiaobei-backend
python main.py
```

**终端 2 - 设备服务：**
```bash
cd xiaobei-devices
python main.py
```

**终端 3 - 前端：**
```bash
cd xiaobei-frontend
pnpm dev
```

### 方式二：一键启动（推荐）

**Windows：**
```bash
start-all.bat
```

**Linux/Mac：**
```bash
chmod +x start-all.sh
./start-all.sh
```

这将在独立窗口中启动两个后端服务。

## 📝 配置文件说明

### main.py (设备服务)

```python
app = FastAPI(
    title="小北机器人 - 设备服务",
    description="提供 RealSense 和 USB 相机设备管理、视频流服务",
    version="1.0.0",
    lifespan=lifespan
)

# 运行配置
uvicorn.run(
    "main:app",
    host="0.0.0.0",
    port=8001,  # 独立端口
    reload=True
)
```

### requirements.txt

```txt
fastapi==0.109.0
uvicorn[standard]==0.27.0
opencv-python==4.9.0.80
numpy==1.26.3
pyrealsense2==2.54.2.5684
...
```

## 🧪 测试验证

### 1. 健康检查

```bash
# 主服务
curl http://localhost:8000/health

# 设备服务
curl http://localhost:8001/health
```

### 2. API 文档

- 主服务: http://localhost:8000/docs
- 设备服务: http://localhost:8001/docs

### 3. 设备列表

```bash
curl http://localhost:8001/api/v1/camera-devices/devices
```

### 4. 前端功能

打开浏览器访问前端，测试：
- 摄像头预览
- 设备选择
- 拍照功能
- 实时视频流

## ⚠️ 注意事项

### 1. 依赖安装

两个项目需要分别安装依赖：

```bash
# 主服务
cd xiaobei-backend
pip install -r requirements.txt

# 设备服务
cd xiaobei-devices
pip install -r requirements.txt
```

### 2. 端口占用

确保 8000 和 8001 端口未被占用：

```bash
# Windows
netstat -ano | findstr :8000
netstat -ano | findstr :8001

# Linux/Mac
lsof -i :8000
lsof -i :8001
```

### 3. 相机驱动

确保已安装 RealSense 驱动和 SDK：

```bash
# 检查相机连接
# Windows: 设备管理器
# Linux: lsusb | grep Intel
```

### 4. 前端配置

如果还有其他组件使用摄像头 API，需要相应更新 URL。

## 🔄 后续优化建议

### 短期优化

1. **错误处理增强**
   - 添加重试机制
   - 完善错误日志

2. **性能监控**
   - 添加请求耗时统计
   - 监控内存使用

3. **文档完善**
   - 添加 API 示例
   - 编写开发指南

### 中期优化

1. **服务发现**
   - 集成 Consul 或 etcd
   - 动态服务注册

2. **API 网关**
   - 统一入口
   - 负载均衡
   - 认证授权

3. **容器化**
   - Docker 镜像
   - Docker Compose 编排

### 长期优化

1. **消息队列**
   - 异步通信
   - 解耦服务

2. **监控系统**
   - Prometheus + Grafana
   - 告警通知

3. **日志聚合**
   - ELK Stack
   - 分布式追踪

## 📞 支持

如有问题，请查看：

1. **项目文档**
   - `xiaobei-devices/README.md`
   - `MIGRATION_GUIDE.md`

2. **API 文档**
   - http://localhost:8000/docs
   - http://localhost:8001/docs

3. **日志输出**
   - 控制台实时显示

## ✨ 总结

成功将摄像头模块从单体架构迁移到微服务架构：

- ✅ 独立的项目结构
- ✅ 独立的端口和服务
- ✅ 完整的功能迁移
- ✅ 前端适配完成
- ✅ 详细的文档支持
- ✅ 便捷的启动脚本

现在可以享受微服务带来的好处：
- 🚀 更好的性能
- 🔒 更高的稳定性
- 🛠️ 更易的维护
- 📈 更强的扩展性

---

**迁移完成日期**: 2026-04-09  
**版本**: v1.0.0
