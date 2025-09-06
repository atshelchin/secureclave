# Apple Developer Team ID 说明

## 什么是 Team ID？

Team ID 是苹果分配给每个开发者账号的唯一标识符，格式为10个字符（字母和数字）。

例如：`9RS8E64FWL`

## 如何查找你的 Team ID？

### 方法1：通过 Xcode
1. 打开 Xcode
2. 点击菜单：Xcode → Settings (或 Preferences)
3. 选择 "Accounts" 标签
4. 选择你的 Apple ID
5. 在右侧面板查看 Team Name，旁边括号内就是 Team ID

### 方法2：通过 Apple Developer 网站
1. 登录 https://developer.apple.com
2. 进入 Account
3. 在 Membership 部分查看 Team ID

### 方法3：通过项目设置
1. 在 Xcode 中打开项目
2. 选择项目文件（蓝色图标）
3. 选择 Target
4. 在 "Signing & Capabilities" 标签下
5. Team 下拉菜单会显示：Team Name (Team ID)

## 在本项目中的使用

### 1. Bundle Identifier
- 当前设置：`app.hotlabs.secureenclave`
- 这是你的应用的唯一标识

### 2. App ID (用于 Passkeys)
- 格式：`TeamID.BundleID`
- 例如：`9RS8E64FWL.app.hotlabs.secureenclave`

### 3. apple-app-site-association 文件
```json
{
  "webcredentials": {
    "apps": [
      "9RS8E64FWL.app.hotlabs.secureenclave"
    ]
  }
}
```

这个文件需要部署到：
`https://atshelchin.github.io/.well-known/apple-app-site-association`

### 4. Keychain Access Groups
在 entitlements 文件中：
```xml
<key>keychain-access-groups</key>
<array>
    <string>$(AppIdentifierPrefix)app.hotlabs.secureenclave</string>
</array>
```

`$(AppIdentifierPrefix)` 会自动被替换为你的 Team ID。

## 重要提示

- Team ID 是自动生成的，无法更改
- 免费开发者账号和付费账号都有 Team ID
- 同一个 Apple ID 可能有多个 Team（个人和公司）
- Team ID 用于标识应用的所有者，确保安全性

## 故障排除

如果 Passkeys 不工作：
1. 确认 Team ID 正确
2. 检查 apple-app-site-association 文件中的 App ID 格式
3. 确保 Bundle ID 匹配
4. 验证 Associated Domains 配置正确