#!/bin/bash

echo "════════════════════════════════════════════════════════════"
echo "  iOS 权限修复 - 自动重新编译脚本"
echo "════════════════════════════════════════════════════════════"
echo ""

# 检查是否在正确的目录
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ 错误：请在项目根目录运行此脚本"
    exit 1
fi

echo "📍 当前目录: $(pwd)"
echo ""

# 第1步：清理Flutter缓存
echo "🧹 第1步：清理Flutter构建缓存..."
flutter clean
if [ $? -ne 0 ]; then
    echo "❌ flutter clean 失败"
    exit 1
fi
echo "✅ Flutter缓存已清理"
echo ""

# 第2步：重新获取依赖
echo "📦 第2步：重新获取依赖..."
flutter pub get
if [ $? -ne 0 ]; then
    echo "❌ flutter pub get 失败"
    exit 1
fi
echo "✅ 依赖已获取"
echo ""

# 第3步：清理iOS Pods缓存
echo "🗑️  第3步：清理iOS Pods缓存..."
cd ios
if [ -d "Pods" ]; then
    rm -rf Pods
    echo "   - 已删除 Pods 目录"
fi
if [ -f "Podfile.lock" ]; then
    rm -f Podfile.lock
    echo "   - 已删除 Podfile.lock"
fi
if [ -d "build" ]; then
    rm -rf build
    echo "   - 已删除 build 目录"
fi
echo "✅ iOS缓存已清理"
echo ""

# 第4步：重新安装Pods
echo "📥 第4步：重新安装Pods..."
pod install --repo-update
if [ $? -ne 0 ]; then
    echo "❌ pod install 失败"
    echo "   提示：如果遇到网络问题，可以尝试："
    echo "   pod install --verbose"
    cd ..
    exit 1
fi
echo "✅ Pods已安装"
cd ..
echo ""

# 第5步：提醒用户卸载App
echo "════════════════════════════════════════════════════════════"
echo "⚠️  重要提醒"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "在继续之前，请先在您的iOS设备上卸载旧版App："
echo ""
echo "  1️⃣  在设备上找到「射箭专业版」App"
echo "  2️⃣  长按App图标"
echo "  3️⃣  选择「删除App」或「移除App」"
echo "  4️⃣  确认删除"
echo ""
echo "完成后按任意键继续..."
read -n 1 -s
echo ""

# 第6步：重新编译
echo "🔨 第6步：开始重新编译..."
echo ""
echo "选择编译模式："
echo "  1) Release模式（推荐，性能更好）"
echo "  2) Debug模式（可以调试）"
echo ""
read -p "请输入选项 (1 或 2): " mode

if [ "$mode" = "1" ]; then
    echo ""
    echo "🚀 正在以Release模式编译..."
    flutter run --release
elif [ "$mode" = "2" ]; then
    echo ""
    echo "🐛 正在以Debug模式编译..."
    flutter run
else
    echo "❌ 无效选项，默认使用Debug模式"
    flutter run
fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo "✅ 编译完成！"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "📝 测试步骤："
echo "  1. 打开App并完成一次训练"
echo "  2. 在结果页点击「保存到相册」"
echo "  3. 应该会弹出权限请求弹窗"
echo "  4. 点击「允许」"
echo "  5. 照片应该成功保存到相册"
echo ""
echo "🔍 验证："
echo "  - 打开「设置」>「隐私与安全性」>「照片」"
echo "  - 应该能看到「射箭专业版」"
echo ""
echo "════════════════════════════════════════════════════════════"
