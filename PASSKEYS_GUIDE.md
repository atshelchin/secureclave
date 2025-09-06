# Passkeys 使用指南

## ⚠️ 重要提示

**错误 Code 1004 "No credentials found" 是正常的！**

这表示系统中还没有为这个域名创建任何Passkey。你需要先创建一个Passkey，然后才能登录。

## 📝 使用步骤

### 第1步：部署配置文件（必须先完成）

1. 将以下内容保存为 `apple-app-site-association` 文件（注意：没有文件扩展名）：
```json
{
  "webcredentials": {
    "apps": ["9RS8E64FWL.app.hotlabs.secureenclave"]
  }
}
```

2. 上传到你的GitHub Pages仓库：
   - 路径必须是：`.well-known/apple-app-site-association`
   - 完整URL：`https://atshelchin.github.io/.well-known/apple-app-site-association`

3. 验证文件可访问：
```bash
curl https://atshelchin.github.io/.well-known/apple-app-site-association
```

### 第2步：创建你的第一个Passkey

1. 打开应用，进入 "Passkeys" 页面
2. 在用户名字段输入一个邮箱（例如：`test@atshelchin.github.io`）
3. 点击 **"Create Passkey"** 按钮
4. 使用Face ID/Touch ID确认
5. 看到 "✅ Passkey created successfully!" 消息

### 第3步：使用Passkey登录

1. 点击 **"Sign In with Passkey"** 按钮
2. 系统会显示可用的Passkey列表
3. 选择你创建的Passkey
4. 使用Face ID/Touch ID确认
5. 看到 "✅ Passkey authentication successful!" 消息

## 🔍 调试提示

### 常见错误及解决方法

| 错误代码 | 含义 | 解决方法 |
|---------|------|----------|
| 1004 | 没有找到凭据 | 先创建一个Passkey |
| 1001 | 用户取消 | 正常，用户主动取消了操作 |
| 1003 | 未处理 | 检查域名配置是否正确 |

### 检查清单

- [ ] GitHub Pages 配置文件已部署
- [ ] 文件URL可以访问（使用curl测试）
- [ ] Team ID 正确：`9RS8E64FWL`
- [ ] Bundle ID 正确：`app.hotlabs.secureenclave`
- [ ] 设备已设置Face ID/Touch ID
- [ ] 已连接网络（首次验证需要）

## 📱 设备要求

- iOS 16.0+ 或 macOS 13+
- 已启用生物识别（Face ID/Touch ID）
- 已登录iCloud（用于同步Passkeys）

## 🔄 Passkeys同步

创建的Passkeys会自动通过iCloud Keychain同步到：
- 同一Apple ID的其他设备
- 支持的浏览器（Safari）
- 其他支持Passkeys的应用

## ⚙️ 高级设置

### 自定义域名

如果你想使用自己的域名而不是 `atshelchin.github.io`：

1. 修改 `PasskeysManager.swift` 中的域名：
```swift
let domain = "your-domain.com"
let rpID = "your-domain.com"
```

2. 更新 `apple-app-site-association` 并部署到新域名

### 测试环境

对于本地测试，你可以：
1. 使用 `localhost` 作为域名（仅限开发）
2. 使用 ngrok 创建临时HTTPS隧道
3. 使用自签名证书的本地服务器

## 📚 参考资源

- [Apple: About Passkeys](https://developer.apple.com/passkeys/)
- [WWDC: Meet Passkeys](https://developer.apple.com/videos/play/wwdc2022/10092/)
- [Associated Domains](https://developer.apple.com/documentation/xcode/supporting-associated-domains)