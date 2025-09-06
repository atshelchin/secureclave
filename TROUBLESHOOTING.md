# 故障排除指南

## 🚨 Passkeys 错误：Database Permission Denied

### 错误信息
```
Attempt to map database failed: permission was denied
Failed to initialize client context with error Error Domain=NSOSStatusErrorDomain Code=-54
ASAuthorizationController credential request failed with error: Code=1004
```

### 原因
这些错误通常由以下原因导致：
1. **在模拟器上运行** - Passkeys在模拟器上功能受限
2. **Entitlements配置问题**
3. **签名配置不正确**
4. **Associated Domains未正确配置**

### ✅ 解决方案

#### 1. 使用真机测试（推荐）
Passkeys功能在真机上工作最佳：
- 连接iPhone或iPad
- 确保设备iOS 16+
- 设置Face ID或Touch ID

#### 2. 检查Xcode配置
1. 打开项目设置
2. 选择Target → Signing & Capabilities
3. 确保：
   - Team: `Qin Xie (Personal Team)` 
   - Bundle ID: `app.hotlabs.secureenclave`
   - Automatically manage signing: ✅ 启用

#### 3. 验证Associated Domains
确保GitHub Pages已部署配置文件：
```bash
curl https://atshelchin.github.io/.well-known/apple-app-site-association
```

应返回：
```json
{
  "webcredentials": {
    "apps": ["9RS8E64FWL.app.hotlabs.secureenclave"]
  }
}
```

#### 4. 清理并重建
```bash
# 1. 清理DerivedData
rm -rf ~/Library/Developer/Xcode/DerivedData/secureenclave-*

# 2. 清理项目
xcodebuild clean -scheme secureenclave

# 3. 重新构建
# 在Xcode中选择你的设备并运行
```

## 🔍 其他常见问题

### Error Code 1004
**含义**：没有找到可用的Passkey凭据

**解决**：
1. 这是正常的 - 第一次使用时没有凭据
2. 先点击"Create Passkey"创建凭据
3. 然后才能使用"Sign In with Passkey"

### SwiftData/CloudKit错误
**错误**：`Could not create ModelContainer`

**已修复**：
- ✅ 所有属性添加了默认值
- ✅ 关系添加了反向引用
- ✅ 使用fallback机制（iCloud失败时使用本地存储）

### Secure Enclave不可用
**在模拟器上**：
- 这是正常的 - Secure Enclave只在真机上可用
- 使用真机测试此功能

## 📱 设备兼容性

| 功能 | 模拟器 | 真机 |
|------|---------|------|
| 基本UI | ✅ | ✅ |
| iCloud同步 | ⚠️ 受限 | ✅ |
| Secure Enclave | ❌ | ✅ |
| Passkeys创建 | ⚠️ 可能失败 | ✅ |
| Passkeys登录 | ⚠️ 可能失败 | ✅ |
| 生物识别 | ❌ | ✅ |

## 🛠️ 调试技巧

### 1. 查看详细日志
在Xcode控制台查看：
- SwiftData初始化消息
- Passkey操作日志
- 错误详情

### 2. 验证配置
```bash
# 检查Team ID
security find-identity -v -p codesigning | grep "Apple Development"

# 检查Bundle ID
grep PRODUCT_BUNDLE_IDENTIFIER *.xcodeproj/project.pbxproj
```

### 3. 测试网络连接
Passkeys首次使用需要验证域名：
```bash
# 测试域名可达性
ping atshelchin.github.io

# 验证HTTPS
curl -I https://atshelchin.github.io/.well-known/apple-app-site-association
```

## 📝 检查清单

运行应用前确保：
- [ ] 使用真机（推荐）或iOS 16+模拟器
- [ ] Xcode已选择正确的Team
- [ ] Bundle ID正确：`app.hotlabs.secureenclave`
- [ ] apple-app-site-association已部署
- [ ] 设备已设置Face ID/Touch ID（真机）
- [ ] 已连接网络

## 🆘 获取帮助

如果问题持续：
1. 查看Xcode控制台完整错误信息
2. 检查设备系统日志（Console.app）
3. 验证所有配置文件
4. 尝试在不同设备上测试

## 📚 参考资源

- [Apple: Troubleshooting Passkeys](https://developer.apple.com/documentation/authenticationservices/public-private_key_authentication/supporting_passkeys)
- [Associated Domains Troubleshooting](https://developer.apple.com/documentation/xcode/supporting-associated-domains)
- [SwiftData with CloudKit](https://developer.apple.com/documentation/swiftdata/syncing-model-data-across-a-persons-devices)