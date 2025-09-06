# 🔑 Passkeys Domain 配置指南

## ⚠️ 重要：RP ID 必须与 Associated Domains 一致！

### 什么是 RP ID？
**RP ID (Relying Party Identifier)** 是 WebAuthn 协议中用于标识依赖方（你的服务）的域名标识符。

## ✅ 正确配置示例

### 1. PasskeysManager 中的设置
```swift
class PasskeysManager {
    let domain = "atshelchin.github.io"    // 你的域名
    let rpID = "atshelchin.github.io"      // 必须与 domain 一致！
}
```

### 2. Entitlements 文件配置
```xml
<key>com.apple.developer.associated-domains</key>
<array>
    <string>webcredentials:atshelchin.github.io</string>  <!-- 必须与 rpID 一致 -->
</array>
```

### 3. AASA 文件配置
文件位置：`https://atshelchin.github.io/.well-known/apple-app-site-association`
```json
{
  "webcredentials": {
    "apps": ["9RS8E64FWL.app.hotlabs.secureenclave"]  // TeamID.BundleID
  }
}
```

## ❌ 常见错误及解决方案

### 错误 1：RP ID 与 Associated Domains 不匹配

**错误配置示例：**
```swift
// PasskeysManager.swift
let rpID = "example.com"  // 错误！与 Associated Domains 不一致

// Entitlements
webcredentials:atshelchin.github.io  // 不匹配！
```

**错误信息：**
- Error Code 1001: "The operation couldn't be completed"
- "Authentication failed - Check if Associated Domains is configured"

**解决方案：**
确保所有地方使用相同的域名：
```swift
let rpID = "atshelchin.github.io"  // 正确！
```

### 错误 2：使用了子域名

**错误配置：**
```swift
let rpID = "api.atshelchin.github.io"  // 错误！使用了子域名
```

**正确配置：**
```swift
let rpID = "atshelchin.github.io"  // 使用主域名
```

> 注意：RP ID 可以是主域名，然后在子域名下也能使用

### 错误 3：包含了协议前缀

**错误配置：**
```swift
let rpID = "https://atshelchin.github.io"  // 错误！包含了 https://
```

**正确配置：**
```swift
let rpID = "atshelchin.github.io"  // 只要域名部分
```

### 错误 4：AASA 文件不可访问

**检查方法：**
```bash
# 测试 AASA 文件是否可访问
curl https://atshelchin.github.io/.well-known/apple-app-site-association

# 检查 HTTP 状态码
curl -I https://atshelchin.github.io/.well-known/apple-app-site-association
```

**应该返回：**
- HTTP 200 OK
- Content-Type: application/json

## 🔍 调试检查清单

### 1. 验证配置一致性
```swift
// 在 PasskeysManager 中添加验证
func validateConfiguration() {
    print("====== PASSKEYS CONFIGURATION ======")
    print("RP ID: \(rpID)")
    print("Domain: \(domain)")
    print("Team ID: 9RS8E64FWL")
    print("Bundle ID: app.hotlabs.secureenclave")
    
    // 检查是否一致
    assert(rpID == domain, "RP ID must match domain!")
}
```

### 2. 检查 Entitlements
在 Xcode 中：
1. 选择 Target → Signing & Capabilities
2. 查看 Associated Domains
3. 确认值为：`webcredentials:atshelchin.github.io`

### 3. 验证 AASA 文件
```bash
# 下载并验证 JSON 格式
curl https://atshelchin.github.io/.well-known/apple-app-site-association | python -m json.tool
```

### 4. 清理缓存
如果修改了配置：
1. 删除应用
2. 重启设备
3. 重新安装应用
4. 等待几分钟让 Apple 刷新 AASA 缓存

## 📊 配置对照表

| 配置项 | 正确值 | 位置 |
|--------|--------|------|
| RP ID | `atshelchin.github.io` | PasskeysManager.swift |
| Domain | `atshelchin.github.io` | PasskeysManager.swift |
| Associated Domain | `webcredentials:atshelchin.github.io` | Entitlements |
| AASA URL | `https://atshelchin.github.io/.well-known/apple-app-site-association` | 服务器 |
| Team ID | `9RS8E64FWL` | AASA 文件 |
| Bundle ID | `app.hotlabs.secureenclave` | AASA 文件 |

## 🚨 重要提示

1. **RP ID 一旦设置不能更改**
   - 创建的 Passkey 绑定到特定 RP ID
   - 更改 RP ID 会导致已有 Passkey 无法使用

2. **测试环境与生产环境**
   - 开发时可以使用不同域名
   - 但需要相应配置 Associated Domains

3. **多域名支持**
   - 可以在 Associated Domains 添加多个域名
   - 每个域名需要单独的 AASA 文件

## 💡 最佳实践

1. **使用主域名作为 RP ID**
   ```swift
   let rpID = "example.com"  // 不要用 www.example.com
   ```

2. **保持配置同步**
   - 创建配置文件统一管理
   ```swift
   struct PasskeysConfig {
       static let domain = "atshelchin.github.io"
       static let rpID = domain  // 确保一致
       static let teamID = "9RS8E64FWL"
       static let bundleID = "app.hotlabs.secureenclave"
   }
   ```

3. **添加运行时检查**
   ```swift
   #if DEBUG
   // 开发时检查配置
   assert(rpID == domain, "Configuration mismatch!")
   #endif
   ```

## 🔧 故障排除

### 症状：Passkey 创建失败，错误代码 1001
**原因：** RP ID 与 Associated Domains 不匹配
**解决：** 检查并统一所有配置中的域名

### 症状：Passkey 创建成功但登录失败
**原因：** 创建和登录时使用了不同的 RP ID
**解决：** 确保 `createCredentialRegistrationRequest` 和 `createCredentialAssertionRequest` 使用相同的 RP ID

### 症状：仅在真机上失败，模拟器正常
**原因：** AASA 文件配置错误或不可访问
**解决：** 验证 AASA 文件的 URL 和内容

## 📚 参考资料

- [Apple: Supporting Associated Domains](https://developer.apple.com/documentation/xcode/supporting-associated-domains)
- [WebAuthn RP ID](https://www.w3.org/TR/webauthn/#rp-id)
- [Passkeys Developer Documentation](https://developer.apple.com/documentation/authenticationservices/public-private_key_authentication/supporting_passkeys)