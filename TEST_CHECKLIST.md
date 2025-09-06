# 测试检查清单

## ✅ 问题已修复

### CloudKit/SwiftData 要求
- ✅ 所有属性都有默认值
- ✅ 关系有反向引用 (`@Relationship` with `inverse`)
- ✅ 关系是可选的 (`[OperationLog]?`)
- ✅ 枚举通过原始值存储

### Team ID 配置
- **你的 Team ID**: `9RS8E64FWL`
- **Bundle ID**: `app.hotlabs.secureenclave`
- **完整 App ID**: `9RS8E64FWL.app.hotlabs.secureenclave`

## 📱 测试步骤

### 1. 基础功能测试（模拟器可用）
```bash
# 在模拟器运行
1. 打开应用，确认没有崩溃
2. 查看主界面三个功能入口
3. 进入 "iCloud Sync Debug" 查看状态
```

### 2. Secure Enclave 测试（需要真机）
```bash
# 必须在真机上测试
1. 连接 iPhone/iPad
2. 确保设置了 Face ID 或 Touch ID
3. 进入 "Secure Enclave" 功能
4. 生成密钥
5. 测试签名和验证
```

### 3. Passkeys 测试（需要配置）
```bash
# 前置条件
1. 部署 apple-app-site-association 到 GitHub Pages
2. 确保文件可访问：
   https://atshelchin.github.io/.well-known/apple-app-site-association
3. 内容应该是：
   {
     "webcredentials": {
       "apps": ["9RS8E64FWL.app.hotlabs.secureenclave"]
     }
   }
```

### 4. iCloud 同步测试
```bash
# 前置条件
1. 登录 iCloud 账号
2. 启用 iCloud Drive
3. 网络连接正常

# 测试步骤
1. 在设备A创建密钥
2. 在设备B查看是否同步
3. 使用 "Force Sync" 手动同步
```

## 🔍 调试提示

### 查看控制台日志
```bash
# Xcode Console 会显示：
- SwiftData 初始化状态
- CloudKit 连接状态
- 错误信息
```

### 常见问题

1. **"Could not create ModelContainer"**
   - ✅ 已修复：添加默认值和反向关系

2. **Team ID 不匹配**
   - 确认 Xcode → Settings → Accounts 中的 Team ID
   - 更新 apple-app-site-association 文件

3. **Passkeys 不工作**
   - 检查网络连接
   - 验证域名配置
   - 查看 Console 日志

## 📊 预期结果

### 成功标志
- ✅ 应用启动无崩溃
- ✅ 可以创建和查看密钥
- ✅ iCloud 状态显示 "Available"（如果已登录）
- ✅ 日志显示操作成功

### 可接受的警告
- ⚠️ "Secure Enclave not available"（在模拟器上）
- ⚠️ "iCloud temporarily unavailable"（网络问题）
- ⚠️ 首次运行时的 CloudKit schema 创建消息