# 紧急密钥轮换系统 - 一键更换所有密钥

## 核心策略
一旦检测到非法重置请求，立即更换所有钱包的 Passkeys 和 SC Key，让攻击者的密钥立即失效。

## 1. 紧急轮换触发机制

```swift
class EmergencyKeyRotation {
    
    enum TriggerReason {
        case suspiciousResetRequest     // 可疑重置请求
        case unauthorizedDevice         // 未授权设备访问
        case iCloudCompromise          // iCloud 账户被盗
        case userInitiated             // 用户主动触发
        case anomalyDetected           // 系统检测到异常
    }
    
    func detectIllegalReset(_ request: ResetRequest) -> Bool {
        // 多维度判断是否为非法请求
        let checks = [
            request.deviceId != currentDevice.id,
            !knownDevices.contains(request.deviceId),
            request.location.distance(from: userLocation) > 1000, // 1000km
            request.timestamp.isUnusualHour(),
            !userInitiatedRecovery()
        ]
        
        // 3个以上异常信号 = 非法请求
        return checks.filter { $0 }.count >= 3
    }
    
    func handleIllegalReset(_ request: ResetRequest) {
        // 1. 立即冻结当前操作
        freezeAllOperations()
        
        // 2. 通知用户
        sendEmergencyAlert(
            title: "🚨 安全警告",
            body: "检测到非法重置请求，正在执行紧急安全措施"
        )
        
        // 3. 执行全量密钥轮换
        performEmergencyRotation(reason: .suspiciousResetRequest)
    }
}
```

## 2. 全量密钥轮换流程

```swift
class BatchKeyRotation {
    
    struct RotationPlan {
        let wallets: [Wallet]
        let oldKeys: KeySet
        let newKeys: KeySet
        let timestamp: Date
        let reason: TriggerReason
    }
    
    func performEmergencyRotation(reason: TriggerReason) async {
        // Phase 1: 准备新密钥
        let plan = await prepareRotationPlan(reason: reason)
        
        // Phase 2: 并行更新所有钱包
        await withTaskGroup(of: RotationResult.self) { group in
            for wallet in plan.wallets {
                group.addTask {
                    await self.rotateWalletKeys(wallet, plan: plan)
                }
            }
            
            // 收集结果
            var results: [RotationResult] = []
            for await result in group {
                results.append(result)
            }
            
            // Phase 3: 验证和清理
            await finalizeRotation(results: results, plan: plan)
        }
    }
    
    func rotateWalletKeys(_ wallet: Wallet, plan: RotationPlan) async -> RotationResult {
        do {
            // 1. 生成新的 SC Key
            let newSCKey = try await SecureEnclaveManager.generateNewKey()
            
            // 2. 生成新的 Passkey
            let newPasskey = try await PasskeysManager.createNewPasskey(
                domain: wallet.domain,
                username: wallet.address
            )
            
            // 3. 更新智能合约（原子操作）
            try await wallet.smartContract.updateKeys(
                newSCKey: newSCKey.publicKey,
                newPasskey: newPasskey.publicKey,
                signature: plan.oldKeys.scKey.sign(updateMessage)
            )
            
            // 4. 确认更新成功
            let confirmed = try await wallet.smartContract.verifyKeyUpdate()
            
            return RotationResult(
                wallet: wallet,
                success: confirmed,
                newKeys: KeyPair(sc: newSCKey, passkey: newPasskey)
            )
            
        } catch {
            // 记录失败，稍后重试
            return RotationResult(
                wallet: wallet,
                success: false,
                error: error
            )
        }
    }
}
```

## 3. 智能合约端支持

```solidity
contract EmergencyRotatableWallet {
    
    // 紧急轮换事件
    event EmergencyKeyRotation(
        address oldSCKey,
        address newSCKey,
        address oldPasskey,
        address newPasskey,
        uint256 timestamp
    );
    
    // 允许 SC Key 紧急更换所有密钥
    function emergencyRotateKeys(
        address newSCKey,
        address newPasskey,
        bytes calldata signature
    ) external {
        // 验证签名来自当前 SC Key
        require(
            verifySCSignature(signature),
            "Invalid SC signature"
        );
        
        // 立即生效，无需等待
        address oldSC = scKey;
        address oldPK = passkeyAddress;
        
        scKey = newSCKey;
        passkeyAddress = newPasskey;
        
        // 取消所有待处理的重置请求
        delete pendingResetRequest;
        
        // 记录事件
        emit EmergencyKeyRotation(
            oldSC,
            newSCKey,
            oldPK,
            newPasskey,
            block.timestamp
        );
        
        // 可选：将旧密钥加入黑名单
        blacklistedKeys[oldSC] = true;
        blacklistedKeys[oldPK] = true;
    }
    
    // 批量更新多个钱包（gas 优化）
    function batchEmergencyRotation(
        address[] calldata wallets,
        address[] calldata newSCKeys,
        address[] calldata newPasskeys,
        bytes[] calldata signatures
    ) external {
        require(wallets.length == newSCKeys.length, "Length mismatch");
        require(wallets.length == newPasskeys.length, "Length mismatch");
        
        for (uint i = 0; i < wallets.length; i++) {
            IWallet(wallets[i]).emergencyRotateKeys(
                newSCKeys[i],
                newPasskeys[i],
                signatures[i]
            );
        }
    }
}
```

## 4. 用户体验优化

```swift
class EmergencyRotationUI {
    
    func showEmergencyAlert() -> some View {
        VStack(spacing: 20) {
            // 醒目的警告图标
            Image(systemName: "exclamationmark.shield.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text("检测到安全威胁")
                .font(.title)
                .bold()
            
            Text("发现非法重置请求，需要立即更新所有密钥")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            // 一键执行
            Button(action: executeEmergencyRotation) {
                Label("立即保护我的钱包", systemImage: "lock.shield.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            
            // 进度展示
            if isRotating {
                RotationProgressView(progress: rotationProgress)
            }
        }
        .padding()
    }
    
    func executeEmergencyRotation() {
        Task {
            // 1. 生物识别确认
            let authenticated = await authenticateUser()
            guard authenticated else { return }
            
            // 2. 显示进度
            showProgress = true
            
            // 3. 执行轮换
            let results = await BatchKeyRotation().performEmergencyRotation(
                reason: .suspiciousResetRequest
            )
            
            // 4. 显示结果
            showRotationResults(results)
        }
    }
}
```

## 5. 轮换后的验证和恢复

```swift
class PostRotationVerification {
    
    func verifyRotationSuccess(_ results: [RotationResult]) async {
        // 1. 验证所有钱包都已更新
        for result in results {
            if !result.success {
                // 重试失败的钱包
                await retryRotation(result.wallet)
            }
        }
        
        // 2. 验证旧密钥已失效
        let oldKeyTest = await testOldKeys(deprecated: results.map(\.oldKeys))
        assert(oldKeyTest.allFailed, "Old keys should be invalid")
        
        // 3. 验证新密钥可用
        let newKeyTest = await testNewKeys(active: results.map(\.newKeys))
        assert(newKeyTest.allSucceeded, "New keys should work")
        
        // 4. 清理旧密钥
        await cleanupOldKeys()
    }
    
    // 保存轮换记录用于审计
    func saveRotationRecord(_ plan: RotationPlan, results: [RotationResult]) {
        let record = RotationRecord(
            id: UUID(),
            timestamp: Date(),
            reason: plan.reason,
            walletsRotated: results.count,
            successCount: results.filter(\.success).count,
            oldKeyHashes: plan.oldKeys.map(\.hash),
            newKeyHashes: plan.newKeys.map(\.hash)
        )
        
        // 本地保存
        KeychainManager.save(record)
        
        // 云端备份（加密）
        CloudBackup.save(encrypted: record)
    }
}
```

## 6. 防止轮换竞争

```swift
class RotationRaceConditionPrevention {
    
    // 防止攻击者同时发起轮换
    func preventRaceCondition() {
        // 1. 轮换锁定期
        let rotationLock = RotationLock(duration: .minutes(5))
        
        // 2. 只允许最高权限的密钥发起
        guard hasHighestAuthority() else {
            throw RotationError.insufficientPrivilege
        }
        
        // 3. 多因素确认
        let confirmed = await confirmWithMultipleMethods([
            .biometric,
            .devicePIN,
            .recoveryPhrase
        ])
        
        guard confirmed else {
            throw RotationError.verificationFailed
        }
    }
    
    // 原子性保证
    func atomicRotation() async {
        // 使用数据库事务确保原子性
        try await database.transaction { tx in
            // 1. 锁定所有钱包
            tx.lockWallets()
            
            // 2. 批量更新
            tx.updateAllKeys()
            
            // 3. 验证一致性
            tx.verifyConsistency()
            
            // 4. 提交或回滚
            tx.commit()
        }
    }
}
```

## 7. 自动化响应流程

```swift
class AutomatedSecurityResponse {
    
    func setupAutomaticProtection() {
        // 监听异常事件
        EventMonitor.on(.suspiciousReset) { event in
            Task {
                // 1. 立即分析威胁
                let threat = await analyzeThreat(event)
                
                if threat.severity >= .high {
                    // 2. 自动触发轮换
                    await triggerEmergencyRotation(
                        reason: threat.type,
                        requireUserConfirm: threat.severity < .critical
                    )
                    
                    // 3. 通知用户结果
                    notifyUser(
                        "已自动更换所有密钥",
                        "检测到威胁并已处理，您的资产是安全的"
                    )
                }
            }
        }
    }
    
    // 分级响应
    enum ResponseLevel {
        case monitor          // 仅监控
        case alert           // 提醒用户
        case semiAutomatic   // 需用户确认
        case automatic       // 全自动处理
    }
    
    func determineResponse(_ threat: Threat) -> ResponseLevel {
        switch (threat.severity, threat.confidence) {
        case (.critical, .high):
            return .automatic  // 高威胁高置信度，自动处理
        case (.high, .medium):
            return .semiAutomatic  // 需要用户确认
        case (.medium, _):
            return .alert  // 提醒用户
        default:
            return .monitor  // 仅监控
        }
    }
}
```

## 8. 实施要点

### 优势
1. **即时失效**：攻击者的密钥立即无效
2. **全面保护**：所有钱包同时更新
3. **自动化**：减少用户操作负担
4. **不可逆**：攻击者无法阻止

### 注意事项
1. **Gas 成本**：批量更新可能消耗较多 Gas
2. **并发控制**：防止同时多个轮换请求
3. **失败处理**：个别钱包更新失败的重试机制
4. **用户教育**：让用户理解这是保护措施

### 实施步骤
```
1. 检测威胁 → 2. 用户确认 → 3. 生成新密钥 → 4. 批量更新 → 5. 验证成功
```

## 9. 成本优化

```solidity
// Gas 优化的批量更新
contract GasOptimizedRotation {
    
    // 使用 Merkle Tree 批量验证
    function batchRotateWithProof(
        bytes32 merkleRoot,
        bytes32[] calldata proofs,
        address[] calldata newKeys
    ) external {
        // 一次验证，批量更新
        require(verifyMerkleProof(merkleRoot, proofs), "Invalid proof");
        
        // 批量更新，节省 gas
        for (uint i = 0; i < newKeys.length; i++) {
            wallets[i].updateKey(newKeys[i]);
        }
    }
}
```

## 10. 总结

通过**一键紧急轮换**机制，一旦发现非法重置请求：
1. 立即让攻击者持有的密钥失效
2. 全部钱包同时更新，不给攻击者机会
3. 自动化处理，用户只需确认一次
4. 完整的审计和恢复机制

这样即使 Passkeys 在攻击者设备上，也立即变成无用的密钥。