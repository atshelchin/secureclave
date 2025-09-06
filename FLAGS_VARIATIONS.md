# WebAuthn Flags 变化情况

## Flags 不是固定的！

Flags 会根据以下因素动态变化：

## 1. 创建 vs 签名

### 创建 Passkey 时
```
Flags: 0x5D (二进制: 01011101)
- UP = 1 ✅ 用户在场
- UV = 1 ✅ 用户验证
- BE = 1 ✅ 可备份
- BS = 1 ✅ 已备份
- AT = 1 ✅ 包含凭证数据（公钥等）
- ED = 0 ❌ 无扩展
```

### 使用 Passkey 签名时
```
Flags: 0x1D (二进制: 00011101)
- UP = 1 ✅ 用户在场
- UV = 1 ✅ 用户验证
- BE = 1 ✅ 可备份
- BS = 1 ✅ 已备份
- AT = 0 ❌ 不包含凭证数据
- ED = 0 ❌ 无扩展
```

## 2. 不同的验证方式

### Face ID/Touch ID 验证
```
Flags: 0x1D
- UV = 1 ✅ 用户已验证
```

### 仅设备密码验证
```
Flags: 0x19
- UV = 0 ❌ 未进行生物识别验证
```

### 无验证（某些情况）
```
Flags: 0x01
- UP = 1 ✅ 用户在场
- UV = 0 ❌ 未验证
```

## 3. 备份状态变化

### 新创建，未备份
```
Flags: 0x05
- BE = 0 ❌ 不可备份
- BS = 0 ❌ 未备份
```

### 可备份但未同步
```
Flags: 0x0D
- BE = 1 ✅ 可备份
- BS = 0 ❌ 尚未备份
```

### 已同步到 iCloud
```
Flags: 0x1D
- BE = 1 ✅ 可备份
- BS = 1 ✅ 已备份
```

## 4. 不同平台的差异

### iOS Passkeys（典型）
```
Flags: 0x1D
- 总是要求用户验证
- 支持 iCloud 同步
- Counter 总是 0
```

### Android Passkeys
```
Flags: 0x05 或 0x1D
- 可能不要求用户验证
- 可能使用递增 counter
```

### 硬件密钥（YubiKey）
```
Flags: 0x01
- 可能只要求用户在场（触摸）
- 不支持备份（BE=0, BS=0）
- Counter 递增
```

## 5. 应用配置影响

### 要求用户验证
```javascript
// iOS 配置
registrationRequest.userVerificationPreference = .required
// 结果: UV flag = 1
```

### 不要求用户验证
```javascript
registrationRequest.userVerificationPreference = .discouraged
// 结果: UV flag 可能 = 0
```

## 6. 实际例子对比

```javascript
// 创建时的 authenticatorData (152 字节)
"b2c0ba7bb038330daf4347f16babea5dfb15ed8f9f451fc96328e1760b3786885d00000000..."
//                                                                    ^^ 0x5D (AT=1)

// 签名时的 authenticatorData (37 字节)
"b2c0ba7bb038330daf4347f16babea5dfb15ed8f9f451fc96328e1760b3786881d00000000"
//                                                                    ^^ 0x1D (AT=0)
```

## 7. 服务器端验证考虑

```javascript
function verifyFlags(flags, requirements) {
    // 必须检查的
    if (requirements.userVerification === 'required') {
        if (!(flags & 0x04)) {
            throw new Error('User verification required but not performed')
        }
    }
    
    // 可选检查
    if (requirements.userPresence) {
        if (!(flags & 0x01)) {
            throw new Error('User presence required but not detected')
        }
    }
    
    // 警告性检查
    if (!(flags & 0x08)) {
        console.warn('Credential not backup eligible')
    }
}
```

## 8. 典型 Flags 值

| 值 | 二进制 | 场景 |
|----|--------|------|
| 0x01 | 00000001 | 仅用户在场 |
| 0x05 | 00000101 | 用户在场+验证 |
| 0x1D | 00011101 | iOS 签名（典型）|
| 0x5D | 01011101 | iOS 创建（含凭证）|
| 0x45 | 01000101 | 包含凭证但无备份 |
| 0xDD | 11011101 | 包含扩展数据 |

## 总结

Flags **不是固定的**，它们反映了：
1. 操作类型（创建 vs 签名）
2. 用户验证方式
3. 设备能力
4. 应用配置
5. 平台特性

iOS Passkeys 的典型模式：
- 创建时：`0x5D`
- 签名时：`0x1D`

但这些值会根据具体情况变化！