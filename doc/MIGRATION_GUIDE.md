# 摄像头服务迁移指南

## 概述

摄像头相关模块已从 `xiaobei-backend` 迁移到独立的 `xiaobei-devices` 项目，作为单独的 FastAPI 进程运行。

## 📦 项目结构变化

### 之前（单体架构）
```
xiaobei-backend/
├── app/
│   ├── api/
│   │   ├── camera.py              # 摄像头 API
│   │   ├── camera_devices.py      # 设备管理 API
│   │   ├── chassis.py
│   │   └── ...
│   ├── models/
│   │   ├── camera.py
│   │   └── ...
│   └── services/
│       ├── camera_manager.py
│       ├── camera_service.py
│       └── ...
└── main.py                        # 单一入口
```

### 现在（微服务架构）
```
xiaobei-backend/                   # 主服务（不含摄像头）
├── app/
│   ├── api/
│   │   ├── chassis.py
│   │   ├── robotic_arm.py
│   │   └── ...
│   └── ...
└── main.py                        # 端口: 8000

xiaobei-devices/                   # 设备服务（独立）
├── app/
│   ├── api/
│   │   ├── camera.py              # 摄像头 API
│   │   └── camera_devices.py      # 设备管理 API
│   ├── models/
│   │   └── camera.py
│   └── services/
│       ├── camera_manager.py
│       └── camera_service.py
└── main.py                        # 端口: 8001
```

## 🔌 端口分配

| 服务 | 端口 | 说明 |
|------|------|------|
| xiaobei-backend | 8000 | 主服务（底盘、机械臂、地图等） |
| xiaobei-devices | 8001 | 设备服务（摄像头） |

## 🔄 API 路径变化

### 摄像头 API

**之前：**
```
http://localhost:8000/api/v1/camera/*
http://localhost:8000/api/v1/camera-devices/*
```

**现在：**
```
http://localhost:8001/api/v1/camera/*
http://localhost:8001/api/v1/camera-devices/*
```

### WebSocket

**之前：**
```
ws://localhost:8000/ws/camera
```

**现在：**
```
ws://localhost:8001/ws/camera
```

## 🛠️ 前端更新

### RightPanel.vue

已自动更新 API 基础 URL：

```typescript
// 之前
const API_BASE_URL = 'http://127.0.0.1:8000/api/v1/camera-devices'

// 现在
const API_BASE_URL = 'http://127.0.0.1:8001/api/v1/camera-devices'
```

如果还有其他组件使用摄像头 API，请相应更新。

## 🚀 启动方式

### 之前（单一服务）
```bash
cd xiaobei-backend
python main.py
# 所有功能在 8000 端口
```

### 现在（两个独立服务）

**终端 1 - 主服务：**
```bash
cd xiaobei-backend
python main.py
# 运行在 8000 端口
```

**终端 2 - 设备服务：**
```bash
cd xiaobei-devices
python main.py
# 运行在 8001 端口
```

或使用启动脚本：
```bash
# Windows
start.bat

# Linux/Mac
./start.sh
```

## ✅ 迁移检查清单

- [x] 创建 xiaobei-devices 项目结构
- [x] 复制摄像头相关文件
- [x] 配置独立端口（8001）
- [x] 创建启动脚本
- [x] 更新前端 API URL
- [x] 编写 README 文档
- [ ] 测试两个服务独立运行
- [ ] 验证前端功能正常
- [ ] 更新部署文档

## 🧪 测试步骤

### 1. 启动主服务
```bash
cd xiaobei-backend
python main.py
```

访问 http://localhost:8000/docs 确认服务正常

### 2. 启动设备服务
```bash
cd xiaobei-devices
python main.py
```

访问 http://localhost:8001/docs 确认服务正常

### 3. 测试摄像头 API
```bash
# 获取设备列表
curl http://localhost:8001/api/v1/camera-devices/devices

# 健康检查
curl http://localhost:8001/health
```

### 4. 测试前端
```bash
cd xiaobei-frontend
pnpm dev
```

打开浏览器，测试摄像头预览功能

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

### 2. pyrealsense2

确保在 `xiaobei-devices` 环境中安装了 pyrealsense2：

```bash
pip install pyrealsense2
```

### 3. 端口冲突

如果 8001 端口被占用，修改 `xiaobei-devices/main.py`：

```python
uvicorn.run(
    "main:app",
    host="0.0.0.0",
    port=8002,  # 改为其他端口
    reload=True
)
```

同时更新前端的 API_BASE_URL。

### 4. CORS 配置

两个服务都已配置允许所有来源（`allow_origins=["*"]`），生产环境建议限制为具体域名。

## 🔙 回滚方案

如需回滚到单体架构：

1. 停止 xiaobei-devices 服务
2. 将摄像头文件复制回 xiaobei-backend
3. 恢复前端 API URL 为 8000 端口
4. 重启 xiaobei-backend

## 📊 优势

### 微服务架构的优势

1. **独立部署**: 可以单独更新摄像头服务
2. **故障隔离**: 摄像头服务崩溃不影响主服务
3. **资源隔离**: 可以为摄像头服务分配独立资源
4. **技术栈灵活**: 可以为不同服务选择最合适的技术
5. **团队协作**: 不同团队可以并行开发

### 性能优势

- 摄像头处理不阻塞主服务
- 可以独立扩展摄像头服务
- 更好的资源利用率

## 📝 后续优化建议

1. **服务发现**: 使用 Consul 或 etcd 管理服务地址
2. **API 网关**: 统一入口，简化前端调用
3. **负载均衡**: 多个摄像头实例负载均衡
4. **监控告警**: 集成 Prometheus + Grafana
5. **日志聚合**: 使用 ELK 或 Loki
6. **容器化**: Docker 部署，简化管理

## 🆘 常见问题

### Q: 为什么要分离摄像头服务？

A: 
- 摄像头处理消耗较多 CPU/GPU 资源
- 独立服务便于维护和升级
- 故障隔离，提高系统稳定性
- 为未来支持更多设备类型做准备

### Q: 两个服务如何通信？

A: 
目前通过 HTTP/WebSocket 直接通信。未来可以考虑：
- REST API
- gRPC
- 消息队列（RabbitMQ, Kafka）

### Q: 前端需要修改多少代码？

A: 
只需修改 API 基础 URL，其他代码无需改动。

### Q: 可以在同一台机器上运行吗？

A: 
可以，两个服务使用不同端口，互不干扰。

## 📞 技术支持

如有问题，请查看：
- xiaobei-devices/README.md
- API 文档: http://localhost:8001/docs
- 日志输出: 控制台实时显示

## 📅 更新日期

2026-04-09
