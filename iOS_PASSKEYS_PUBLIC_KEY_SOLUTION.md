# iOS Passkeys 公钥获取解决方案

## 问题
iOS Passkeys **不支持 attestation**，因此无法在创建时获取公钥。这是 Apple 的设计决定，与 WebAuthn 标准实现不同。

错误信息：
```
Error Code: 1004
Error Description: Passkeys do not support attestation.
```

## 原因
1. Apple 的 Passkeys 实现不提供 `rawAttestationObject`
2. 设置 `attestationPreference` 为任何非 `.none` 的值都会导致错误 1004
3. 这是出于隐私保护的设计考虑

## 解决方案

### 方案 1：服务器端注册流程（推荐）
在实际应用中，公钥应该在服务器端处理：

1. **创建 Passkey 时**：
   - iOS 创建 Passkey 并保存私钥到 iCloud Keychain
   - 将 credential ID 发送到服务器
   
2. **首次认证时**：
   - 服务器发送 challenge
   - iOS 使用 Passkey 签名
   - 服务器从签名响应中提取公钥（如果使用适当的协议）

### 方案 2：使用 Secure Enclave 替代
如果需要在客户端访问公钥，使用 Secure Enclave：

```swift
// Secure Enclave 可以提供公钥
let publicKey = SecKeyCopyPublicKey(privateKey)
let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, nil)
```

### 方案 3：混合方案
1. 使用 Secure Enclave 生成密钥对（可获取公钥）
2. 使用 Passkeys 进行用户认证（更好的用户体验）
3. 结合两者的优势

## iOS Passkeys 的限制

| 功能 | Passkeys | Secure Enclave |
|-----|----------|----------------|
| 公钥访问 | ❌ 不支持 | ✅ 支持 |
| iCloud 同步 | ✅ 自动 | ❌ 不支持 |
| 用户体验 | ✅ 最佳 | ⚠️ 需要自定义 UI |
| WebAuthn 兼容 | ✅ 完全兼容 | ❌ 需要适配 |
| Attestation | ❌ 不支持 | ✅ 支持 |

## 代码示例

### 创建 Passkey（无公钥）
```swift
registrationRequest.attestationPreference = .none // 必须为 .none
// 创建后只能获得 credential ID，无法获得公钥
```

### 签名验证（服务器端）
```javascript
// 服务器端使用 WebAuthn 库
const verification = await verifyAuthenticationResponse({
  response: authenticationResponse,
  // 服务器存储的公钥（从首次认证获得）
  authenticator: storedAuthenticator,
  expectedChallenge: challenge,
});
```

## 结论
iOS Passkeys 的设计理念是：
- **客户端**：只负责创建和使用 Passkey
- **服务器**：负责管理公钥和验证签名
- **公钥**：不应该在客户端存储或传输

如果必须在客户端获取公钥，应该使用 Secure Enclave 而不是 Passkeys。