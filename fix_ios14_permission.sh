#!/bin/bash
set -e

echo "=================================================="
echo "🔧 iOS 14权限修复 - 完整清理重建流程"
echo "=================================================="
echo ""
echo "本脚本将执行以下操作："
echo "1. 拉取最新代码（iOS版本已升级到14.0）"
echo "2. 完全清理Flutter构建缓存"
echo "3. 清理iOS Pods和依赖"
echo "4. 重新安装Pods（使用iOS 14配置）"
echo "5. 引导您卸载并重新安装App"
echo ""
echo "⚠️  重要提示："
echo "- 本脚本不会自动卸载App，需要您手动操作"
echo "- 执行完毕后需要手动运行 flutter run"
echo ""

# 确认继续
read -p "是否继续？(y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo "❌ 已取消"
    exit 1
fi

cd /home/user/archerypro

echo ""
echo "步骤1: 拉取最新代码..."
echo "========================================"
git pull origin claude/plan-logic-architecture-4MDgy

echo ""
echo "步骤2: 验证iOS版本配置..."
echo "========================================"
echo "检查 Podfile:"
grep "platform :ios" ios/Podfile
echo ""
echo "检查 project.pbxproj (IPHONEOS_DEPLOYMENT_TARGET):"
grep "IPHONEOS_DEPLOYMENT_TARGET" ios/Runner.xcodeproj/project.pbxproj | head -3
echo ""

# 验证是否是14.0
if grep -q "platform :ios, '14.0'" ios/Podfile; then
    echo "✅ Podfile iOS版本正确: 14.0"
else
    echo "❌ 警告：Podfile iOS版本不是14.0！"
    exit 1
fi

echo ""
echo "步骤3: 清理Flutter构建缓存..."
echo "========================================"
flutter clean

echo ""
echo "步骤4: 重新获取Dart依赖..."
echo "========================================"
flutter pub get

echo ""
echo "步骤5: 清理iOS Pods缓存（关键步骤）..."
echo "========================================"
cd ios
echo "删除 Pods/"
rm -rf Pods
echo "删除 Podfile.lock"
rm -f Podfile.lock
echo "删除 build/"
rm -rf build
echo "删除 .symlinks/"
rm -rf .symlinks

echo ""
echo "步骤6: 更新CocoaPods仓库..."
echo "========================================"
pod repo update

echo ""
echo "步骤7: 重新安装Pods（使用iOS 14.0配置）..."
echo "========================================"
pod install

cd ..

echo ""
echo "=================================================="
echo "✅ 清理和重建完成！"
echo "=================================================="
echo ""
echo "📱 现在请执行以下操作："
echo ""
echo "1️⃣  在iOS设备或模拟器上完全卸载「射箭专业版」App"
echo "   - 长按App图标 → 删除App"
echo "   - 或在设置中卸载"
echo ""
echo "2️⃣  重新编译并安装App："
echo "   flutter run"
echo "   # 或者使用Release模式："
echo "   flutter run --release"
echo ""
echo "3️⃣  测试权限功能："
echo "   - 打开App，完成一次训练"
echo "   - 点击「保存到相册」"
echo "   - 应该弹出权限请求弹窗！"
echo "   - 弹窗内容：「需要相册权限来保存你的成绩海报。」"
echo "   - 点击「允许访问所有照片」或「选择的照片」"
echo ""
echo "4️⃣  验证成功标志："
echo "   ✅ 首次点击保存时弹出权限请求"
echo "   ✅ 系统设置 > 隐私与安全性 > 照片 中出现「射箭专业版」"
echo "   ✅ 照片成功保存到相册"
echo ""
echo "=================================================="
echo "💡 故障排查"
echo "=================================================="
echo ""
echo "如果仍然没有权限弹窗："
echo ""
echo "1. 确认iOS设备版本 >= 14.0"
echo "   - 设置 > 通用 > 关于本机 > iOS版本"
echo ""
echo "2. 尝试重置模拟器（仅模拟器）"
echo "   - Device > Erase All Content and Settings..."
echo ""
echo "3. 真机完全重启"
echo "   - 卸载App后重启设备"
echo "   - 再次运行 flutter run"
echo ""
echo "4. 检查编译产物中的Info.plist"
echo "   flutter build ios --simulator"
echo "   plutil -p build/ios/iphonesimulator/Runner.app/Info.plist | grep NSPhotoLibrary"
echo ""
echo "应该看到："
echo "  \"NSPhotoLibraryAddUsageDescription\" => \"需要相册权限来保存你的成绩海报。\""
echo "  \"NSPhotoLibraryUsageDescription\" => \"需要相册权限来读取与保存你的成绩海报。\""
echo ""
echo "=================================================="
echo "🎉 祝您使用愉快！"
echo "=================================================="
