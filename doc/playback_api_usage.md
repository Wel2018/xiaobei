# 视频播放 FastAPI 接口使用说明

## 1. 功能说明

本接口用于护士站向当前应用发送视频播放请求。

FastAPI 服务随当前应用一起启动，在后台线程中监听请求。护士站提交播放请求后，服务端将请求加入队列；当前应用定时领取队首任务，并复用已有媒体播放组件播放 `res/video` 目录下的视频。播放开始、完成或失败后，当前应用更新任务状态，护士站可通过接口查询。

旧的 `MediaTriggerService` 点位轮询、点位映射和状态回写逻辑不再用于本功能。

## 2. 服务配置

建议在项目根目录 `config.xml` 中增加以下配置：

```xml
<playback_api>
    <enabled>true</enabled>
    <host>0.0.0.0</host>
    <port>29007</port>
    <poll_interval>500</poll_interval>
</playback_api>
```

字段说明：

| 字段 | 说明 |
| --- | --- |
| `enabled` | 是否启用视频播放 API |
| `host` | FastAPI 监听地址，使用 `0.0.0.0` 允许局域网设备访问 |
| `port` | FastAPI 监听端口，示例为 `29007` |
| `poll_interval` | 当前应用领取播放任务的间隔，单位为毫秒 |

`0.0.0.0` 仅用于服务端监听。护士站调用时必须使用当前设备的实际局域网 IP，例如：

```text
http://192.168.1.20:29007
```

## 3. 总体流程

```text
当前应用启动
    -> 启动 FastAPI 服务
    -> 扫描 res/video
    -> 更新 FastAPI 中的视频列表

护士站
    -> 查询视频列表
    -> 提交播放请求

FastAPI
    -> 将请求加入播放队列

当前应用
    -> 定时领取队首任务
    -> 使用已有播放组件开始播放
    -> 更新状态为 playing
    -> 播放结束后更新为 completed
    -> 播放异常时更新为 failed

护士站
    -> 查询播放状态
```

## 4. 接口列表

| 方法 | 路径 | 调用方 | 说明 |
| --- | --- | --- | --- |
| `PUT` | `/api/videos` | 当前应用 | 全量更新本地视频列表 |
| `GET` | `/api/videos` | 护士站 | 查询可播放的视频列表 |
| `POST` | `/api/playback` | 护士站 | 提交播放请求并加入队列 |
| `POST` | `/api/playback/next` | 当前应用 | 原子领取队首播放任务 |
| `PUT` | `/api/playback/status` | 当前应用 | 更新任务播放状态 |
| `GET` | `/api/playback/status` | 护士站 | 查询播放状态 |
| `GET` | `/health` | 双方 | 查询服务健康状态 |

### 4.1 接口返回值总表

| 方法和路径 | HTTP 状态码 | 返回含义 |
| --- | --- | --- |
| `PUT /api/videos` | `200 OK` | 视频列表更新成功 |
| `PUT /api/videos` | `400 Bad Request` | 请求格式错误、视频名称不合法或字段类型错误 |
| `GET /api/videos` | `200 OK` | 返回当前完整视频列表；没有视频时 `videos` 为空数组 |
| `POST /api/playback` | `202 Accepted` | 播放请求已进入队列 |
| `POST /api/playback` | `400 Bad Request` | 未传视频名称或视频名称格式不合法 |
| `POST /api/playback` | `404 Not Found` | 视频不在当前资源列表中 |
| `POST /api/playback/next` | `200 OK` | 成功领取一个队首任务 |
| `POST /api/playback/next` | `204 No Content` | 队列为空，没有待播放任务；响应体为空 |
| `PUT /api/playback/status` | `200 OK` | 播放状态更新成功 |
| `PUT /api/playback/status` | `400 Bad Request` | 任务编号缺失或状态值不合法 |
| `PUT /api/playback/status` | `404 Not Found` | 指定任务不存在 |
| `PUT /api/playback/status` | `409 Conflict` | 状态流转不合法，例如从 `completed` 改回 `playing` |
| `GET /api/playback/status` | `200 OK` | 返回当前、最近一次或指定任务的状态 |
| `GET /api/playback/status` | `404 Not Found` | 查询参数中指定的任务不存在 |
| `GET /health` | `200 OK` | 服务正常，并返回队列与播放器状态 |

除 `204 No Content` 外，所有响应均为 JSON。错误响应统一使用第 9 节定义的格式。

## 5. 视频列表接口

### 5.1 更新视频列表

当前应用启动后扫描 `res/video`，然后全量更新服务端保存的视频列表。

```http
PUT /api/videos
Content-Type: application/json
```

请求示例：

```json
{
  "videos": [
    {
      "video_name": "血压仪使用教学.mp4",
      "display_name": "血压仪使用教学",
      "size": 2780166
    },
    {
      "video_name": "医疗护理人员入科宣教.mp4",
      "display_name": "医疗护理人员入科宣教",
      "size": 25747116
    }
  ]
}
```

响应示例：

```json
{
  "success": true,
  "count": 2,
  "updated_at": "2026-07-15T16:30:00+08:00"
}
```

返回字段：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `success` | `boolean` | 固定为 `true`，表示更新成功 |
| `count` | `integer` | 更新后的视频总数 |
| `updated_at` | `string` | ISO 8601 格式的更新时间，使用带时区时间 |

空数组是合法请求，用于清空服务端保存的视频列表：

```json
{
  "videos": []
}
```

本接口采用全量覆盖。`res/video` 中已删除的视频必须同时从接口资源列表中移除。

### 5.2 查询视频列表

```http
GET /api/videos
```

响应示例：

```json
{
  "videos": [
    {
      "video_name": "血压仪使用教学.mp4",
      "display_name": "血压仪使用教学",
      "size": 2780166
    }
  ],
  "count": 1,
  "updated_at": "2026-07-15T16:30:00+08:00"
}
```

返回字段：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `videos` | `array` | 当前全部可播放视频；没有资源时为空数组 |
| `videos[].video_name` | `string` | 带扩展名的视频文件名，也是播放请求使用的值 |
| `videos[].display_name` | `string` | 护士站界面显示名称 |
| `videos[].size` | `integer` | 文件大小，单位为字节 |
| `count` | `integer` | `videos` 数组元素数量 |
| `updated_at` | `string` 或 `null` | 最近更新时间；尚未同步时为 `null` |

护士站只能使用该列表中存在的 `video_name` 创建播放任务。接口不接受绝对路径或包含 `..` 的文件路径。

## 6. 播放任务接口

### 6.1 提交播放请求

调用该接口本身即表示请求开始播放，不需要额外传递 `start_play` 标志位。

```http
POST /api/playback
Content-Type: application/json
```

请求示例：

```json
{
  "video_name": "血压仪使用教学.mp4"
}
```

响应状态码为 `202 Accepted`：

```json
{
  "success": true,
  "task_id": "10001",
  "video_name": "血压仪使用教学.mp4",
  "status": "queued",
  "queue_position": 2
}
```

返回字段：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `success` | `boolean` | 固定为 `true`，表示任务已接收 |
| `task_id` | `string` | FastAPI 自动生成的任务编号 |
| `video_name` | `string` | 本次请求播放的视频名称 |
| `status` | `string` | 固定为 `queued` |
| `queue_position` | `integer` | 当前排队位置，从 `1` 开始；正在播放的任务不计入该位置 |

`task_id` 由 FastAPI 自动生成，护士站不需要提交。保留该字段是为了区分队列中名称相同的多个播放任务。

### 6.2 领取下一个任务

当前应用按配置的轮询间隔调用该接口。

```http
POST /api/playback/next
```

有待播放任务时返回 `200 OK`：

```json
{
  "task_id": "10001",
  "video_name": "血压仪使用教学.mp4",
  "status": "claimed"
}
```

返回字段：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `task_id` | `string` | 被领取任务的编号，更新状态时必须原样传回 |
| `video_name` | `string` | 应从 `res/video` 播放的视频文件名 |
| `status` | `string` | 固定为 `claimed` |

没有待播放任务时返回：

```http
204 No Content
```

`204 No Content` 不包含 JSON 响应体，当前应用等待下一个轮询周期即可。

领取操作必须具有原子性。同一个任务只能被领取一次；当前视频播放期间，应用停止领取新任务，剩余任务继续保留在队列中。

### 6.3 更新播放状态

```http
PUT /api/playback/status
Content-Type: application/json
```

开始播放：

```json
{
  "task_id": "10001",
  "status": "playing"
}
```

播放完成：

```json
{
  "task_id": "10001",
  "status": "completed"
}
```

播放失败：

```json
{
  "task_id": "10001",
  "status": "failed",
  "message": "视频文件不存在或无法播放"
}
```

统一响应：

```json
{
  "success": true,
  "task_id": "10001",
  "status": "completed",
  "updated_at": "2026-07-15T16:35:00+08:00"
}
```

返回字段：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `success` | `boolean` | 固定为 `true`，表示状态更新成功 |
| `task_id` | `string` | 已更新的任务编号 |
| `status` | `string` | 更新后的状态，只能是 `playing`、`completed` 或 `failed` |
| `updated_at` | `string` | ISO 8601 格式的状态更新时间 |

### 6.4 查询播放状态

查询当前或最近一次播放状态：

```http
GET /api/playback/status
```

响应示例：

```json
{
  "task_id": "10001",
  "video_name": "血压仪使用教学.mp4",
  "status": "playing",
  "queue_size": 2,
  "updated_at": "2026-07-15T16:33:00+08:00"
}
```

返回字段：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `task_id` | `string` 或 `null` | 当前、最近一次或指定任务的编号 |
| `video_name` | `string` 或 `null` | 对应的视频名称 |
| `status` | `string` | `idle`、`queued`、`claimed`、`playing`、`completed` 或 `failed` |
| `queue_size` | `integer` | 当前仍处于 `queued` 状态的任务数量 |
| `message` | `string` 或 `null` | 失败原因；非失败状态为 `null`，实现时可省略该字段 |
| `updated_at` | `string` 或 `null` | 最近状态更新时间；从未产生任务时为 `null` |

按任务编号查询指定任务：

```http
GET /api/playback/status?task_id=10001
```

当前没有任何任务时：

```json
{
  "task_id": null,
  "video_name": null,
  "status": "idle",
  "queue_size": 0,
  "updated_at": null
}
```

## 7. 播放状态

| 状态 | 说明 |
| --- | --- |
| `idle` | 当前没有播放任务，仅用于整体状态查询 |
| `queued` | 已进入队列，等待播放 |
| `claimed` | 已被当前应用领取 |
| `playing` | 正在播放 |
| `completed` | 播放正常完成 |
| `failed` | 视频不存在、解码失败或播放器异常 |

正常状态流转：

```text
queued -> claimed -> playing -> completed
                    -> failed
```

无论任务成功还是失败，当前应用都应继续领取队列中的下一个任务。

## 8. 健康检查

```http
GET /health
```

响应示例：

```json
{
  "status": "ok",
  "service": "playback-api",
  "queue_size": 2,
  "player_status": "playing"
}
```

返回字段：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `status` | `string` | 固定为 `ok` |
| `service` | `string` | 固定为 `playback-api` |
| `queue_size` | `integer` | 当前待播放任务数量 |
| `player_status` | `string` | 当前播放器状态，如 `idle`、`claimed` 或 `playing` |

## 9. 错误响应

统一错误格式：

```json
{
  "success": false,
  "code": "VIDEO_NOT_FOUND",
  "message": "指定视频不在可播放列表中"
}
```

| HTTP 状态码 | 场景 |
| --- | --- |
| `400` | 请求字段缺失、状态值不合法或文件名不安全 |
| `404` | 视频或任务不存在 |
| `409` | 任务状态流转冲突 |
| `500` | 服务内部异常 |

错误码建议固定为：

| `code` | 使用场景 |
| --- | --- |
| `INVALID_REQUEST` | 请求体缺失、字段类型错误或缺少必填字段 |
| `INVALID_VIDEO_NAME` | 视频名称包含路径分隔符、`..` 或其他非法内容 |
| `VIDEO_NOT_FOUND` | 视频不在当前资源列表中 |
| `TASK_NOT_FOUND` | 任务编号不存在 |
| `INVALID_STATUS` | 状态值不在允许范围内 |
| `STATUS_CONFLICT` | 请求的状态变化违反状态机规则 |
| `INTERNAL_ERROR` | 未分类的服务内部异常 |

## 10. 应用集成约束

1. FastAPI 服务随当前应用启动和退出，不单独启动独立服务。
2. FastAPI 请求处理线程不得直接操作 PySide6 界面或播放器。
3. 当前应用通过定时器领取任务，并在 Qt 主线程调用已有 `MediaPlaybackCoordinator`。
4. 实际播放路径必须由项目根目录、固定的 `res/video` 目录和 `video_name` 安全拼接得到。
5. 视频开始播放后更新为 `playing`，收到播放器结束信号后更新为 `completed`，播放错误时更新为 `failed`。
6. 当前任务结束后才能领取下一项，保证视频严格按队列顺序播放。
7. 监听 `0.0.0.0` 会向局域网开放控制接口，部署时应通过防火墙限制为护士站所在网段访问。
