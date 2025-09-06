# Passkeys vs Secure Enclave 安全模型分析

## 核心问题：账户恢复与安全性的平衡

您提出了一个关键的安全悖论：
- **Passkeys**：方便但可能被盗用
- **Secure Enclave**：安全但可能永久丢失

## 1. 攻击场景分析

### 场景 A：iCloud 账户被盗
```
攻击者获得 iCloud 访问 → 可以在新设备使用 Passkeys
                    ↓
              用户失去账户控制
                    ↓
         即使有原设备也无法阻止
```

**影响**：
- ✅ Passkeys 可在攻击者设备上使用
- ❌ Secure Enclave 密钥无法被攻击者获取
- ⚠️ 但攻击者可能删除 iCloud 中的 Secure Enclave 恢复信息

### 场景 B：设备丢失 + App 被删除
```
用户设备丢失 → Secure Enclave 密钥无法恢复
           ↓
    需要等待 30 天冷却期
           ↓
    期间账户完全无法访问
```

**影响**：
- ❌ Secure Enclave 密钥永久丢失
- ✅ Passkeys 可通过 iCloud 在新设备恢复
- ⚠️ 30 天窗口期存在风险

### 场景 C：恶意删除攻击
```
攻击者获得 iCloud → 删除 Passkeys
              ↓
        删除 App/恢复信息
              ↓
     用户永久失去账户访问权
```

## 2. 产品逻辑漏洞分析

### 漏洞 1：单点故障
```
iCloud 被盗 = 全部 Passkeys 被盗
设备丢失 = 全部 Secure Enclave 密钥丢失
```

### 漏洞 2：恢复机制不对等
| 方案 | 便利性 | 安全性 | 恢复能力 | 风险 |
|------|--------|--------|----------|------|
| Passkeys | ⭐⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐⭐ | iCloud 被盗 |
| Secure Enclave | ⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐ | 永久丢失 |

### 漏洞 3：删除保护不足
- Passkeys 可被远程删除（通过 iCloud）
- Secure Enclave 无云端备份
- 没有"删除保护"或"回收站"机制

## 3. 改进方案

### 方案 A：混合模型
```
账户 = Passkey (日常) + Secure Enclave (高权限)
```

**实现**：
```swift
// 分级权限系统
enum OperationLevel {
    case daily      // 使用 Passkey
    case sensitive  // 需要 Secure Enclave
    case critical   // 需要多重验证
}

// 日常操作：Passkey
func dailyOperation() {
    // 登录、查看、普通交易
    authenticateWithPasskey()
}

// 敏感操作：Secure Enclave
func sensitiveOperation() {
    // 大额转账、修改密码、删除账户
    authenticateWithSecureEnclave()
}

// 关键操作：多重验证
func criticalOperation() {
    // 需要 Passkey + Secure Enclave + 时间锁
    authenticateWithBoth()
    waitForTimeLock(hours: 24)
}
```

### 方案 B：社交恢复
```
恢复密钥 = 分片存储在信任的联系人
```

**实现**：
```swift
// Shamir's Secret Sharing
func setupSocialRecovery() {
    let secret = generateRecoveryKey()
    let shares = splitSecret(secret, threshold: 3, total: 5)
    
    // 分发给 5 个信任联系人
    // 需要任意 3 个才能恢复
    distributeShares(shares)
}
```

### 方案 C：时间锁保护
```
删除/重置 → 通知所有设备 → 48小时等待期 → 可撤销
```

**实现**：
```swift
func requestDeletion() {
    // 1. 创建删除请求
    let request = DeletionRequest(timestamp: Date())
    
    // 2. 通知所有设备
    notifyAllDevices(request)
    
    // 3. 等待期（可撤销）
    scheduleExecution(after: .hours(48)) {
        if !request.isCancelled {
            executeDelete()
        }
    }
}
```

### 方案 D：硬件备份密钥
```
生成离线恢复码 → 打印/存储在保险箱
```

**实现**：
```swift
func generateOfflineRecovery() -> String {
    // 生成恢复种子
    let seed = generateSecureRandom(bytes: 32)
    
    // 编码为助记词
    let mnemonic = encodeMnemonic(seed) // 24 words
    
    // 可以重建所有密钥
    return mnemonic
}
```

## 4. 最佳实践建议

### 4.1 分层安全模型
```
Level 1: 日常访问
├── Passkeys (iCloud 同步)
└── 便利性优先

Level 2: 资金操作
├── Secure Enclave
└── 需要设备在手

Level 3: 账户恢复
├── 社交恢复 (3/5 门限)
├── 硬件密钥备份
└── 时间锁保护
```

### 4.2 防删除机制
```swift
struct AccountProtection {
    // 1. 删除需要多重确认
    let deletionRequiresMultiAuth = true
    
    // 2. 删除有冷却期
    let deletionCooldown = TimeInterval(48 * 3600)
    
    // 3. 删除通知所有设备
    let notifyAllDevices = true
    
    // 4. 保留恢复窗口
    let recoveryWindow = TimeInterval(30 * 24 * 3600)
}
```

### 4.3 定期安全审计
```swift
func performSecurityAudit() {
    // 每月检查
    checkActiveDevices()
    checkRecentAuthentications()
    checkRecoveryMethods()
    
    // 异常告警
    if detectAnomalous() {
        requireReauthentication()
        notifyUser()
    }
}
```

## 5. 技术实现建议

### 5.1 多重签名方案
```swift
// 需要 N 个密钥中的 M 个
struct MultiSigAccount {
    let passkey: Passkey
    let secureEnclaveKey: SecureEnclaveKey
    let hardwareKey: HardwareKey?
    let socialRecoveryKeys: [SocialKey]
    
    func authorize(operation: Operation) -> Bool {
        let required = operation.requiredSignatures
        let signatures = collectSignatures()
        return signatures.count >= required
    }
}
```

### 5.2 分级权限矩阵
| 操作 | Passkey | Secure Enclave | 硬件密钥 | 时间锁 |
|------|---------|----------------|----------|--------|
| 登录 | ✅ | ❌ | ❌ | ❌ |
| 查看 | ✅ | ❌ | ❌ | ❌ |
| 小额交易 | ✅ | ❌ | ❌ | ❌ |
| 大额交易 | ✅ | ✅ | ❌ | ❌ |
| 修改密码 | ✅ | ✅ | ❌ | ✅ |
| 账户恢复 | ❌ | ❌ | ✅ | ✅ |
| 删除账户 | ✅ | ✅ | ✅ | ✅ |

### 5.3 审计日志
```swift
struct SecurityEvent {
    let timestamp: Date
    let eventType: EventType
    let device: DeviceInfo
    let location: Location?
    let success: Bool
    
    enum EventType {
        case login
        case passwordChange
        case deviceAdded
        case recoveryAttempt
        case deletion
    }
}

// 所有安全事件必须记录
// 用户可以查看和接收通知
```

## 6. 结论

### 现有方案的问题
1. **过度依赖单一机制**：要么全部 Passkeys，要么全部 Secure Enclave
2. **恢复机制不完善**：没有考虑各种边缘情况
3. **缺乏分级保护**：所有操作使用相同的安全级别

### 推荐的解决方案
1. **混合模型**：Passkeys 用于日常，Secure Enclave 用于敏感操作
2. **多重恢复**：社交恢复 + 硬件备份 + 时间锁
3. **分级权限**：根据操作敏感度要求不同的认证
4. **审计追踪**：完整的日志和异常检测

### 核心原则
> "安全性和便利性不是二选一，而是要在不同场景下找到适当的平衡点。"

- **日常操作**：便利性优先（Passkeys）
- **敏感操作**：安全性优先（Secure Enclave）
- **账户恢复**：多重保障（避免单点故障）
- **防御删除**：时间窗口 + 多设备通知

## 7. 实施建议

### Phase 1：基础保护
- 实现 Passkeys + Secure Enclave 双轨制
- 添加删除保护（48小时冷却期）

### Phase 2：恢复机制
- 实现社交恢复（3/5 门限）
- 生成离线恢复码

### Phase 3：高级功能
- 分级权限系统
- 异常检测和告警
- 完整审计日志

这样的设计可以最大程度避免：
- iCloud 被盗导致的账户接管
- 设备丢失导致的永久锁定
- 恶意删除导致的不可恢复

同时保持了良好的用户体验和安全性平衡。