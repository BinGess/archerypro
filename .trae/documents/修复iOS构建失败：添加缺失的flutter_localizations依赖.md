# iOS构建失败修复计划：添加缺失依赖

根据错误日志 `Error: Couldn't resolve the package 'flutter_localizations' in 'package:flutter_localizations/flutter_localizations.dart'`，问题原因非常明确：`pubspec.yaml` 中缺少了 `flutter_localizations` 依赖，但在 `lib/main.dart` 中引用了它。

这是一个常见的 Flutter 项目配置错误，修复非常简单。

## 修复步骤

1.  **修改 `pubspec.yaml`**：
    *   在 `dependencies` 部分添加 `flutter_localizations`。
    *   该包是 Flutter SDK 的一部分，所以版本号通常设为 `sdk: flutter`。

2.  **执行 `flutter pub get`**：
    *   更新依赖配置，确保包被正确下载和链接。

3.  **验证**：
    *   重新运行 `flutter analyze` 或尝试构建，确保错误消失。

## 详细变更

**文件**: `pubspec.yaml`

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:  # 新增
    sdk: flutter          # 新增
  # ... 其他依赖保持不变
```

## 执行计划

1.  直接使用 `SearchReplace` 工具修改 `pubspec.yaml`。
2.  运行 `flutter pub get`。
3.  如果不放心，可以再运行一次 `flutter analyze` 确认无误。

这个修复将解决 `Unhandled exception: FileSystemException` 和 `Target kernel_snapshot_program failed` 等构建错误。

