# 🔐 Passkey vs Secure Enclave 签名差异

## ❌ 问题：Passkey 签名无法通过 P256.verify() 验证

```javascript
// ❌ Passkey 签名验证失败
const verified_passkeys = P256.verify({
    hash: true,
    publicKey: PublicKey.fromHex(publicKey_passkeys),
    payload: Hex.fromString(payload_passkeys),
    signature: Signature.fromDerHex(signature_passkeys),
})

// ✅ Secure Enclave 签名验证成功
const verified_secureenclave = P256.verify({
    hash: true,
    publicKey: PublicKey.fromHex(publicKey_secureenclave),
    payload: Hex.fromString(payload_secureenclave),
    signature: Signature.fromDerHex(signature_secureenclave),
})
```

## 🔍 原因分析

### 1. Secure Enclave 签名（标准 ECDSA）
- **直接签名**：对消息的 SHA256 哈希进行签名
- **格式**：标准 ECDSA (P-256) DER 格式
- **验证**：可以直接使用 P256.verify()

```
签名数据 = SHA256(message)
签名 = ECDSA_Sign(私钥, 签名数据)
```

### 2. Passkey/WebAuthn 签名（复杂格式）
- **不是直接签名**：签名的是 WebAuthn 特定数据结构
- **实际签名内容**：`authenticatorData || SHA256(clientDataJSON)`
- **格式**：WebAuthn 格式，包含额外元数据

```
clientData = {
    type: "webauthn.get",
    challenge: Base64URL(challenge),
    origin: "https://example.com",
    ...
}
签名数据 = authenticatorData || SHA256(clientDataJSON)
签名 = ECDSA_Sign(私钥, 签名数据)
```

## 📊 数据结构对比

### Secure Enclave
```
输入: "Hello World"
↓
SHA256: 0x1234...abcd (32 bytes)
↓
签名: 0x3045... (DER, ~70 bytes)
```

### Passkey/WebAuthn
```
输入: "Hello World" (作为 challenge)
↓
clientDataJSON: {
    "type": "webauthn.get",
    "challenge": "SGVsbG8gV29ybGQ",  // Base64URL
    "origin": "https://atshelchin.github.io",
    "crossOrigin": false
}
↓
authenticatorData: 0x49960de5... (37+ bytes)
包含:
  - RP ID hash (32 bytes)
  - Flags (1 byte)
  - Counter (4 bytes)
  
↓
签名数据: authenticatorData || SHA256(clientDataJSON)
↓
签名: 0x3046... (DER, ~70 bytes)
```

## 🛠 解决方案

### 方案 1：在客户端重构验证数据（推荐）

```javascript
import { P256, Hex, PublicKey, Signature, SHA256 } from 'ox'

// 解析 WebAuthn 响应
const authenticatorData = Hex.fromHex(authenticatorData_hex)
const clientDataJSON = JSON.parse(clientDataJSON_string)
const clientDataHash = SHA256.hash(clientDataJSON_string)

// 重构 WebAuthn 签名的实际数据
const signedData = Hex.concat([authenticatorData, clientDataHash])

// 验证（不使用 hash:true，因为数据已经是哈希后的）
const verified = P256.verify({
    hash: false,  // 重要！数据已经包含哈希
    publicKey: PublicKey.fromCOSE(publicKey_cose), // 注意：需要 COSE 格式
    payload: signedData,
    signature: Signature.fromDerHex(signature_webauthn),
})
```

### 方案 2：在服务端使用 WebAuthn 库

```javascript
// 使用专门的 WebAuthn 库
import { verifyAuthenticationResponse } from '@simplewebauthn/server'

const verification = await verifyAuthenticationResponse({
    response: authenticationResponse,
    expectedChallenge: challenge,
    expectedOrigin: origin,
    expectedRPID: rpID,
    authenticator: {
        credentialPublicKey: publicKey,
        credentialID: credentialID,
        counter: 0
    }
})
```

### 方案 3：使用 Secure Enclave 替代 Passkey 签名

如果需要标准 ECDSA 签名验证，建议：
- **认证**：使用 Passkey（用户体验好）
- **签名**：使用 Secure Enclave（标准格式）

## 📝 iOS 实现建议

```swift
// Passkey - 用于认证
func authenticateWithPasskey() {
    // WebAuthn 流程，用于用户身份验证
}

// Secure Enclave - 用于签名
func signWithSecureEnclave(message: String) -> Data {
    // 标准 ECDSA 签名，可用 P256.verify() 验证
}
```

## ⚠️ 重要提示

1. **Passkey 公钥格式**：通常是 COSE 格式，不是标准 X.509 格式
2. **Challenge 编码**：WebAuthn 使用 Base64URL，不是 Base64
3. **Origin 验证**：WebAuthn 包含 origin 验证，需要匹配
4. **计数器**：WebAuthn 包含防重放计数器

## 🔧 调试技巧

在 iOS 端记录完整数据：
```swift
log("Authenticator Data: \(authenticatorData.hexString)")
log("Client Data JSON: \(clientDataJSON)")
log("Client Data Hash: \(SHA256(clientDataJSON).hexString)")
log("Signed Data: \(authenticatorData + clientDataHash)")
log("Signature: \(signature.hexString)")
```

## 📚 参考资料

- [WebAuthn Spec](https://www.w3.org/TR/webauthn/)
- [FIDO2 CTAP](https://fidoalliance.org/specs/fido-v2.0-ps-20190130/fido-client-to-authenticator-protocol-v2.0-ps-20190130.html)
- [Apple AuthenticationServices](https://developer.apple.com/documentation/authenticationservices)