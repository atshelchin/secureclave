# 以太坊智能钱包双密钥安全模型分析

## 系统架构理解

```
┌─────────────────────────────────────┐
│      以太坊智能合约钱包              │
├─────────────────────────────────────┤
│  控制密钥：                          │
│  1. Secure Enclave (主密钥)          │
│     - ✅ 签名交易                    │
│     - ✅ 立即重置 Passkeys           │
│  2. Passkeys (恢复密钥)              │
│     - ❌ 不能签名交易                │
│     - ⏱️ 30天后可重置 Secure Enclave │
└─────────────────────────────────────┘
```

## 1. 正常使用流程

### 日常交易
```
用户 → Secure Enclave 签名 → 交易执行
      (Face ID/Touch ID)
```

### Passkeys 丢失/被盗
```
用户 → Secure Enclave → 立即重置 Passkeys → 安全
      (还有设备)
```

## 2. 攻击场景分析

### 场景 A：iCloud 被盗（Passkeys 泄露）
```
攻击者获得 Passkeys
    ↓
发起 Secure Enclave 重置请求
    ↓
⏱️ 30天等待期开始
    ↓
原用户收到通知
    ↓
原用户使用 Secure Enclave 取消重置 ✅
    ↓
攻击失败，立即重置 Passkeys
```

**结果**：
- ✅ 攻击者无法立即控制钱包
- ✅ 30天窗口给用户充足反应时间
- ✅ 用户可立即阻止攻击并重置 Passkeys

### 场景 B：设备丢失（Secure Enclave 不可用）
```
用户设备丢失/损坏
    ↓
无法使用 Secure Enclave
    ↓
使用 Passkeys 发起重置
    ↓
⏱️ 等待30天
    ↓
新设备上重新设置 Secure Enclave
    ↓
恢复钱包控制权
```

**结果**：
- ⏱️ 需要等待30天
- ✅ 最终可以恢复
- ❌ 期间无法进行交易

### 场景 C：双重丢失
```
情况1: iCloud被盗 + 设备丢失
    ↓
攻击者发起重置（30天）
用户无法取消（无设备）
    ↓
30天后攻击者获得控制 ❌

情况2: Passkeys被删除 + 设备丢失
    ↓
无法重置 Secure Enclave
    ↓
永久失去控制 ❌
```

## 3. 安全模型评估

### 优点
1. **双重保护**：需要两个密钥同时失效才会完全失去控制
2. **时间缓冲**：30天给予充足的反应时间
3. **权限分离**：交易权限和恢复权限分离
4. **防快速攻击**：即使 Passkeys 被盗也不能立即转移资产

### 漏洞分析

#### 漏洞1：恶意删除攻击
```
攻击者控制 iCloud
    ↓
删除所有 Passkeys
    ↓
用户设备丢失/损坏
    ↓
无法恢复 ❌
```

**严重性**：🔴 高
**影响**：永久失去钱包控制

#### 漏洞2：长期潜伏攻击
```
攻击者控制 iCloud
    ↓
悄悄发起重置请求
    ↓
用户30天内未察觉
    ↓
攻击者获得控制 ❌
```

**严重性**：🟡 中
**影响**：需要用户定期检查

#### 漏洞3：社会工程攻击
```
攻击者诱导用户：
"您的账户有异常，请确认这不是您的重置请求"
    ↓
用户误以为是安全检查
    ↓
没有取消重置
    ↓
30天后失去控制 ❌
```

## 4. 改进建议

### 建议1：多重 Passkeys 备份
```solidity
contract SmartWallet {
    mapping(address => bool) passkeys;
    uint constant PASSKEY_THRESHOLD = 2; // 需要2/3确认
    
    function initiateRecovery() {
        require(getPasskeyConfirmations() >= PASSKEY_THRESHOLD);
        startRecoveryTimer();
    }
}
```

### 建议2：分级时间锁
```solidity
enum RecoverySpeed {
    EMERGENCY,  // 7天 - 需要3/5 passkeys
    STANDARD,   // 30天 - 需要1/3 passkeys
    SAFE        // 90天 - 单个passkey
}
```

### 建议3：监护人机制
```solidity
contract SmartWallet {
    address[] guardians; // 信任的地址
    
    function emergencyFreeze() external {
        require(isGuardian(msg.sender));
        frozen = true;
        // 冻结所有操作，需要多签解冻
    }
}
```

### 建议4：通知机制增强
```javascript
// 多渠道通知
function notifyRecoveryInitiated() {
    // 1. 链上事件
    emit RecoveryInitiated(timestamp, initiator);
    
    // 2. 推送通知到所有设备
    pushNotification("Recovery initiated - 30 days countdown");
    
    // 3. Email通知（如果设置）
    sendEmail("Security Alert: Recovery Process Started");
    
    // 4. 链上留言（其他钱包可见）
    broadcastWarning();
}
```

### 建议5：硬件钱包集成
```
三重保护：
1. Secure Enclave - 日常签名
2. Passkeys - 恢复密钥（30天）
3. Hardware Wallet - 紧急恢复（7天）
```

## 5. 智能合约实现建议

```solidity
contract SecureSmartWallet {
    // 密钥角色
    enum KeyRole {
        SIGNER,     // Secure Enclave - 可签名
        RECOVERER,  // Passkeys - 可恢复
        GUARDIAN    // 硬件钱包 - 紧急干预
    }
    
    struct Key {
        address pubkey;
        KeyRole role;
        uint256 addedAt;
        bool active;
    }
    
    struct RecoveryRequest {
        address newKey;
        address initiator;
        uint256 executeAfter;
        bool cancelled;
    }
    
    mapping(address => Key) public keys;
    RecoveryRequest public pendingRecovery;
    
    // 交易签名（仅 SIGNER 角色）
    function executeTransaction(
        address to,
        uint256 value,
        bytes calldata data,
        bytes calldata signature
    ) external {
        require(keys[recover(signature)].role == KeyRole.SIGNER);
        // 执行交易
    }
    
    // 发起恢复（RECOVERER 角色）
    function initiateRecovery(address newSignerKey) external {
        require(keys[msg.sender].role == KeyRole.RECOVERER);
        pendingRecovery = RecoveryRequest({
            newKey: newSignerKey,
            initiator: msg.sender,
            executeAfter: block.timestamp + 30 days,
            cancelled: false
        });
        emit RecoveryInitiated(newSignerKey, block.timestamp);
    }
    
    // 取消恢复（SIGNER 角色）
    function cancelRecovery() external {
        require(keys[msg.sender].role == KeyRole.SIGNER);
        pendingRecovery.cancelled = true;
        
        // 立即重置发起恢复的 Passkey
        keys[pendingRecovery.initiator].active = false;
        emit RecoveryCancelled(pendingRecovery.initiator);
    }
    
    // 执行恢复
    function executeRecovery() external {
        require(block.timestamp >= pendingRecovery.executeAfter);
        require(!pendingRecovery.cancelled);
        
        // 替换 Secure Enclave 密钥
        // 旧密钥失效，新密钥激活
    }
}
```

## 6. 风险矩阵

| 场景 | 概率 | 影响 | 风险等级 | 缓解措施 |
|------|------|------|----------|----------|
| iCloud 被盗 | 中 | 低 | 🟡 | 30天保护期 + 取消机制 |
| 设备丢失 | 中 | 中 | 🟡 | Passkeys 恢复 |
| Passkeys 被删 + 设备丢失 | 低 | 极高 | 🔴 | 需要额外备份机制 |
| 用户未察觉恢复请求 | 低 | 高 | 🟠 | 强化通知机制 |
| 双重密钥同时泄露 | 极低 | 极高 | 🟡 | 概率极低 |

## 7. 结论

### 当前设计的优势
1. ✅ **时间锁保护**：30天缓冲期防止快速攻击
2. ✅ **权限分离**：签名权和恢复权分离
3. ✅ **双向恢复**：两种密钥可互相恢复

### 主要风险
1. 🔴 **Passkeys 被恶意删除 + 设备丢失 = 永久锁定**
2. 🟠 **通知机制依赖用户主动察觉**
3. 🟡 **30天等待期对合法用户也是负担**

### 核心改进建议
1. **多重备份**：不要只依赖单一 iCloud Passkeys
2. **分级恢复**：根据安全级别设置不同等待期
3. **监护人机制**：可信第三方紧急干预
4. **链上透明**：所有恢复请求公开可查

### 最终建议
这个设计已经相当巧妙，通过**时间不对称性**（立即重置 vs 30天重置）创造了安全缓冲区。但需要解决 **"Passkeys 单点故障"** 问题：

```
理想方案：
- 3个 Passkeys（分布在不同位置）
- 需要 2/3 确认才能发起恢复
- 防止单一 iCloud 被盗导致的风险
```

这样可以在保持原有优雅设计的同时，显著提高安全性。