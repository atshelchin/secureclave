# 设置说明

## 🔧 重要：首次设置

### 1. 配置你的Team ID

1. 打开Xcode中的项目
2. 选择 "secureenclave" target
3. 进入 "Signing & Capabilities" 标签
4. 在 "Team" 下拉菜单中选择你的开发团队
5. 查看Team名称后括号中的ID，例如：
   - "Qin Xie (Personal Team) (XXXXXXXXXX)" 
   - 其中 XXXXXXXXXX 就是你的Team ID

### 2. 更新 apple-app-site-association 文件

找到你的Team ID后，更新 `well-known-config/apple-app-site-association` 文件：

```json
{
  "webcredentials": {
    "apps": [
      "你的TEAM_ID.app.hotlabs.secureenclave"
    ]
  }
}
```

例如，如果你的Team ID是 `ABC123DEF4`，则应该是：
```json
{
  "webcredentials": {
    "apps": [
      "ABC123DEF4.app.hotlabs.secureenclave"
    ]
  }
}
```

### 3. 部署到 GitHub Pages

1. 将更新后的 `apple-app-site-association` 文件上传到你的GitHub Pages仓库
2. 路径必须是：`.well-known/apple-app-site-association`
3. 确保可以通过以下URL访问：
   ```
   https://atshelchin.github.io/.well-known/apple-app-site-association
   ```

### 4. 验证设置

运行以下命令验证文件是否正确部署：
```bash
curl https://atshelchin.github.io/.well-known/apple-app-site-association
```

应该返回你的JSON配置。

## ⚠️ 常见问题

### Team ID 相关
- **个人免费账号**：Team ID通常是10个字符
- **公司账号**：Team ID格式相同
- **找不到Team ID**：
  1. Xcode → Settings → Accounts
  2. 选择你的Apple ID
  3. 查看Team列表中的ID

### Bundle ID 冲突
如果 `app.hotlabs.secureenclave` 已被使用，你可以：
1. 修改为你自己的域名格式，如：`com.yourname.secureenclave`
2. 在Xcode中更新Bundle Identifier
3. 同步更新apple-app-site-association文件

### 签名问题
- 确保选择了正确的Team
- 启用 "Automatically manage signing"
- 如果出现provisioning profile错误，点击 "Try Again" 让Xcode重新生成

## 📝 检查清单

- [ ] 找到并记录你的Team ID
- [ ] 更新apple-app-site-association文件
- [ ] 部署文件到GitHub Pages
- [ ] 验证文件可访问
- [ ] 在Xcode中选择正确的Team
- [ ] Bundle ID没有冲突
- [ ] 构建成功