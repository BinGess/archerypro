# Archery Pro Tracker - 架构文档

## 📐 架构概览

这个项目采用 **Clean Architecture + MVVM + Riverpod** 架构模式，确保代码的可维护性、可测试性和可扩展性。

## 🏗️ 项目结构

```
lib/
├── main.dart                        # 应用入口（已集成Riverpod）
├── theme/                           # 主题系统
│   └── app_colors.dart
├── widgets/                         # 通用UI组件
│   └── common_widgets.dart
├── screens/                         # UI展示层
│   ├── dashboard_screen.dart         # 原始UI（待连接）
│   ├── dashboard_screen_with_logic.dart  # 示例：已连接逻辑层
│   ├── analysis_screen.dart
│   ├── scoring_screen.dart
│   └── details_screen.dart
├── models/                          # 数据模型层 ✅ 已完成
│   ├── arrow.dart                    # 单支箭模型
│   ├── end.dart                      # 一组箭模型(3-6支)
│   ├── equipment.dart                # 装备模型
│   ├── training_session.dart         # 训练场次模型
│   ├── statistics.dart               # 统计数据模型
│   └── ai_insight.dart               # AI建议模型
├── services/                        # 业务逻辑层 ✅ 已完成
│   ├── scoring_service.dart          # 计分逻辑
│   ├── session_service.dart          # 场次管理
│   ├── storage_service.dart          # 本地存储(Hive)
│   └── analytics_service.dart        # 数据分析和AI
├── providers/                       # 状态管理层(Riverpod) ✅ 已完成
│   ├── scoring_provider.dart         # 实时计分状态
│   ├── session_provider.dart         # 场次列表状态
│   └── analytics_provider.dart       # 分析统计状态
└── utils/                           # 工具类 ✅ 已完成
    └── constants.dart                # 应用常量
```

## ✅ 已完成的功能

### 1. 数据模型层 (Models)
所有数据模型已完成，包括：
- **Arrow**: 单支箭的数据（分数、位置、类型）
- **End**: 一组箭的集合（通常6支）
- **Equipment**: 装备信息（弓类型、箭型号等）
- **TrainingSession**: 完整训练场次（包含多个ends、统计数据）
- **Statistics**: 分析统计数据（平均分、趋势、热力图数据）
- **AIInsight**: AI教练建议

### 2. 业务逻辑层 (Services)
- **ScoringService**: 计分逻辑和验证
- **SessionService**: 训练场次的CRUD操作
- **StorageService**: 基于Hive的本地数据持久化
- **AnalyticsService**: 统计分析和AI建议生成

### 3. 状态管理层 (Providers)
- **ScoringProvider**: 管理实时计分状态
- **SessionProvider**: 管理训练场次列表
- **AnalyticsProvider**: 管理分析和统计数据

### 4. 基础设施
- ✅ Riverpod已集成到main.dart
- ✅ Hive存储已初始化
- ✅ 所有依赖包已添加到pubspec.yaml

## 🚀 快速开始

### 1. 安装依赖

```bash
flutter pub get
```

### 2. 运行代码生成（可选）

如果你修改了模型类，需要重新生成序列化代码：

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. 运行应用

```bash
flutter run
```

## 📖 如何使用

### 示例1: 读取训练场次列表

查看 `lib/screens/dashboard_screen_with_logic.dart`：

```dart
class DashboardScreenWithLogic extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听状态变化
    final sessionState = ref.watch(sessionProvider);

    return ListView.builder(
      itemCount: sessionState.sessions.length,
      itemBuilder: (context, index) {
        final session = sessionState.sessions[index];
        return ListTile(
          title: Text(session.scoreDisplay),
          subtitle: Text(session.equipment.bowTypeDisplay),
        );
      },
    );
  }
}
```

### 示例2: 开始新的计分会话

```dart
// 在按钮点击时
ref.read(scoringProvider.notifier).startNewSession(
  equipment: Equipment(bowType: BowType.compound),
  distance: 18.0,
  targetFaceSize: 40,
);

// 添加箭分数
ref.read(scoringProvider.notifier).addArrow(10);

// 保存会话
await ref.read(scoringProvider.notifier).saveSession();
```

### 示例3: 获取统计数据

```dart
final analyticsState = ref.watch(analyticsProvider);

Text('平均分: ${analyticsState.statistics.avgArrowScore.toStringAsFixed(1)}');
Text('趋势: ${analyticsState.statistics.trendDisplay}');
```

## 🔧 下一步工作

### 需要连接UI到逻辑层的屏幕：

1. **ScoringScreen** (计分屏幕)
   - 使用 `scoringProvider` 管理状态
   - 调用 `addArrow()` 添加分数
   - 调用 `saveSession()` 保存场次

2. **DashboardScreen** (历史记录)
   - 使用 `sessionProvider` 获取场次列表
   - 使用 `analyticsProvider` 显示统计数据

3. **AnalysisScreen** (性能分析)
   - 使用 `analyticsProvider` 获取统计和AI建议
   - 显示热力图和趋势图

4. **DetailsScreen** (详情页面)
   - 使用 `selectedSessionProvider` 获取选中的场次
   - 显示详细的end和arrow数据

### 具体步骤：

#### 1. 将StatelessWidget改为ConsumerWidget

```dart
// 之前
class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) { ... }
}

// 之后
class DashboardScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) { ... }
}
```

#### 2. 读取Provider数据

```dart
final sessionState = ref.watch(sessionProvider);
final sessions = sessionState.sessions;
```

#### 3. 调用Provider方法

```dart
// 刷新数据
ref.read(sessionProvider.notifier).refresh();

// 删除场次
ref.read(sessionProvider.notifier).deleteSession(id);
```

## 📊 数据流

```
用户操作 (UI)
    ↓
Consumer Widget
    ↓
Provider (ref.read/ref.watch)
    ↓
Service (业务逻辑)
    ↓
Storage (Hive持久化)
```

## 🎯 架构优势

### ✅ 分层清晰
- **UI层**: 只负责展示，不包含业务逻辑
- **State层**: 管理应用状态
- **Service层**: 处理业务逻辑
- **Model层**: 定义数据结构

### ✅ 易于测试
每一层都可以独立测试：
```dart
// 测试Service
test('ScoringService calculates total correctly', () {
  final service = ScoringService();
  final arrow = service.createArrow(10);
  expect(arrow.pointValue, equals(10));
});
```

### ✅ 可扩展
未来可以轻松添加：
- 云端同步
- 社交功能
- 高级AI分析
- 多用户支持

### ✅ 类型安全
完全使用 Dart 的类型系统，编译时就能发现错误

## 🛠️ 常用命令

```bash
# 安装依赖
flutter pub get

# 运行代码生成
flutter pub run build_runner build

# 清理并重新生成
flutter pub run build_runner build --delete-conflicting-outputs

# 运行应用
flutter run

# 运行测试
flutter test

# 分析代码
flutter analyze
```

## 📚 技术栈

- **Flutter** 3.0+
- **Riverpod** 2.4.0 - 状态管理
- **Hive** 2.2.3 - 本地数据库
- **json_serializable** - JSON序列化
- **uuid** - ID生成
- **intl** - 日期格式化

## 🤝 贡献指南

在添加新功能时，请遵循以下步骤：

1. 在 `models/` 中定义数据模型
2. 在 `services/` 中实现业务逻辑
3. 在 `providers/` 中创建状态管理
4. 在 `screens/` 中连接UI

## ❓ 常见问题

**Q: 为什么选择Riverpod而不是Provider?**
A: Riverpod提供编译时安全、无需BuildContext、更好的测试支持。

**Q: 为什么选择Hive而不是SQLite?**
A: Hive是纯Dart实现，无需原生代码，性能更好，更易用。

**Q: 如何添加新的统计指标?**
A: 在 `AnalyticsService` 中添加计算逻辑，在 `Statistics` 模型中添加字段。

## 📞 支持

如有问题，请查阅：
- Flutter文档: https://flutter.dev/docs
- Riverpod文档: https://riverpod.dev
- Hive文档: https://docs.hivedb.dev

---

**祝你编码愉快！🎯**
