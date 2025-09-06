# 📱 清除 iPhone 本地 AASA 缓存

## 🚨 问题
即使 Apple CDN 更新了，iPhone 可能仍在使用本地缓存的旧 AASA 配置。

## 🔄 清除方法（按效果排序）

### 方法 1：完全重置（最彻底）✅
1. **删除应用**
2. **重启 iPhone**（关机 → 开机）
3. **重置网络设置**：
   - 设置 → 通用 → 传输或还原 iPhone → 还原 → 还原网络设置
   - ⚠️ 注意：这会清除 Wi-Fi 密码
4. **重新安装应用**

### 方法 2：开发者模式清除 🛠
1. **启用开发者模式**：
   - 设置 → 隐私与安全性 → 开发者模式 → 开启
   - 重启设备
2. **在 Mac 上通过 Xcode Console 查看日志**：
   ```bash
   # 连接 iPhone 到 Mac
   # Xcode → Window → Devices and Simulators
   # 选择设备 → Open Console
   # 过滤: swcd
   ```
3. **删除应用并重新安装**

### 方法 3：快速清除（推荐）⚡️
1. **删除应用**
2. **清除 Safari 缓存**：
   - 设置 → Safari → 清除历史记录与网站数据
3. **开启飞行模式 30 秒**
4. **关闭飞行模式**
5. **重新安装应用**

### 方法 4：强制刷新 AASA 🔄
1. **删除应用**
2. **修改系统时间**：
   - 设置 → 通用 → 日期与时间
   - 关闭"自动设置"
   - 将日期调到未来一周
3. **重启 iPhone**
4. **改回自动时间**
5. **重新安装应用**

### 方法 5：使用 TestFlight 📦
TestFlight 版本会更积极地刷新 AASA：
1. 上传应用到 TestFlight
2. 通过 TestFlight 安装
3. TestFlight 通常会忽略本地缓存

## 🔍 验证缓存状态

### 在 Mac 上检查（需要 iPhone 连接）
```bash
# 使用 Console.app 查看日志
# 过滤关键词：
# - swcd
# - AuthenticationServices
# - webcredentials
# - atshelchin.github.io
```

### 在 iPhone 上检查
1. 尝试创建 Passkey
2. 查看错误信息中的 Team ID
3. 如果显示 `9RS8E64FWL` → 使用旧缓存
4. 如果显示 `F9W689P9NE` → 使用新配置

## 📝 调试日志

在 PasskeysManager 中添加缓存检测：

```swift
func checkLocalCache() {
    log("===== CACHE STATUS CHECK =====")
    log("Expected Team ID: F9W689P9NE")
    log("If error shows 9RS8E64FWL, local cache is outdated")
    log("Try Method 1 or 3 to clear cache")
    log("==============================")
}
```

## ⚡️ 最快解决方案

如果急需测试，直接使用 `shelchin2025.github.io`：
1. 在应用中切换到 "GitHub Pages (2025)"
2. 这个域名没有缓存问题
3. 可以立即创建 Passkey

## 🎯 推荐步骤

1. **先试方法 3**（快速清除）- 5 分钟
2. **如果不行，用方法 1**（完全重置）- 10 分钟
3. **或者直接用 shelchin2025.github.io** - 立即可用

## 💡 提示

- iPhone 缓存 AASA 约 **7 天**
- 删除应用不一定清除缓存
- 重置网络设置是最彻底的方法
- TestFlight 和开发者模式更容易刷新

## 🔄 防止未来缓存问题

1. 使用多个 RP ID 域名
2. 在 AASA 文件中添加版本号
3. 使用 TestFlight 进行测试
4. 保持开发者模式开启