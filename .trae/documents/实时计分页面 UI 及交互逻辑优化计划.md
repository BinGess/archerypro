# 功能调整计划：移除实时切换，改为设置页预设

根据你的需求，我们将对App进行以下调整，以优化空间利用率并简化计分逻辑。

## 1. 训练设置页面调整 (SessionSetupScreen)

**目标**：添加视图模式选择（列表视图/靶面视图）。

* **新增状态**：`_isTargetMode` (bool)，默认值为 `false` (列表视图)。

* **UI 变更**：

  * 在“训练场地”下方或“比赛模式”附近，新增一个设置项“计分视图”。

  * 提供两个选项：**列表模式** (List) 和 **靶面模式** (Target)。

* **持久化**：

  * 在 `_loadLastSettings` 中读取 `lastViewMode`。

  * 在 `_saveSettings` 中保存 `lastViewMode`。

* **参数传递**：

  * 修改 `startNewSession` 调用，或者直接在跳转到 `ScoringScreen` 前设置 `ScoringState` 的初始 `isTargetView` 状态。

  * 由于 `ScoringNotifier.startNewSession` 目前不接受视图参数，我们需要修改该方法，或者在 `ScoringScreen` 初始化时读取这个配置。

  * **最佳方案**：修改 `ScoringNotifier.startNewSession`，增加 `isTargetMode` 参数，并在初始化 `ScoringState` 时直接应用。

## 2. 实时计分页面调整 (ScoringScreen)

**目标**：移除视图切换按钮，固定显示模式。

* **UI 变更**：

  * **移除**：顶部的“列表视图/靶面视图”切换开关 (Toggle Button)。

  * **布局调整**：原本显示切换开关的区域可以节省下来，用于展示更多信息或直接移除以增加列表可视区域。

* **逻辑变更**：

  * 移除 `_buildToggleBtn` 相关代码。

  * 页面加载时，直接使用 `scoringState.isTargetView` 决定显示 `_buildKeypad` (底部键盘) 还是 `_buildTargetPanel` (底部靶面)。

## 3. 状态管理调整 (ScoringNotifier)

* **修改**：`startNewSession` 方法增加 `bool isTargetMode` 参数。

* **初始化**：在创建 `ScoringState` 时，将 `isTargetView` 设置为传入的值。

* **移除**：`toggleView` 方法（因为不再需要在计分过程中切换）。

***

**执行步骤**：

1. **修改** **`ScoringNotifier`**：更新 `startNewSession` 签名，支持传入视图模式。
2. **修改** **`SessionSetupScreen`**：

   * 添加视图选择 UI。

   * 实现设置的保存与加载。

   * 在开始训练时传入选择的模式。
3. **修改** **`ScoringScreen`**：

   * 移除切换开关 UI。

   * 清理相关冗余代码。

