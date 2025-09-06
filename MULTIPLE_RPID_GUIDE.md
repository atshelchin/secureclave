# 🔑 Passkeys 多个 RP ID 配置指南

## 📋 可以注册多个 RP ID 吗？

**是的！** 一个应用可以支持多个 RP ID，但每个 RP ID 都是独立的。

## 🎯 重要概念

### 1. RP ID 的独立性
- 每个 RP ID 的 Passkey 是**完全独立**的
- 为 `example.com` 创建的 Passkey **不能**用于 `another.com`
- 用户需要为每个域名分别创建 Passkey

### 2. 子域名规则
一个 RP ID 可以覆盖其所有子域名：
- RP ID: `example.com` 
- 可用于: `example.com`, `www.example.com`, `app.example.com`
- 不能用于: `another.com`

## 📱 在 iOS 应用中配置多个 RP ID

### 方法 1：Associated Domains 配置多个域名

**entitlements 文件：**
```xml
<key>com.apple.developer.associated-domains</key>
<array>
    <string>webcredentials:atshelchin.github.io</string>
    <string>webcredentials:shelchin2025.github.io</string>
    <string>webcredentials:custom-domain.com</string>
</array>
```

### 方法 2：动态切换 RP ID

```swift
class MultiRPIDPasskeysManager: NSObject, ObservableObject {
    // 支持多个 RP ID
    enum SupportedDomain: String, CaseIterable {
        case github = "atshelchin.github.io"
        case github2 = "shelchin2025.github.io"
        case custom = "custom-domain.com"
        
        var displayName: String {
            switch self {
            case .github: return "GitHub Pages (Main)"
            case .github2: return "GitHub Pages (2025)"
            case .custom: return "Custom Domain"
            }
        }
    }
    
    @Published var currentDomain: SupportedDomain = .github
    
    // 为特定域名创建 Passkey
    func createPasskey(for domain: SupportedDomain, username: String) {
        let rpID = domain.rawValue
        let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(
            relyingPartyIdentifier: rpID
        )
        
        // ... 创建流程
    }
    
    // 使用特定域名的 Passkey 登录
    func signIn(with domain: SupportedDomain) {
        let rpID = domain.rawValue
        let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(
            relyingPartyIdentifier: rpID
        )
        
        // ... 登录流程
    }
}
```

## 🌐 AASA 文件配置

每个域名都需要自己的 AASA 文件：

### atshelchin.github.io/.well-known/apple-app-site-association
```json
{
  "webcredentials": {
    "apps": ["F9W689P9NE.app.hotlabs.secureenclave"]
  }
}
```

### shelchin2025.github.io/.well-known/apple-app-site-association
```json
{
  "webcredentials": {
    "apps": ["F9W689P9NE.app.hotlabs.secureenclave"]
  }
}
```

## 🎨 UI 设计建议

### 域名选择器
```swift
struct PasskeysDomainSelector: View {
    @Binding var selectedDomain: SupportedDomain
    
    var body: some View {
        VStack {
            Text("选择域名")
                .font(.headline)
            
            Picker("Domain", selection: $selectedDomain) {
                ForEach(SupportedDomain.allCases, id: \.self) { domain in
                    Text(domain.displayName).tag(domain)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            Text("当前 RP ID: \(selectedDomain.rawValue)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
```

### 分组显示 Passkeys
```swift
struct GroupedPasskeysView: View {
    @Query private var allPasskeys: [KeychainItem]
    
    var passkeysGroupedByDomain: [String: [KeychainItem]] {
        Dictionary(grouping: allPasskeys.filter { $0.keyType == .passkey }) { 
            $0.relyingParty ?? "Unknown"
        }
    }
    
    var body: some View {
        List {
            ForEach(passkeysGroupedByDomain.keys.sorted(), id: \.self) { domain in
                Section(header: Text(domain)) {
                    ForEach(passkeysGroupedByDomain[domain] ?? []) { passkey in
                        PasskeyRow(item: passkey)
                    }
                }
            }
        }
    }
}
```

## ⚠️ 注意事项

### 1. 独立管理
- 每个 RP ID 的 Passkey 需要**独立创建和管理**
- 不能跨域名使用

### 2. 用户体验
- 清楚地向用户展示当前使用的域名
- 分组显示不同域名的 Passkey
- 提供域名切换功能

### 3. 安全考虑
- 每个域名必须有正确的 AASA 文件
- Team ID 必须匹配
- Associated Domains 必须包含所有域名

## 🔄 实际使用场景

### 场景 1：多环境支持
```swift
enum Environment {
    case production  // example.com
    case staging     // staging.example.com
    case development // dev.example.com
    
    var rpID: String {
        switch self {
        case .production: return "example.com"
        case .staging: return "staging.example.com"
        case .development: return "dev.example.com"
        }
    }
}
```

### 场景 2：多品牌应用
```swift
enum Brand {
    case brandA  // brand-a.com
    case brandB  // brand-b.com
    
    var rpID: String {
        switch self {
        case .brandA: return "brand-a.com"
        case .brandB: return "brand-b.com"
        }
    }
}
```

## 📊 管理策略

| 策略 | 优点 | 缺点 |
|------|------|------|
| 单一 RP ID | 简单，用户只需创建一次 | 限制于一个域名 |
| 多个 RP ID | 支持多个独立服务 | 用户需要多次创建 |
| 主域名 + 子域名 | 一个 Passkey 覆盖多个子域 | 需要控制主域名 |

## 🚀 最佳实践

1. **明确告知用户**
   - 显示当前使用的域名
   - 解释为什么需要为不同域名创建 Passkey

2. **提供迁移功能**
   - 如果更换域名，提供迁移指导
   - 保留旧域名的 Passkey 一段时间

3. **统一管理**
   - 使用 SwiftData 统一存储所有域名的 Passkey 信息
   - 提供统一的管理界面

## 💡 示例：当前应用支持多个 RP ID

```swift
// 修改 PasskeysManager 支持多域名
class PasskeysManager: NSObject, ObservableObject {
    // 当前支持的域名
    let supportedDomains = [
        "atshelchin.github.io",
        "shelchin2025.github.io"  // 可以添加更多
    ]
    
    @Published var currentRPID = "atshelchin.github.io"
    
    func createPasskey(username: String, rpID: String? = nil) {
        let selectedRPID = rpID ?? currentRPID
        
        // 验证是否是支持的域名
        guard supportedDomains.contains(selectedRPID) else {
            log("❌ Unsupported RP ID: \(selectedRPID)")
            return
        }
        
        let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(
            relyingPartyIdentifier: selectedRPID
        )
        
        // ... 继续创建流程
    }
}
```

## 📝 总结

- ✅ 可以支持多个 RP ID
- ✅ 每个 RP ID 独立管理
- ✅ 需要为每个域名配置 AASA
- ✅ Associated Domains 包含所有域名
- ⚠️ 用户需要为每个域名分别创建 Passkey