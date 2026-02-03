## 问题分析
### 1) 首页时间块视觉
当前首页历史条目的日期使用纯色方块（[dashboard_screen.dart](file:///Users/bytedance/Documents/Code/archerypro/lib/screens/dashboard_screen.dart) 的 `_buildHistoryItem`），视觉信息密度偏低；可以用“日历卡片”样式增强识别。

### 2) 计分页靶面模式点击会自动新增一组
靶面点击入口 `_handleTargetTap`（[scoring_screen.dart](file:///Users/bytedance/Documents/Code/archerypro/lib/screens/scoring_screen.dart#L645-L728)）目前不会像键盘模式 `_addScore` 一样做 `maxEnds` 边界拦截，因此当最后一组完成后焦点推进到 `focusedEndIndex == maxEnds` 时，再点击靶面会走到 Provider 的 `addArrow` 并触发“创建新 end”（[scoring_provider.dart](file:///Users/bytedance/Documents/Code/archerypro/lib/providers/scoring_provider.dart#L148-L170)），导致“无意新增一组”。

### 3) 详情页热力图靶面偏左
详情页的 `_buildChartCard` 使用 `Column(crossAxisAlignment: CrossAxisAlignment.start)`，并且直接放置固定宽高的 `HeatmapWithCenter(size: 280)`，所以组件会默认贴左摆放，视觉上靶面偏左（[details_screen.dart](file:///Users/bytedance/Documents/Code/archerypro/lib/screens/details_screen.dart#L270-L324)）。

## 修改计划
### 1) 首页 ITEM 时间块改成“日历图标”风格
- 文件： [dashboard_screen.dart](file:///Users/bytedance/Documents/Code/archerypro/lib/screens/dashboard_screen.dart)
- 改动点：`_buildHistoryItem` 里日期 Box（当前纯色 Container）
- 实现方式（不引入图片资源）：用 `Stack`/`Column` 组合出日历卡片：
  - 外层白底 + 细边框（更像日历纸）
  - 顶部一条主色“日历头”横条
  - 月份缩写/中文月放上方，小号；日期数字放中间，大号
  - 可选：顶部两个小圆点模拟装订孔

### 2) 靶面模式：最后一组完成后点击靶面无效（只允许“再来一组”新增）
- 文件：
  - [scoring_screen.dart](file:///Users/bytedance/Documents/Code/archerypro/lib/screens/scoring_screen.dart)
  - [scoring_provider.dart](file:///Users/bytedance/Documents/Code/archerypro/lib/providers/scoring_provider.dart)
- 改动点：
  1. 在 `_handleTargetTap` 最前面增加与 `_addScore` 一致的边界判断：
     - 当 `focusedEndIndex >= maxEnds`（典型场景：最后一组填满后自动推进到下一组）时直接 return，不调用 `addArrow`。
  2. 在 Provider 的 `addArrow` 里补一层防线：
     - 若本次输入会触发创建新 end（`focusedEndIndex == currentEnds.length`）且 `focusedEndIndex >= maxEnds`，直接 return false。
- 预期效果：
  - 最后一组打完后继续点靶面不会新增一组。
  - 点击“再来一组”按钮会 `maxEnds + 1`（现有逻辑），之后靶面点击才允许新增下一组。

### 3) 详情页热力图居中
- 文件：[details_screen.dart](file:///Users/bytedance/Documents/Code/archerypro/lib/screens/details_screen.dart)
- 改动点：`_buildChartCard` 的 `child` 渲染处。
- 实现方式：把 `child` 包一层 `Center`（或 `Align(alignment: Alignment.center)`），确保固定宽高的热力图组件在卡片内居中；不改动文本的左对齐布局。

## 验证方式
- 运行静态检查：`flutter analyze`（确认无新增 error）。
- 手动验证：
  - 首页：日期块呈现日历风格并对齐正常。
  - 计分靶面模式：最后一组完成后连续点击靶面不新增组；点击“再来一组”后才新增。
  - 详情页：热力图靶面在卡片中水平居中。