#!/bin/bash
set -e

echo "🚀 iOS权限修复 - 完整流程"
echo "================================"

cd /home/user/archerypro

echo ""
echo "步骤1: 清理Flutter缓存..."
flutter clean

echo ""
echo "步骤2: 重新获取Dart依赖..."
flutter pub get

echo ""
echo "步骤3: 清理iOS Pods缓存（最关键！）..."
cd ios
rm -rf Pods
rm -f Podfile.lock  
rm -rf build
rm -rf .symlinks

echo ""
echo "步骤4: 重新安装Pods..."
pod install

cd ..

echo ""
echo "================================"
echo "✅ 清理完成！"
echo ""
echo "⚠️  现在请执行以下操作："
echo "1. 在设备上完全卸载「射箭专业版」App"
echo "2. 执行: flutter run"
echo "3. 首次点击保存时会弹出权限请求"
echo "================================"
