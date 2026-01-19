# 🚀 快速开始指南

## 📱 在真机上运行 Archery Pro Tracker

### 前置要求

- Flutter SDK 3.0+ 已安装
- Android Studio / Xcode (取决于你的测试设备)
- 连接的真机或模拟器

### 步骤1: 克隆项目

```bash
git clone <your-repo-url>
cd archerypro
git checkout claude/plan-logic-architecture-4MDgy
```

### 步骤2: 安装依赖

```bash
flutter pub get
```

### 步骤3: (可选) 生成代码

如果遇到编译错误，运行代码生成器：

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 步骤4: 连接设备

确保你的设备已连接并被识别：

```bash
flutter devices
```

### 步骤5: 运行应用

```bash
flutter run
```

或者在 Android Studio / VS Code 中：
1. 打开项目文件夹
2. 等待依赖索引完成
3. 选择目标设备
4. 点击 Run 按钮 ▶️

---

## ✅ 当前进度

### 已完成 ✓
- ✅ **完整的逻辑层架构** (Models, Services, Providers)
- ✅ **DashboardScreen 已连接** - 显示真实数据
  - 统计卡片（场次数、平均分、趋势）
  - 训练历史列表
  - 月度目标进度条
  - 刷新功能

- ✅ **示例数据生成器** - 首次启动自动生成5个示例训练场次
- ✅ **本地数据持久化** (Hive)
- ✅ **状态管理** (Riverpod)

### UI 状态

| 屏幕 | 状态 | 说明 |
|------|------|------|
| Dashboard (History) | ✅ 已连接 | 完全功能，显示真实数据 |
| Analysis (Stats) | 🎨 原UI保留 | 显示静态UI，待连接 |
| Scoring | 🎨 原UI保留 | 显示静态UI，待连接 |
| Details | 🎨 原UI保留 | 显示静态UI，待连接 |

---

## 🎯 功能演示

### Dashboard Screen

运行应用后，你将看到：

1. **统计摘要卡片**
   - 总训练场次数
   - 本月射箭数量
   - 平均分数
   - 性能趋势 (百分比)
   - 月度目标进度条

2. **训练历史列表**
   - 显示最近10个训练场次
   - 最佳记录高亮显示
   - 显示日期、分数、弓型、距离
   - 准确率百分比
   - 点击可查看详情（待实现）

3. **刷新按钮**
   - 右上角刷新图标
   - 重新加载所有数据

---

## 🏗️ 架构说明

### 数据流

```
App Start
    ↓
Initialize Storage (Hive)
    ↓
Generate Sample Data (首次启动)
    ↓
Load Sessions into Provider
    ↓
Calculate Statistics
    ↓
Display in UI
```

### 示例数据

应用首次启动时会自动生成 **5个示例训练场次**：

- **场次1** (2天前): 30箭，高分场次
- **场次2** (5天前): 30箭，中等表现
- **场次3** (10天前): 30箭，稳定发挥
- **场次4** (15天前): 30箭，Recurve弓
- **场次5** (20天前): 30箭，高分场次

### 数据存储

- **位置**: 应用本地存储 (Hive)
- **持久化**: 数据在应用重启后保持
- **清除**: 卸载应用会清除所有数据

---

## 🔧 开发建议

### 如果遇到编译错误

1. **缺少生成文件错误**:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

2. **依赖冲突**:
   ```bash
   flutter clean
   flutter pub get
   ```

3. **Hive 初始化错误**:
   - 确保 `main()` 函数是 async
   - 检查 `StorageService.initialize()` 是否被调用

### 调试模式

在 `main.dart` 中添加调试输出：

```dart
Future<void> _initializeApp() async {
  print('🚀 Initializing app...');

  final sessionService = ref.read(sessionServiceProvider);
  final scoringService = ref.read(scoringServiceProvider);
  final generator = SampleDataGenerator(sessionService, scoringService);

  await generator.generateSampleSessions();
  print('✅ Sample data generated');

  await ref.read(sessionProvider.notifier).loadSessions();
  print('✅ Sessions loaded');

  setState(() {
    _isInitialized = true;
  });
}
```

---

## 📂 项目结构

```
lib/
├── main.dart                    # 应用入口 ✅ 已更新
├── models/                      # 数据模型 ✅ 完成
│   ├── arrow.dart
│   ├── end.dart
│   ├── equipment.dart
│   ├── training_session.dart
│   ├── statistics.dart
│   └── ai_insight.dart
├── services/                    # 业务逻辑 ✅ 完成
│   ├── scoring_service.dart
│   ├── session_service.dart
│   ├── storage_service.dart
│   └── analytics_service.dart
├── providers/                   # 状态管理 ✅ 完成
│   ├── scoring_provider.dart
│   ├── session_provider.dart
│   └── analytics_provider.dart
├── screens/                     # UI屏幕
│   ├── dashboard_screen.dart    # ✅ 已连接
│   ├── analysis_screen.dart     # 🎨 静态UI
│   ├── scoring_screen.dart      # 🎨 静态UI
│   └── details_screen.dart      # 🎨 静态UI
├── utils/                       # 工具类 ✅ 完成
│   ├── constants.dart
│   └── sample_data.dart         # ✅ 新增
└── theme/
    └── app_colors.dart
```

---

## 📖 API 快速参考

### 读取训练场次

```dart
// 在 ConsumerWidget 中
final sessionState = ref.watch(sessionProvider);
final sessions = sessionState.sessions;
final recentSessions = sessionState.recentSessions; // 最近10个
```

### 读取统计数据

```dart
final analyticsState = ref.watch(analyticsProvider);
final stats = analyticsState.statistics;

print('平均分: ${stats.avgArrowScore}');
print('趋势: ${stats.trendDisplay}');
print('本月箭数: ${stats.currentMonthArrows}');
```

### 刷新数据

```dart
// 刷新场次列表
ref.read(sessionProvider.notifier).refresh();

// 刷新分析数据
ref.read(analyticsProvider.notifier).refreshAnalytics();
```

---

## 🎯 下一步计划

1. **Analysis Screen** - 连接统计和AI建议
2. **Scoring Screen** - 实现实时计分功能
3. **Details Screen** - 显示单个场次详情
4. **数据导出** - 添加数据导出功能
5. **云同步** (可选) - 未来扩展

---

## 💡 提示

- Dashboard 右上角有**刷新按钮**可以重新加载数据
- 点击训练记录卡片会设置 `selectedSessionProvider`（详情屏幕会用到）
- 示例数据只在首次启动时生成，不会重复生成
- 所有数据存储在本地，卸载应用会清除

---

## ❓ 常见问题

**Q: 为什么没有看到数据？**
A: 检查 `_initializeApp()` 是否成功执行。查看控制台日志。

**Q: 如何清除示例数据？**
A: 卸载并重新安装应用，或在代码中调用 `storageService.clearAllSessions()`

**Q: 可以添加自己的训练数据吗？**
A: 可以！使用 Scoring Screen（待连接）或通过 `sessionService.saveSession()` API

**Q: 数据存在哪里？**
A: 使用 Hive 存储在应用沙盒中，路径由系统管理

---

**祝你测试愉快！🏹**

有问题请查阅 `ARCHITECTURE.md` 获取详细架构文档。
