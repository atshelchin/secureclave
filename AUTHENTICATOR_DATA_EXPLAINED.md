# AuthenticatorData 详解

## 什么是 AuthenticatorData？

`authenticatorData` 是 WebAuthn 协议中的核心数据结构，由认证器（如 iOS Passkeys）在每次签名时生成。它包含了关于认证器状态和用户验证的信息。

## 数据结构（37 字节最小）

```
+------------------+----------+----------+-------------------+
| RP ID Hash       | Flags    | Counter  | Extensions (可选)  |
| (32 bytes)       | (1 byte) | (4 bytes)| (variable)        |
+------------------+----------+----------+-------------------+
```

## 详细分解

以你的数据为例：
```
0xb2c0ba7bb038330daf4347f16babea5dfb15ed8f9f451fc96328e1760b3786881d00000000
```

### 1. RP ID Hash (32 字节)
```
b2c0ba7bb038330daf4347f16babea5dfb15ed8f9f451fc96328e1760b378688
```
- **含义**：Relying Party ID 的 SHA-256 哈希
- **生成方式**：`SHA256("atshelchin.github.io")`
- **用途**：确保签名是为正确的网站生成的

### 2. Flags (1 字节)
```
1d (二进制: 00011101)
```

| Bit | 值 | 标志 | 含义 |
|-----|---|------|-----|
| 0 | 1 | UP | User Present - 用户在场 |
| 1 | 0 | RFU1 | 保留 |
| 2 | 1 | UV | User Verified - 用户已验证（Face ID/Touch ID）|
| 3 | 1 | BE | Backup Eligible - 可备份 |
| 4 | 1 | BS | Backup State - 已备份 |
| 5 | 0 | RFU2 | 保留 |
| 6 | 0 | AT | Attested Credential Data - 无凭证数据 |
| 7 | 0 | ED | Extension Data - 无扩展数据 |

### 3. Counter (4 字节)
```
00000000
```
- **含义**：签名计数器
- **用途**：防止重放攻击
- **注意**：iOS Passkeys 通常不递增计数器（隐私考虑）

## 生成过程

### 在 iOS 中（签名时）

```swift
// 1. 用户请求签名
func signWithPasskey(challenge: Data) {
    // 2. iOS 构造 authenticatorData
    let rpIdHash = SHA256.hash(data: "atshelchin.github.io".data(using: .utf8)!)
    
    // 3. 设置 flags
    var flags: UInt8 = 0
    flags |= 0x01  // UP - 用户在场
    if userDidBiometric {
        flags |= 0x04  // UV - 用户验证
    }
    if isBackupEligible {
        flags |= 0x08  // BE - 可备份
    }
    if isBackedUp {
        flags |= 0x10  // BS - 已备份
    }
    
    // 4. 构造 authenticatorData
    var authenticatorData = Data()
    authenticatorData.append(rpIdHash)
    authenticatorData.append(flags)
    authenticatorData.append(counter) // 4 bytes, usually 0x00000000
    
    // 5. 返回给应用
    return authenticatorData
}
```

### 在创建 Passkey 时

创建时的 `authenticatorData` 会包含额外的凭证数据：

```
+-------------+-------+---------+------------------+
| RP ID Hash  | Flags | Counter | Credential Data  |
| (32 bytes)  | 0x5d  | 4 bytes | (variable)       |
+-------------+-------+---------+------------------+
                   |
                   +-- AT flag = 1 (有凭证数据)
```

凭证数据包含：
- AAGUID (16 字节) - 认证器标识
- Credential ID Length (2 字节)
- Credential ID (variable)
- Public Key (COSE format)

## 签名时的使用

WebAuthn 签名实际签的是：
```
签名数据 = authenticatorData || SHA256(clientDataJSON)
```

### 完整流程

```javascript
// 1. 客户端请求签名
const assertion = await navigator.credentials.get({
    publicKey: {
        challenge: challenge,
        rpId: "atshelchin.github.io"
    }
});

// 2. iOS 生成 authenticatorData
// - 计算 RP ID hash
// - 设置 flags (UP, UV 等)
// - 添加 counter

// 3. 构造签名数据
const clientDataHash = SHA256(clientDataJSON)
const signedData = authenticatorData + clientDataHash

// 4. 使用私钥签名
const signature = sign(privateKey, signedData)

// 5. 返回结果
return {
    authenticatorData,
    clientDataJSON,
    signature
}
```

## 验证时的使用

```javascript
// 服务器端验证
function verifySignature(publicKey, signature, authenticatorData, clientDataJSON) {
    // 1. 重构签名数据
    const clientDataHash = SHA256(clientDataJSON)
    const signedData = authenticatorData + clientDataHash
    
    // 2. 验证签名
    return verify(publicKey, signature, signedData)
}
```

## 安全性保证

1. **RP ID Hash**：确保签名只能用于特定网站
2. **User Verification Flag**：证明用户进行了生物识别验证
3. **Counter**：防止重放攻击（虽然 iOS 不使用）
4. **签名绑定**：authenticatorData 与 clientDataJSON 一起签名，防止篡改

## iOS Passkeys 的特点

- **隐私优先**：Counter 通常为 0，避免跟踪
- **始终验证**：通常 UV flag 总是设置（Face ID/Touch ID）
- **iCloud 同步**：BE 和 BS flags 通常都设置
- **简化结构**：签名时不包含扩展数据

## 调试技巧

```javascript
// 解析 authenticatorData
function parseAuthenticatorData(hex) {
    const data = Buffer.from(hex.replace('0x', ''), 'hex')
    
    console.log("RP ID Hash:", data.slice(0, 32).toString('hex'))
    console.log("Flags:", data[32].toString(16))
    console.log("Counter:", data.slice(33, 37).toString('hex'))
    
    const flags = data[32]
    console.log("User Present:", (flags & 0x01) !== 0)
    console.log("User Verified:", (flags & 0x04) !== 0)
}
```

这就是 `authenticatorData` 的完整说明！它是 WebAuthn 安全模型的核心部分。