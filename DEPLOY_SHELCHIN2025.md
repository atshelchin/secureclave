# 🚀 部署 shelchin2025.github.io 配置

## 📋 部署步骤

### 1. 在 GitHub 创建/更新仓库
如果还没有 `shelchin2025.github.io` 仓库：
1. 登录 GitHub
2. 创建新仓库，名称为 `shelchin2025.github.io`
3. 设置为 Public

### 2. 部署 AASA 文件

```bash
# 克隆仓库（如果是新建的）
git clone https://github.com/shelchin2025/shelchin2025.github.io.git
cd shelchin2025.github.io

# 创建 .well-known 目录
mkdir -p .well-known

# 复制 AASA 文件
cp ../secureenclave/shelchin2025-config/apple-app-site-association .well-known/

# 提交并推送
git add .
git commit -m "Add AASA for Passkeys support"
git push origin main
```

### 3. 启用 GitHub Pages
1. 进入仓库设置 > Pages
2. Source: Deploy from a branch
3. Branch: main / (root)
4. 保存

### 4. 验证部署

等待几分钟后，验证文件是否可访问：

```bash
# 检查 AASA 文件
curl https://shelchin2025.github.io/.well-known/apple-app-site-association

# 应该返回：
{
  "webcredentials": {
    "apps": [
      "F9W689P9NE.app.hotlabs.secureenclave"
    ]
  }
}
```

### 5. 检查 Apple CDN（新域名应该立即生效）

```bash
# 检查 Apple CDN
curl https://app-site-association.cdn-apple.com/a/v1/shelchin2025.github.io
```

## ✅ 优势

使用 `shelchin2025.github.io` 作为第二个 RP ID 的优势：

1. **全新域名** - 没有 CDN 缓存问题
2. **独立控制** - 可以独立测试不同配置
3. **备份方案** - 当主域名有问题时可以切换
4. **测试环境** - 可以用于测试新功能

## 📱 在应用中使用

应用已配置好支持两个域名：
- `atshelchin.github.io` (主域名)
- `shelchin2025.github.io` (备用域名)

在 ModernPasskeysView 中可以通过选择器切换：
- GitHub Pages (Main) → atshelchin.github.io
- GitHub Pages (2025) → shelchin2025.github.io

## 🔍 测试步骤

1. 部署 AASA 到 shelchin2025.github.io
2. 在 Xcode 中 Clean Build Folder
3. 重新构建应用
4. 在应用中切换到 "GitHub Pages (2025)"
5. 尝试创建 Passkey

## ⚠️ 注意事项

- 确保 Team ID 是 `F9W689P9NE`
- Bundle ID 是 `app.hotlabs.secureenclave`
- 两个域名的 Passkey 是**独立的**，不能互用

## 📊 状态检查脚本

```bash
#!/bin/bash
echo "检查两个域名的 AASA 状态："
echo ""
echo "1. atshelchin.github.io:"
curl -s https://atshelchin.github.io/.well-known/apple-app-site-association | grep -o '[A-Z0-9]*\.app\.hotlabs'
echo ""
echo "2. shelchin2025.github.io:"
curl -s https://shelchin2025.github.io/.well-known/apple-app-site-association | grep -o '[A-Z0-9]*\.app\.hotlabs'
```