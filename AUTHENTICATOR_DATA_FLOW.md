# AuthenticatorData 生成流程

## 重要：你不需要（也不能）自己构造 authenticatorData！

## 1. 签名请求流程

```swift
// 你的 iOS 应用代码
func signWithPasskey(message: String) {
    // 1. 你只需要提供 challenge
    let challenge = SHA256.hash(data: message.data(using: .utf8)!)
    
    // 2. 创建签名请求
    let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(
        relyingPartyIdentifier: "atshelchin.github.io"
    )
    let request = provider.createCredentialAssertionRequest(
        challenge: challenge
    )
    
    // 3. 执行请求
    controller.performRequests()
}

// 4. iOS 系统内部处理（你看不到也控制不了）
// iOS 系统会：
//   a. 验证用户身份（Face ID/Touch ID）
//   b. 查找对应的 Passkey 私钥
//   c. 生成 authenticatorData
//   d. 构造 clientDataJSON
//   e. 计算签名
//   f. 返回结果

// 5. 你收到的回调
func didCompleteWithAuthorization(authorization: ASAuthorization) {
    let assertion = authorization.credential as! ASAuthorizationPlatformPublicKeyCredentialAssertion
    
    // 这些都是 iOS 生成并返回的！
    let authenticatorData = assertion.rawAuthenticatorData  // iOS 生成的
    let clientDataJSON = assertion.rawClientDataJSON        // iOS 生成的
    let signature = assertion.signature                      // iOS 生成的
    
    // 你只是获取和使用这些数据，不是创建它们
}
```

## 2. iOS 内部如何生成 authenticatorData

```
iOS 系统内部（黑盒，你无法控制）：
┌─────────────────────────────────────┐
│ 1. 计算 RP ID Hash                  │
│    SHA256("atshelchin.github.io")   │
├─────────────────────────────────────┤
│ 2. 设置 Flags                       │
│    - 检测用户是否在场 (UP)           │
│    - 检测是否通过 Face ID (UV)       │
│    - 检查是否已备份到 iCloud (BS)    │
│    - 决定是否包含凭证数据 (AT)       │
├─────────────────────────────────────┤
│ 3. 设置 Counter                     │
│    iOS 总是使用 0x00000000          │
├─────────────────────────────────────┤
│ 4. 组装 authenticatorData           │
│    rpIdHash + flags + counter       │
└─────────────────────────────────────┘
```

## 3. 数据流向

```
你的应用                iOS 系统              返回给你
─────────             ─────────            ─────────
                      
challenge     ───►    生成:                ◄─── authenticatorData
rpId                  - authenticatorData       (系统生成的)
                      - clientDataJSON      
                      - signature           ◄─── clientDataJSON
                                                 (系统生成的)
                      使用私钥签名          
                                           ◄─── signature
                                                 (系统生成的)
```

## 4. 实际代码示例

### iOS 端（你的代码）
```swift
// 你只提供输入
let challenge = generateChallenge()
let rpId = "atshelchin.github.io"

// 请求签名
let request = provider.createCredentialAssertionRequest(
    challenge: challenge
)

// 获取系统返回的结果
func handleResult(assertion: ASAuthorizationPlatformPublicKeyCredentialAssertion) {
    // 这些都是系统给你的，不是你创建的！
    print("系统返回的 authenticatorData: \(assertion.rawAuthenticatorData)")
    print("系统返回的 clientDataJSON: \(assertion.rawClientDataJSON)")
    print("系统返回的 signature: \(assertion.signature)")
    
    // 你的任务：把这些数据发送给服务器验证
    sendToServer([
        "authenticatorData": assertion.rawAuthenticatorData,
        "clientDataJSON": assertion.rawClientDataJSON,
        "signature": assertion.signature
    ])
}
```

### 服务器端（验证）
```javascript
// 服务器收到 iOS 返回的数据
function verifySignature(data) {
    const { authenticatorData, clientDataJSON, signature } = data
    
    // 重构签名数据（iOS 签名的内容）
    const clientDataHash = SHA256(clientDataJSON)
    const signedData = authenticatorData + clientDataHash
    
    // 验证签名
    return verify(publicKey, signature, signedData)
}
```

## 5. 你能控制什么 vs 不能控制什么

### ✅ 你能控制的：
- Challenge 的内容
- RP ID（域名）
- 用户验证偏好（preferred/required/discouraged）
- 何时发起签名请求

### ❌ 你不能控制的（iOS 系统决定）：
- authenticatorData 的具体内容
- Flags 的值（系统根据实际情况设置）
- Counter 的值（iOS 总是 0）
- 签名算法和过程
- clientDataJSON 的生成
- 私钥的访问和使用

## 6. 为什么这样设计？

1. **安全性**：私钥永远不会暴露给应用
2. **一致性**：确保所有应用使用相同的标准
3. **隐私**：应用无法跟踪用户（如 counter 总是 0）
4. **简单性**：开发者不需要理解复杂的加密细节

## 总结

```
你的角色：提供 challenge → 获取结果 → 发送验证
iOS 角色：生成所有 WebAuthn 数据 → 执行签名 → 返回结果
```

**记住**：`authenticatorData` 是 iOS 系统生成的，不是你构造的！你只是：
1. 发起请求
2. 接收结果
3. 使用结果（发送给服务器验证）