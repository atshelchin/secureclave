# Secure Enclave Debug App

一个用于调试和测试iOS Secure Enclave、Passkeys和iCloud SwiftData同步功能的应用。

## 功能特性

### 1. Secure Enclave 调试
- ✅ 生成硬件加密密钥
- ✅ 支持生物识别保护（Face ID/Touch ID）
- ✅ 数字签名和验证
- ✅ 密钥管理（创建、检索、删除、列表）
- ✅ 完整的操作日志记录

### 2. Passkeys 认证
- ✅ 创建和管理Passkey凭据
- ✅ 使用域名：`atshelchin.github.io`
- ✅ 生物识别认证
- ✅ AutoFill集成支持
- ✅ 凭据管理和追踪

### 3. iCloud SwiftData 同步
- ✅ 自动同步到CloudKit
- ✅ 存储所有密钥和Passkey数据
- ✅ 实时同步状态监控
- ✅ CloudKit连接测试
- ✅ 调试工具和日志

## 系统要求

- iOS 16.0+（Passkeys功能需要）
- 真实设备（Secure Enclave不支持模拟器）
- 配置Face ID或Touch ID
- 登录iCloud账号

## 安装步骤

1. 在Xcode中打开项目
2. 选择你的开发团队
3. 连接iPhone设备
4. 构建并运行应用

## Passkeys配置

### GitHub Pages设置

1. 在你的GitHub Pages仓库（`atshelchin.github.io`）创建以下文件结构：
```
.well-known/
└── apple-app-site-association
```

2. 将以下内容添加到`apple-app-site-association`文件：
```json
{
  "webcredentials": {
    "apps": [
      "9RS8E64FWL.app.hotlabs.secureenclave"
    ]
  }
}
```

3. 确保文件通过HTTPS访问：
```
https://atshelchin.github.io/.well-known/apple-app-site-association
```

## 使用指南

### Secure Enclave测试

1. 打开应用，点击"Secure Enclave"
2. 输入密钥标签（自动生成）
3. 选择是否需要生物识别保护
4. 点击"Generate Key"创建密钥
5. 使用"Sign Data"对数据签名
6. 使用"Verify"验证签名

### Passkeys测试

1. 点击"Passkeys"进入测试界面
2. 输入用户名（默认：testuser@atshelchin.github.io）
3. 点击"Create Passkey"创建凭据
4. 使用Face ID/Touch ID确认
5. 点击"Sign In with Passkey"测试登录

### iCloud同步调试

1. 点击"iCloud Sync Debug"
2. 查看同步状态和统计信息
3. 使用"Force Sync to iCloud"手动同步
4. 使用"Test CloudKit Connection"测试连接

## 注意事项

⚠️ **重要提示**：
- Secure Enclave功能仅在真机上可用
- Passkeys需要配置Associated Domains
- 确保已登录iCloud账号以使用同步功能
- 首次使用需要网络连接验证域名

## 调试信息

所有操作都会生成详细的日志，可在各个功能页面底部查看。日志包含：
- ✅ 成功操作（绿色）
- ❌ 错误信息（红色）
- ⚠️ 警告信息（橙色）
- 时间戳和详细描述

## 故障排除

### Passkeys不工作
- 确认apple-app-site-association文件已部署
- 检查Bundle ID和Team ID是否匹配
- 确保设备已连接网络

### iCloud同步问题
- 检查iCloud账号登录状态
- 确认CloudKit容器配置正确
- 查看CloudSyncDebugView中的日志

### Secure Enclave错误
- 确保在真机上运行（不支持模拟器）
- 检查生物识别是否已注册
- 查看操作日志获取详细错误信息

## 技术架构

- **SwiftUI**：现代声明式UI框架
- **SwiftData**：持久化和iCloud同步
- **CryptoKit**：加密操作
- **LocalAuthentication**：生物识别
- **AuthenticationServices**：Passkeys实现
- **CloudKit**：iCloud同步

## 文件结构

```
secureenclave/
├── Models/
│   └── KeychainItem.swift         # 数据模型
├── Managers/
│   ├── SecureEnclaveManager.swift # SE操作管理
│   └── PasskeysManager.swift      # Passkey管理
├── Views/
│   ├── SecureEnclaveTestView.swift # SE测试界面
│   ├── PasskeysTestView.swift      # Passkey测试界面
│   └── CloudSyncDebugView.swift    # 同步调试界面
├── ContentView.swift               # 主界面
└── secureenclaveApp.swift         # 应用入口
```

## 许可证

此项目仅供调试和学习使用。