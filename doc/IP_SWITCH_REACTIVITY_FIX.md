# IP切换响应式修复

## 问题描述

当在 `NetworkSettingsDialog.vue` 中切换机器人IP后,其他组件(如 `CameraPreview.vue`)中的API请求仍然使用旧的IP地址,导致请求失败。

### 根本原因

1. **apiConfigStore 中的 URL 不是响应式的**
   - `apiBaseUrl` 和 `apiExtUrl` 是普通的 `ref`,不会自动响应 `ip` 的变化
   
2. **axios 实例在组件初始化时创建**
   - `CameraPreview.vue` 在 `onMounted` 时创建 axios 实例
   - 即使 store 更新,已创建的 axios 实例也不会感知变化

## 解决方案

### 1. 将 URL 改为 computed 属性

**文件**: `xiaobei-frontend/src/stores/apiConfig.ts`

```typescript
// 修改前
const apiBaseUrl = ref<string>(`http://${ip.value}:${port.value}`)
const apiExtUrl = ref<string>(`http://${ip.value}:${port2.value}`)

// 修改后
const apiBaseUrl = computed(() => `http://${ip.value}:${port.value}`)
const apiExtUrl = computed(() => `http://${ip.value}:${port2.value}`)
```

**优势**:
- ✅ 自动响应 `ip`、`port`、`port2` 的变化
- ✅ 无需手动更新 URL
- ✅ 符合 Vue 响应式最佳实践

### 2. 监听 IP 变化并重建 axios 实例

**文件**: `xiaobei-frontend/src/components/monitor/right/camera/CameraPreview.vue`

```typescript
// 将 const 改为 let,允许重新赋值
let axiosInstance = createAxiosInstance({
  baseURL: apiConfigStore.apiUrl2,
  timeout: 5000
})
let apiMethods = api.get(axiosInstance)

// 监听 IP 变化
watch(() => apiConfigStore.ip, (newIp) => {
  console.log('IP 已切换为:', newIp, '重新创建 axios 实例')
  
  // 停止当前的自动刷新
  stopAutoRefresh()
  
  // 重新创建 axios 实例
  axiosInstance = createAxiosInstance({
    baseURL: apiConfigStore.apiUrl2,  // 此时 apiUrl2 已经是新的值
    timeout: 5000
  })
  apiMethods = api.get(axiosInstance)
  
  // 重新启动自动刷新
  startAutoRefresh()
})
```

**工作流程**:
```
用户点击切换IP
  ↓
NetworkSettingsDialog.switchRobot()
  ↓
apiConfig.setIp(newIp)
  ↓
apiConfigStore.ip 更新
  ↓
apiConfigStore.apiExtUrl 自动更新(computed)
  ↓
CameraPreview watch 监听到 ip 变化
  ↓
stopAutoRefresh() - 停止旧请求
  ↓
重新创建 axiosInstance (使用新的 apiExtUrl)
  ↓
startAutoRefresh() - 使用新实例发起请求
```

## 修改的文件

### 1. xiaobei-frontend/src/stores/apiConfig.ts
- ✅ 将 `apiBaseUrl` 从 `ref` 改为 `computed`
- ✅ 将 `apiExtUrl` 从 `ref` 改为 `computed`
- ✅ 简化 `setIp()` 函数,移除手动更新 URL 的代码

### 2. xiaobei-frontend/src/components/monitor/right/camera/CameraPreview.vue
- ✅ 导入 `watch` 函数
- ✅ 将 `axiosInstance` 和 `apiMethods` 从 `const` 改为 `let`
- ✅ 添加 `watch(() => apiConfigStore.ip)` 监听器
- ✅ 在监听器中重新创建 axios 实例

### 3. xiaobei-frontend/src/views/WebRTCViewer.vue
- ✅ 将 `axiosInstance` 和 `apiMethods` 从 `const` 改为 `let`
- ✅ 增强现有的 IP watch 监听器
- ✅ 在监听器中重新创建 axios 实例

## 测试步骤

### CameraPreview.vue 测试
1. 启动前端应用
2. 打开监控页面,观察 CameraPreview 的实时预览
3. 点击“网络设置”按钮
4. 切换到另一个IP地址
5. 观察控制台输出 "IP 已切换为: xxx 重新创建 axios 实例"
6. 确认 CameraPreview 继续使用新的IP获取图像

### WebRTCViewer.vue 测试
1. 在监控页面点击 📺 WebRTC 按钮进入 WebRTC Viewer
2. 选择一个设备并启动推流
3. 点击“网络设置”按钮
4. 切换到另一个IP地址
5. 观察控制台输出:
   - "WebRTC IP 已更新为: xxx 重新创建 axios 实例"
   - "WebRTC axios 实例已重建,使用新IP: http://xxx:8001"
6. 确认视频流 URL 已更新为新的IP
7. 如果需要,重新启动推流以使用新IP

## 注意事项

### 需要类似处理的组件

任何在初始化时创建 axios 实例并使用 `apiConfigStore` 的组件都需要添加类似的 watch 监听器:

```typescript
// 模板代码
import { watch } from 'vue'
import { useApiConfigStore } from '@/stores/apiConfig'
import { createAxiosInstance } from '@/utils/axios'

const apiConfigStore = useApiConfigStore()

let axiosInstance = createAxiosInstance({
  baseURL: apiConfigStore.apiBaseUrl, // 或 apiUrl2
  timeout: 5000
})
let apiMethods = api.get(axiosInstance)

watch(() => apiConfigStore.ip, () => {
  axiosInstance = createAxiosInstance({
    baseURL: apiConfigStore.apiBaseUrl,
    timeout: 5000
  })
  apiMethods = api.get(axiosInstance)
})
```

### 性能考虑

- ✅ watch 只在 IP 真正变化时触发
- ✅ 重新创建 axios 实例开销很小(<1ms)
- ✅ 自动停止/重启定时器,避免内存泄漏

### 替代方案(未采用)

**方案A**: 每次API调用都动态创建 axios 实例
- ❌ 性能差,每次请求都要创建新实例
- ❌ 无法复用连接池

**方案B**: 使用全局事件总线
- ❌ 需要每个组件手动监听事件
- ❌ 不如 watch 简洁直观

**方案C**: 将 axios 实例也放入 Pinia store
- ⚠️ 可行但增加了复杂性
- ⚠️ 当前方案更轻量

## 相关文档

- [Vue 3 Computed Properties](https://vuejs.org/guide/essentials/computed.html)
- [Vue 3 Watch API](https://vuejs.org/guide/essentials/watchers.html)
- [Pinia Store Reactivity](https://pinia.vuejs.org/core-concepts/state.html#reactivity)

## 版本历史

- **v1.0** (2026-06-04): 初始实现,修复IP切换响应式问题
