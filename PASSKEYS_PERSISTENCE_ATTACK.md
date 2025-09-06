# Passkeys 持久化攻击分析与防御方案

## 攻击场景

```
时间线：
T0: 攻击者获得 iCloud 访问权
T1: Passkeys 同步到攻击者设备
T2: 用户发现异常，修改 iCloud 密码
T3: 攻击者设备上的 Passkeys 仍然有效 ⚠️
T4: 攻击者可以发起 SC 重置请求
T5: 30天后获得钱包控制权（如果用户未察觉）
```

## 问题根源

### Passkeys 的设计特性
1. **本地存储**：Passkeys 一旦同步到设备，就存储在该设备的 Keychain 中
2. **无远程撤销**：更改 iCloud 密码不会使已同步的 Passkeys 失效
3. **无设备列表**：无法查看 Passkeys 在哪些设备上
4. **无法选择性删除**：不能远程删除特定设备上的 Passkeys

## 防御方案

### 方案 1：版本化 Passkeys（推荐）

```swift
struct VersionedPasskey {
    let version: Int
    let createdAt: Date
    let rpId: String
    
    // 在 iCloud 存储当前版本
    static var currentVersion: Int {
        get { iCloudKeyValue.integer(forKey: "passkey_version") }
        set { 
            iCloudKeyValue.set(newValue, forKey: "passkey_version")
            // 同时记录更新时间
            iCloudKeyValue.set(Date(), forKey: "passkey_version_updated")
        }
    }
}

// 智能合约端
contract SmartWallet {
    uint256 public passkeyVersion = 1;
    mapping(uint256 => address) public passkeysByVersion;
    
    modifier onlyCurrentPasskey() {
        require(
            msg.sender == passkeysByVersion[passkeyVersion],
            "Outdated passkey"
        );
        _;
    }
    
    // SC 可以立即更新 Passkey 版本
    function updatePasskeyVersion(
        uint256 newVersion,
        address newPasskey
    ) external onlySecureEnclave {
        passkeyVersion = newVersion;
        passkeysByVersion[newVersion] = newPasskey;
        emit PasskeyVersionUpdated(newVersion);
    }
    
    // 只接受当前版本的 Passkey 发起重置
    function initiateRecovery() external onlyCurrentPasskey {
        // 30天重置流程
    }
}
```

### 方案 2：设备绑定验证

```swift
class DeviceBoundPasskey {
    // 每个设备生成唯一标识
    var deviceId: String {
        // 使用多个因素生成稳定的设备ID
        let factors = [
            UIDevice.current.identifierForVendor?.uuidString,
            ProcessInfo.processInfo.systemVersion,
            // 硬件特征
        ].compactMap { $0 }
        
        return SHA256(factors.joined())
    }
    
    // 创建 Passkey 时绑定设备
    func createPasskey() {
        let passkey = // ... 创建 Passkey
        
        // 在 iCloud 记录授权设备
        var authorizedDevices = iCloudKeyValue.array(forKey: "authorized_devices") ?? []
        authorizedDevices.append([
            "deviceId": deviceId,
            "deviceName": UIDevice.current.name,
            "authorizedAt": Date(),
            "passkeyId": passkey.credentialID
        ])
        iCloudKeyValue.set(authorizedDevices, forKey: "authorized_devices")
    }
    
    // 使用 Passkey 前检查设备授权
    func usePasskey() throws {
        let authorizedDevices = iCloudKeyValue.array(forKey: "authorized_devices") ?? []
        
        guard authorizedDevices.contains(where: { 
            $0["deviceId"] as? String == deviceId 
        }) else {
            throw PasskeyError.unauthorizedDevice
        }
        
        // 继续使用 Passkey
    }
}
```

### 方案 3：时间窗口限制

```swift
struct TimeWindowProtection {
    // Passkey 创建后的有效期
    let passkeyValidityPeriod: TimeInterval = 90 * 24 * 3600 // 90天
    
    // 检查 Passkey 是否需要重新认证
    func checkPasskeyValidity() -> Bool {
        guard let createdAt = getPasskeyCreationDate() else { 
            return false 
        }
        
        let age = Date().timeIntervalSince(createdAt)
        
        if age > passkeyValidityPeriod {
            // 需要重新创建 Passkey
            promptReauthentication()
            return false
        }
        
        return true
    }
    
    // 定期轮换 Passkey
    func schedulePasskeyRotation() {
        Timer.scheduledTimer(withTimeInterval: passkeyValidityPeriod, repeats: true) { _ in
            rotatePasskey()
        }
    }
}
```

### 方案 4：多因素验证层

```swift
enum RecoveryInitiation {
    case passkeyOnly           // 不允许
    case passkeyPlusOTP        // Passkey + 一次性密码
    case passkeyPlusEmail      // Passkey + 邮件确认
    case passkeyPlusSocial     // Passkey + 社交确认
}

class EnhancedRecovery {
    // 发起重置需要额外验证
    func initiateRecovery() async throws {
        // 步骤1：Passkey 签名
        let passkeySignature = try await signWithPasskey()
        
        // 步骤2：发送 OTP 到注册邮箱
        let otp = generateOTP()
        sendEmail(to: registeredEmail, otp: otp)
        
        // 步骤3：用户输入 OTP
        let userOTP = await promptForOTP()
        
        guard userOTP == otp else {
            throw RecoveryError.invalidOTP
        }
        
        // 步骤4：记录设备信息用于审计
        recordRecoveryAttempt(device: currentDevice)
        
        // 步骤5：开始30天倒计时
        startRecoveryCountdown()
    }
}
```

### 方案 5：紧急撤销机制

```swift
class EmergencyRevocation {
    // 用户发现 iCloud 被盗后的紧急操作
    func emergencyRevokeAllPasskeys() {
        // 1. 立即增加版本号，使所有旧 Passkey 失效
        VersionedPasskey.currentVersion += 1
        
        // 2. 清空授权设备列表
        iCloudKeyValue.removeObject(forKey: "authorized_devices")
        
        // 3. 在链上标记紧急状态
        smartWallet.setEmergencyMode(true)
        
        // 4. 通知所有已知渠道
        notifyAllChannels("紧急：检测到账户入侵，所有 Passkeys 已撤销")
        
        // 5. 要求重新设置所有密钥
        requireFullReauthentication()
    }
    
    // 智能合约端的紧急模式
    contract SmartWallet {
        bool public emergencyMode = false;
        
        modifier notInEmergency() {
            require(!emergencyMode, "Wallet in emergency mode");
            _;
        }
        
        // 紧急模式下，只有 SC 可以操作
        function setEmergencyMode(bool _mode) external onlySecureEnclave {
            emergencyMode = _mode;
            if (_mode) {
                // 取消所有待处理的恢复请求
                cancelAllPendingRecoveries();
            }
        }
    }
}
```

### 方案 6：设备审计日志

```swift
struct DeviceAuditLog {
    struct DeviceActivity {
        let deviceId: String
        let deviceName: String
        let lastSeen: Date
        let actions: [Action]
        
        struct Action {
            let type: ActionType
            let timestamp: Date
            let success: Bool
        }
    }
    
    // 显示所有使用过 Passkey 的设备
    func showDeviceHistory() -> [DeviceActivity] {
        // 从 iCloud 读取所有设备活动
        return iCloudKeyValue.array(forKey: "device_history")
            .map { DeviceActivity(from: $0) }
            .sorted { $0.lastSeen > $1.lastSeen }
    }
    
    // 允许用户撤销特定设备
    func revokeDevice(_ deviceId: String) {
        var blockedDevices = iCloudKeyValue.array(forKey: "blocked_devices") ?? []
        blockedDevices.append(deviceId)
        iCloudKeyValue.set(blockedDevices, forKey: "blocked_devices")
        
        // 立即更新 Passkey 版本
        VersionedPasskey.currentVersion += 1
    }
}
```

## 完整防御架构

```swift
class SecureWalletDefense {
    // 多层防御
    func setupDefense() {
        // Layer 1: 版本控制
        enablePasskeyVersioning()
        
        // Layer 2: 设备绑定
        bindPasskeyToDevice()
        
        // Layer 3: 时间限制
        setPasskeyExpiration(days: 90)
        
        // Layer 4: 多因素验证
        requireMultiFactorForRecovery()
        
        // Layer 5: 审计追踪
        enableDeviceAuditLog()
        
        // Layer 6: 紧急撤销
        setupEmergencyRevocation()
    }
    
    // 检测可疑活动
    func detectSuspiciousActivity() {
        // 新设备使用旧 Passkey
        if isNewDevice() && isOldPasskey() {
            alertUser("⚠️ 检测到陌生设备使用您的 Passkey")
            requireAdditionalVerification()
        }
        
        // 异常地理位置
        if isUnusualLocation() {
            alertUser("⚠️ 检测到异常位置的访问")
            requireLocationConfirmation()
        }
        
        // 异常时间
        if isUnusualTime() {
            delayOperation(minutes: 30)
        }
    }
}
```

## 用户操作指南

### 当怀疑 iCloud 被盗时：

1. **立即行动**（5分钟内）
   ```
   1. 打开钱包 App
   2. 进入安全设置
   3. 点击"紧急撤销所有 Passkeys"
   4. 使用 SC (Face ID) 确认
   ```

2. **24小时内**
   ```
   1. 更改 iCloud 密码
   2. 检查设备列表，移除陌生设备
   3. 重新创建新版本 Passkey
   4. 检查是否有待处理的重置请求
   ```

3. **后续措施**
   ```
   1. 启用额外安全措施（OTP、邮件验证）
   2. 设置更短的 Passkey 有效期
   3. 定期检查设备审计日志
   ```

## 智能合约实现

```solidity
contract SecureSmartWallet {
    // 版本化 Passkey 管理
    uint256 public currentPasskeyVersion;
    mapping(uint256 => address) public passkeysByVersion;
    mapping(address => bool) public blockedPasskeys;
    
    // 紧急模式
    bool public emergencyMode;
    uint256 public emergencyModeUntil;
    
    // 重置请求增强
    struct RecoveryRequest {
        address newKey;
        uint256 passkeyVersion;  // 记录发起时的版本
        uint256 initiatedAt;
        uint256 executeAfter;
        bool cancelled;
        bytes32 otpHash;         // 需要 OTP 验证
    }
    
    modifier onlyCurrentPasskey() {
        require(
            msg.sender == passkeysByVersion[currentPasskeyVersion],
            "Outdated or invalid passkey"
        );
        require(
            !blockedPasskeys[msg.sender],
            "Passkey has been blocked"
        );
        _;
    }
    
    // SC 可以立即撤销所有 Passkeys
    function emergencyRevokePasskeys() external onlySecureEnclave {
        currentPasskeyVersion++;
        emergencyMode = true;
        emergencyModeUntil = block.timestamp + 7 days;
        
        // 取消所有待处理的恢复
        delete pendingRecovery;
        
        emit EmergencyRevocation(block.timestamp);
    }
}
```

## 结论

### 核心策略
1. **版本化 Passkeys**：最有效的防御方式
2. **设备绑定**：限制 Passkey 使用范围
3. **多因素验证**：增加攻击难度
4. **紧急撤销**：快速响应入侵

### 实施优先级
1. 🔴 **立即实施**：版本化 Passkeys
2. 🟠 **尽快实施**：紧急撤销机制
3. 🟡 **计划实施**：设备审计日志
4. 🟢 **逐步优化**：多因素验证

这样即使攻击者设备上还有旧 Passkey，也无法使用它来发起重置请求！