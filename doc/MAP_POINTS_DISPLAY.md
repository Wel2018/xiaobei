# 地图点位绘制功能实现说明

## 概述

实现了从后端API读取地图导航点位，并将其绘制到主页地图组件中的完整功能。支持动态切换地图、实时更新点位显示。

## 功能特性

### 1. 坐标转换系统

#### 真实世界坐标 → 地图像素坐标
```typescript
// 从后端获取的点位坐标（单位：米）
const worldX = point.x * scaleRatio + BASE_W / 2
const worldY = -point.y * scaleRatio + BASE_H / 2  // Y轴翻转
```

**关键点：**
- **分辨率换算**: `scaleRatio = mapNaturalWidth / BASE_W`
- **Y轴翻转**: 真实世界Y轴向上为正，屏幕Y轴向下为正，需要取反
- **原点偏移**: 假设地图原点在中心，需要加上 `BASE_W/2` 和 `BASE_H/2`

#### 地图像素坐标 → 屏幕坐标
```typescript
const screenX = worldX * zoom.value + tx.value
const screenY = worldY * zoom.value + ty.value
```

考虑了当前的缩放比例(zoom)和平移偏移(tx, ty)。

### 2. 点位绘制样式

导航点位采用与机器人相同的绘制方式：

- **圆形背景**: 半透明填充，带黑色描边
  - 路径点: `rgba(59, 130, 246, 0.6)` (蓝色)
  - 充电点: `rgba(245, 158, 11, 0.6)` (橙色)

- **内部三角形**: 表示朝向方向
  - 根据 `yaw` (弧度) 计算三角形顶点
  - `yaw=0` 时指向下方
  - 使用与机器人相同的三角函数公式

- **文本标签**: 显示在圆形下方
  - 位置: `screenY + screenR + 15`
  - 字体大小: 11px
  - 颜色与圆形一致
  - 带黑色描边增强可读性

### 3. 地图管理对话框增强

**文件**: `MapSettingsDialog.vue`

新增功能：
- **应用地图按钮**: 用户选择地图后可以点击"应用地图"按钮
- **持久化存储**: 将选中的地图ID保存到localStorage
- **全局事件通知**: 触发`map-changed`自定义事件通知其他组件

```typescript
// 应用当前选中的地图
function handleApplyMap() {
  if (!selectedMapId.value) {
    alert('请先选择一个地图')
    return
  }
  
  // 保存当前地图ID到localStorage
  localStorage.setItem('current_map_id', selectedMapId.value)
  
  // 触发全局事件通知其他组件
  window.dispatchEvent(new CustomEvent('map-changed', { 
    detail: { mapId: selectedMapId.value } 
  }))
  
  alert(`已切换到地图: ${selectedMapId.value}`)
}
```

### 2. 主监控页面集成

**文件**: `MonitorDashboard.vue`

新增功能：
- **navPoints状态**: 存储当前地图的导航点位数据
- **loadMapPoints函数**: 从后端API加载指定地图的点位信息
- **事件监听**: 监听`map-changed`事件，自动加载新地图的点位
- **生命周期管理**: onMounted时加载默认地图，onUnmounted时清理事件监听

```typescript
// 加载地图点位
async function loadMapPoints(mapId: string) {
  try {
    const response = await fetch(`${API_BASE_URL}/detail/${mapId}`)
    if (!response.ok) {
      throw new Error('加载地图详情失败')
    }
    
    const data = await response.json()
    navPoints.value = data.points || []
    console.log(`已加载地图 ${mapId} 的 ${navPoints.value.length} 个点位`)
  } catch (error) {
    console.error('加载地图点位失败:', error)
    navPoints.value = []
  }
}

// 处理地图切换事件
function handleMapChanged(event: Event) {
  const customEvent = event as CustomEvent
  const mapId = customEvent.detail?.mapId
  
  if (mapId) {
    console.log('检测到地图切换:', mapId)
    loadMapPoints(mapId)
  }
}
```

### 3. 地图查看器组件增强

**文件**: `MapViewer.vue`

新增功能：
- **navPoints属性**: 接收父组件传递的导航点位数据
- **scaledNavPoints计算属性**: 将真实世界坐标转换为屏幕坐标，并计算三角形顶点
- **SVG点位绘制**: 绘制圆形、三角形和文本标签，与机器人样式一致

#### 坐标转换逻辑

```typescript
const scaledNavPoints = computed(() => {
  if (!props.navPoints || props.navPoints.length === 0) return []

  const sx = mapNatural.value.w && mapNatural.value.h ? mapNatural.value.w / BASE_W : 1
  const sy = mapNatural.value.w && mapNatural.value.h ? mapNatural.value.h / BASE_H : 1
  const sr = 5 * ((sx + sy) / 2) // 圆形半径（与机器人相同）

  return props.navPoints.map((point) => {
    // 将真实世界坐标(m)转换为地图像素坐标
    const worldX = point.x * sx + BASE_W / 2
    const worldY = -point.y * sy + BASE_H / 2 // Y轴翻转

    // 转换为屏幕坐标（考虑缩放和平移）
    const screenX = worldX * zoom.value + tx.value
    const screenY = worldY * zoom.value + ty.value

    // 圆形半径根据zoom缩放
    const screenR = sr * zoom.value

    // 根据yaw（弧度）计算三角形顶点（yaw=0时指向下方）
    const yaw = point.yaw || 0
    const tipX = screenX + screenR * 0.7 * Math.sin(yaw)
    const tipY = screenY + screenR * 0.7 * Math.cos(yaw)
    const leftX = screenX - screenR * 0.5 * Math.cos(yaw) - screenR * 0.6 * Math.sin(yaw)
    const leftY = screenY + screenR * 0.5 * Math.sin(yaw) - screenR * 0.6 * Math.cos(yaw)
    const rightX = screenX + screenR * 0.5 * Math.cos(yaw) - screenR * 0.6 * Math.sin(yaw)
    const rightY = screenY - screenR * 0.5 * Math.sin(yaw) - screenR * 0.6 * Math.cos(yaw)
    const trianglePoints = `${tipX},${tipY} ${leftX},${leftY} ${rightX},${rightY}`

    return {
      ...point,
      screenX,
      screenY,
      screenR,
      trianglePoints,
    }
  })
})
```

#### SVG绘制

```vue
<!-- 导航点位 -->
<g v-for="point in scaledNavPoints" :key="point.id">
  <!-- 圆形背景（带透明度） -->
  <circle 
    :cx="point.screenX" 
    :cy="point.screenY" 
    :r="point.screenR"
    :fill="point.type === 'charge' ? 'rgba(245, 158, 11, 0.6)' : 'rgba(59, 130, 246, 0.6)'"
    stroke="#0b0b0b"
    stroke-width="1.5"
  />

  <!-- 内部拉长的三角形（表示方向，根据 yaw 旋转） -->
  <polygon 
    :points="point.trianglePoints" 
    fill="rgba(11, 11, 11, 0.85)" 
  />

  <!-- 点位名称标签（在圆形下方） -->
  <text 
    :x="point.screenX" 
    :y="point.screenY + point.screenR + 15" 
    font-size="11" 
    :fill="point.type === 'charge' ? '#f59e0b' : '#3b82f6'"
    stroke="#000"
    stroke-width="0.3"
    style="font-weight: 600; paint-order: stroke fill;"
    text-anchor="middle"
  >
    {{ point.name }}
  </text>
</g>
```

## 数据流

```
用户操作 → MapSettingsDialog
              ↓
    点击"应用地图"按钮
              ↓
    保存到localStorage + 触发自定义事件
              ↓
    MonitorDashboard监听到事件
              ↓
    调用loadMapPoints(mapId)
              ↓
    从后端API获取地图详情
              ↓
    更新navPoints状态
              ↓
    传递给MapViewer组件
              ↓
    scaledNavPoints计算坐标
              ↓
    SVG绘制点位和标签
```

## 点位类型区分

- **路径点 (waypoint)**: 蓝色圆点 (#3b82f6)
- **充电点 (charge)**: 橙色圆点 (#f59e0b)

## 坐标系统

### 后端坐标（真实世界）
- 单位：米 (m)
- 原点：根据地图calibration.yaml配置
- Y轴：向上为正

### 前端坐标（屏幕显示）
- 单位：像素 (px)
- 原点：左上角
- Y轴：向下为正（需要翻转）

### 转换公式
```
worldX = point.x * scaleRatio + BASE_W / 2
worldY = -point.y * scaleRatio + BASE_H / 2  // Y轴翻转
screenX = worldX * zoom + translateX
screenY = worldY * zoom + translateY
```

## 使用流程

1. **打开地图设置**: 点击顶部导航栏的"地图设置"
2. **选择地图**: 在地图列表中点击要使用的地图
3. **查看详情**: 右侧显示地图图片、信息和导航点位列表
4. **应用地图**: 点击底部"应用地图"按钮
5. **自动刷新**: 主页地图立即显示新地图的点位

## 技术要点

### 1. 事件驱动架构
使用CustomEvent实现组件间通信，避免直接依赖关系。

### 2. 响应式更新
Vue的computed属性确保点位坐标随地图缩放/平移自动更新。

### 3. 性能优化
- 只在点位数据变化时重新计算
- SVG渲染比Canvas更适合这种场景
- 点位数量较多时使用虚拟滚动（未来优化）

### 4. 容错处理
- API请求失败时清空点位列表
- 空状态友好提示
- 网络错误捕获和日志记录

## 后端API

### GET `/api/v1/map/detail/{map_id}`

**响应示例**:
```json
{
  "id": "hospital_one_12F",
  "name": "hospital_one_12F",
  "points": [
    {
      "id": "10",
      "name": "10",
      "x": 7.02,
      "y": -25.35,
      "z": 0.0,
      "yaw": 2.36,
      "floor": 12,
      "type": "waypoint"
    },
    {
      "id": "charge_12F",
      "name": "charge_12F",
      "x": 0.08,
      "y": 1.45,
      "z": 0.0,
      "yaw": 0.0,
      "floor": 12,
      "type": "charge"
    }
  ]
}
```

## 后续优化建议

1. **点位交互**: 点击点位显示详细信息
2. **路径规划**: 显示点位之间的连接线和路径
3. **机器人实时位置**: 结合WebSocket实时更新机器人位置
4. **地图缓存**: 缓存已加载的地图数据，减少API请求
5. **点位筛选**: 按类型、楼层筛选显示的点位
6. **坐标校准**: 提供更精确的坐标转换算法
