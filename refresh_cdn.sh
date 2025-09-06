#!/bin/bash

echo "🔄 Apple CDN AASA 缓存刷新脚本"
echo "================================"
echo ""

# 检查当前状态
echo "📊 当前状态检查："
echo ""

echo "1️⃣ GitHub Pages 上的 AASA (正确版本):"
curl -s https://atshelchin.github.io/.well-known/apple-app-site-association | grep -o '[A-Z0-9]*\.app\.hotlabs\.secureenclave' || echo "获取失败"
echo ""

echo "2️⃣ Apple CDN 缓存的 AASA (可能是旧版本):"
curl -s https://app-site-association.cdn-apple.com/a/v1/atshelchin.github.io | grep -o '[A-Z0-9]*\.app\.hotlabs\.secureenclave' || echo "获取失败"
echo ""

echo "================================"
echo "🛠 可执行的操作："
echo ""
echo "1. 使用 swcutil 验证（需要 sudo 权限）："
echo "   sudo swcutil verify -d atshelchin.github.io -s webcredentials"
echo ""
echo "2. 重置 swcd 缓存（需要 sudo 权限）："
echo "   sudo swcutil reset"
echo ""
echo "3. 查看详细的 AASA 内容："
echo "   curl -s https://atshelchin.github.io/.well-known/apple-app-site-association | python3 -m json.tool"
echo ""
echo "4. 在 iOS 设备上强制刷新："
echo "   - 删除应用"
echo "   - 设置 > 通用 > 传输或还原 iPhone > 还原 > 还原网络设置"
echo "   - 重新安装应用"
echo ""
echo "5. 使用 Xcode 清理："
echo "   - Product > Clean Build Folder (Shift+Cmd+K)"
echo "   - 删除 Derived Data"
echo "   - 重新构建和运行"
echo ""

# 提供快速复制的命令
echo "================================"
echo "📋 快速复制命令："
echo ""
echo "验证命令："
echo "sudo swcutil verify -d atshelchin.github.io -s webcredentials"
echo ""
echo "重置命令："
echo "sudo swcutil reset"
echo ""

# 检查是否可以运行 sudo
echo "================================"
echo "💡 提示：运行以下命令来执行刷新："
echo "chmod +x refresh_cdn.sh"
echo "sudo ./refresh_cdn.sh --execute"
echo ""

# 如果带 --execute 参数，尝试执行
if [ "$1" == "--execute" ]; then
    echo "🚀 正在尝试刷新..."
    echo "需要输入密码来执行 sudo 命令"
    
    # 验证当前状态
    echo "验证当前状态..."
    sudo swcutil verify -d atshelchin.github.io -s webcredentials
    
    # 重置缓存
    echo "重置 swcd 缓存..."
    sudo swcutil reset
    
    # 再次验证
    echo "再次验证..."
    sudo swcutil verify -d atshelchin.github.io -s webcredentials
    
    echo "✅ 刷新尝试完成！"
fi