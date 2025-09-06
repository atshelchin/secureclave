# 🔄 强制刷新 Apple CDN AASA 缓存

## 当前问题
- **CDN 缓存**: `9RS8E64FWL.app.hotlabs.secureenclave` (旧的)
- **GitHub 实际**: `F9W689P9NE.app.hotlabs.secureenclave` (新的)
- **CDN URL**: https://app-site-association.cdn-apple.com/a/v1/atshelchin.github.io

## 🎯 触发刷新的方法

### 方法 1: 使用 Developer Mode（iOS 16+）
1. **在 iPhone 上启用开发者模式**：
   - 设置 > 隐私与安全性 > 开发者模式 > 开启
   - 重启设备

2. **清除 AASA 缓存**：
   ```bash
   # 在 Mac 上通过 Xcode
   xcrun simctl spawn booted log stream --debug --predicate 'subsystem == "com.apple.AuthenticationServices"'
   ```

3. **强制重新下载**：
   - 删除应用
   - 重启设备
   - 重新安装应用

### 方法 2: 使用 swcutil 命令（macOS）
```bash
# 验证当前状态
swcutil verify -d atshelchin.github.io -s webcredentials

# 强制刷新（需要 sudo）
sudo swcutil reset

# 再次验证
swcutil verify -d atshelchin.github.io -s webcredentials
```

### 方法 3: 修改 Bundle ID 触发
临时修改 Bundle ID 可以绕过缓存：
1. 在 Xcode 中修改 Bundle ID 为 `app.hotlabs.secureenclave2`
2. 更新 AASA 文件添加新 Bundle ID
3. 部署后测试
4. 确认工作后改回原 Bundle ID

### 方法 4: 使用备用域名
```json
{
  "webcredentials": {
    "apps": ["F9W689P9NE.app.hotlabs.secureenclave"]
  },
  "alternate": {
    "apps": ["F9W689P9NE.app.hotlabs.secureenclave"],
    "paths": ["*"]
  }
}
```

### 方法 5: Apple 开发者网站触发
1. 登录 [Apple Developer](https://developer.apple.com)
2. 进入 **Certificates, Identifiers & Profiles**
3. 找到你的 App ID
4. 编辑 **Associated Domains**
5. 删除并重新添加 `webcredentials:atshelchin.github.io`
6. 保存更改

这会触发 Apple 重新验证域名。

### 方法 6: 使用 TestFlight
TestFlight 版本会更频繁地检查 AASA：
1. 上传应用到 TestFlight
2. 安装 TestFlight 版本
3. TestFlight 通常会绕过一些缓存

### 方法 7: 联系 Apple 支持
如果缓存超过 72 小时未更新：
1. 通过 [开发者支持](https://developer.apple.com/support/) 提交请求
2. 提供域名和 Team ID
3. 请求手动刷新 CDN 缓存

## 🔍 验证命令

### 检查 CDN 状态
```bash
# 查看 CDN 缓存
curl -s https://app-site-association.cdn-apple.com/a/v1/atshelchin.github.io | jq .

# 查看源文件
curl -s https://atshelchin.github.io/.well-known/apple-app-site-association | jq .

# 对比 Team ID
echo "CDN:" && curl -s https://app-site-association.cdn-apple.com/a/v1/atshelchin.github.io | grep -o '[A-Z0-9]*\.app'
echo "Source:" && curl -s https://atshelchin.github.io/.well-known/apple-app-site-association | grep -o '[A-Z0-9]*\.app'
```

### iOS 设备日志
在 Xcode 中查看设备日志：
1. 连接 iPhone 到 Mac
2. Xcode > Window > Devices and Simulators
3. 选择设备 > Open Console
4. 过滤 "swcd" 或 "AuthenticationServices"

## ⏰ 预期时间

| 方法 | 生效时间 |
|-----|---------|
| Developer Mode | 立即 |
| swcutil reset | 几分钟 |
| 修改 Bundle ID | 立即 |
| 编辑 App ID | 1-2 小时 |
| TestFlight | 几小时 |
| 自然刷新 | 24-48 小时 |
| Apple 支持 | 1-3 工作日 |

## 💡 建议

1. **立即尝试**: 使用 Developer Mode 或 swcutil
2. **短期方案**: 修改 Bundle ID 或使用 TestFlight
3. **长期等待**: CDN 会在 24-48 小时内自动刷新

## 🐛 调试提示

在 PasskeysManager 中添加 CDN 检查：
```swift
func checkCDNStatus() {
    let cdnURL = URL(string: "https://app-site-association.cdn-apple.com/a/v1/atshelchin.github.io")!
    URLSession.shared.dataTask(with: cdnURL) { data, _, _ in
        if let data = data,
           let string = String(data: data, encoding: .utf8) {
            if string.contains("F9W689P9NE") {
                print("✅ CDN 已更新到正确的 Team ID")
            } else if string.contains("9RS8E64FWL") {
                print("❌ CDN 仍在使用旧的 Team ID")
            }
        }
    }.resume()
}
```

## 📝 注意事项

- CDN 缓存是全球分布的，不同地区可能更新时间不同
- 开发期间建议使用 localhost 或内网 IP 测试
- 生产环境务必提前 48 小时部署 AASA 文件