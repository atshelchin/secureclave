#!/bin/bash

echo "🚀 设置 shelchin2025.github.io 仓库"
echo "===================================="
echo ""

# 检查是否已存在仓库
if [ -d "shelchin2025.github.io" ]; then
    echo "⚠️  目录已存在，跳过克隆"
    cd shelchin2025.github.io
else
    echo "📦 创建本地仓库..."
    mkdir shelchin2025.github.io
    cd shelchin2025.github.io
    git init
fi

# 创建必要的目录和文件
echo "📁 创建 .well-known 目录..."
mkdir -p .well-known

# 复制 AASA 文件
echo "📄 复制 AASA 文件..."
cat > .well-known/apple-app-site-association << 'EOF'
{
  "webcredentials": {
    "apps": [
      "F9W689P9NE.app.hotlabs.secureenclave"
    ]
  },
  "applinks": {
    "details": []
  },
  "_comment": "AASA for shelchin2025.github.io - Created: 2025-09-05"
}
EOF

# 创建主页
echo "📝 创建 index.html..."
cat > index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Shelchin2025 - Passkeys Test Domain</title>
    <meta charset="utf-8">
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            max-width: 800px;
            margin: 50px auto;
            padding: 20px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
        }
        .container {
            background: white;
            border-radius: 10px;
            padding: 30px;
            box-shadow: 0 20px 40px rgba(0,0,0,0.1);
        }
        h1 { color: #333; }
        .status { 
            background: #f0f9ff; 
            border: 1px solid #3b82f6;
            padding: 15px;
            border-radius: 5px;
            margin: 20px 0;
        }
        code {
            background: #f3f4f6;
            padding: 2px 5px;
            border-radius: 3px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🔑 Passkeys Test Domain</h1>
        <p>This domain is configured for testing Passkeys with the SecureEnclave iOS app.</p>
        
        <div class="status">
            <h3>✅ AASA Configuration</h3>
            <p>Team ID: <code>F9W689P9NE</code></p>
            <p>Bundle ID: <code>app.hotlabs.secureenclave</code></p>
            <p>RP ID: <code>shelchin2025.github.io</code></p>
        </div>
        
        <h3>📋 Quick Links</h3>
        <ul>
            <li><a href="/.well-known/apple-app-site-association">View AASA File</a></li>
            <li><a href="https://github.com/shelchin2025/shelchin2025.github.io">GitHub Repository</a></li>
        </ul>
        
        <h3>🔍 Verify Configuration</h3>
        <pre><code>curl https://shelchin2025.github.io/.well-known/apple-app-site-association</code></pre>
    </div>
</body>
</html>
EOF

# Git 操作
echo "📦 准备提交..."
git add .
git commit -m "Initial commit with AASA for Passkeys support"

echo ""
echo "✅ 本地仓库已准备就绪！"
echo ""
echo "📋 下一步操作："
echo "1. 在 GitHub 上创建仓库 'shelchin2025.github.io'"
echo "   访问: https://github.com/new"
echo "   仓库名: shelchin2025.github.io"
echo "   设置为: Public"
echo ""
echo "2. 添加远程仓库并推送："
echo "   git remote add origin https://github.com/shelchin2025/shelchin2025.github.io.git"
echo "   git branch -M main"
echo "   git push -u origin main"
echo ""
echo "3. 启用 GitHub Pages:"
echo "   Settings > Pages > Source: Deploy from a branch"
echo "   Branch: main / (root)"
echo ""
echo "4. 等待几分钟后验证:"
echo "   curl https://shelchin2025.github.io/.well-known/apple-app-site-association"