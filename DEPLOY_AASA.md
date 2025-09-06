# 🚀 部署 AASA 文件到 GitHub Pages

## 📋 当前配置

- **Team ID**: F9W689P9NE（你的实际 Developer ID）
- **Bundle ID**: app.hotlabs.secureenclave
- **Domain**: atshelchin.github.io

## 📁 AASA 文件内容

文件已更新为：
```json
{
  "webcredentials": {
    "apps": [
      "F9W689P9NE.app.hotlabs.secureenclave"
    ]
  }
}
```

## 🔧 部署步骤

### 方法 1：通过 GitHub 网页界面

1. 访问你的 GitHub Pages 仓库：https://github.com/atshelchin/atshelchin.github.io
2. 创建文件夹路径：`.well-known`
3. 在 `.well-known` 文件夹中创建文件：`apple-app-site-association`（无扩展名）
4. 粘贴上述 JSON 内容
5. 提交更改

### 方法 2：通过命令行

```bash
# 克隆你的 GitHub Pages 仓库
git clone https://github.com/atshelchin/atshelchin.github.io.git
cd atshelchin.github.io

# 创建 .well-known 目录
mkdir -p .well-known

# 复制 AASA 文件
cp /Users/shelchin/ai-repo2025/secureenclave/well-known-config/apple-app-site-association .well-known/

# 提交并推送
git add .well-known/apple-app-site-association
git commit -m "Update AASA file with correct Team ID (F9W689P9NE)"
git push
```

## ✅ 验证部署

部署后，验证文件是否可访问：

```bash
# 检查文件是否可访问
curl https://atshelchin.github.io/.well-known/apple-app-site-association

# 应该返回：
{
  "webcredentials": {
    "apps": [
      "F9W689P9NE.app.hotlabs.secureenclave"
    ]
  }
}
```

## ⏱ 等待时间

- GitHub Pages 更新通常需要 1-5 分钟
- Apple CDN 缓存可能需要额外 5-10 分钟
- 如果仍然失败，尝试：
  1. 删除应用
  2. 重启设备
  3. 重新安装应用

## 🔍 故障排除

如果 Passkeys 仍然失败，检查：

1. **确认 Team ID**
   ```bash
   security find-identity -v -p codesigning | grep "F9W689P9NE"
   ```

2. **确认 AASA 文件内容类型**
   ```bash
   curl -I https://atshelchin.github.io/.well-known/apple-app-site-association
   # Content-Type 应该是 application/json 或 application/octet-stream
   ```

3. **清除缓存**
   - 在设备上：设置 → 开发者 → Clear Trusted Computers
   - 重启设备

## 📝 重要说明

**为什么是 F9W689P9NE 而不是 9RS8E64FWL？**

- F9W689P9NE 是你的主 Developer ID（签名证书使用的）
- 9RS8E64FWL 是 Apple Development 证书
- Passkeys 使用实际签名应用的 Team ID，即 F9W689P9NE