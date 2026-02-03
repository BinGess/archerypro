import 'package:intl/intl.dart';
import 'app_localizations.dart';

/// Chinese (Simplified) localizations
class AppLocalizationsZh extends AppLocalizations {
  // Common
  @override
  String get appName => '射箭追踪器';

  @override
  String get ok => '确定';

  @override
  String get cancel => '取消';

  @override
  String get save => '保存';

  @override
  String get delete => '删除';

  @override
  String get edit => '编辑';

  @override
  String get confirm => '确认';

  @override
  String get back => '返回';

  @override
  String get settings => '设置';

  @override
  String get language => '语言';

  // Bottom Navigation
  @override
  String get navHome => '首页';

  @override
  String get navAdd => '添加';

  @override
  String get navStatistics => '统计';

  // Dashboard
  @override
  String get dashboard => '首页';

  @override
  String get refresh => '刷新';

  @override
  String get noTrainingRecords => '暂无训练记录';

  @override
  String get clickAddToStart => '点击"添加"开始第一次训练';

  @override
  String get highScore => '最高纪录';

  @override
  String get arrows => '支箭';

  @override
  String get totalScore => '总分';

  @override
  String get averageScore => '平均分';

  @override
  String get xCount => 'X环数';

  @override
  String get tenCount => '10环数';

  // Scoring
  @override
  String get scoring => '计分';

  @override
  String get endNumber => '组';

  @override
  String get arrowNumber => '支';

  @override
  String get miss => '脱靶';

  @override
  String get removeScore => '移除成绩';

  @override
  String get completeSession => '完成成绩';

  @override
  String get sessionSaved => '训练已保存！';

  @override
  String get endCompleted => '组完成';

  @override
  String get sessionCompleted => '训练完成！';

  // Session Setup
  @override
  String get newTraining => '新建训练';

  @override
  String get distance => '距离';

  @override
  String get meters => '米';

  @override
  String get targetFaceSize => '靶面尺寸';

  @override
  String get bowType => '弓型';

  @override
  String get arrowsPerEnd => '每组箭数';

  @override
  String get numberOfEnds => '组数';

  @override
  String get startTraining => '开始训练';

  // Bow Types
  @override
  String get recurveBow => '反曲弓';

  @override
  String get compoundBow => '复合弓';

  @override
  String get traditionalBow => '传统弓';

  @override
  String get barebow => '光弓';

  // Analysis
  @override
  String get analysis => '分析';

  @override
  String get statistics => '统计';

  @override
  String get trends => '趋势';

  @override
  String get heatmap => '热力图';

  @override
  String get scoreDistribution => '分数分布';

  @override
  String get performanceAnalysis => '表现分析';

  @override
  String get consistency => '稳定性';

  @override
  String get accuracy => '准确度';

  @override
  String get precision => '精准度';

  // Details
  @override
  String get sessionDetails => '训练详情';

  @override
  String get date => '日期';

  @override
  String get equipment => '装备';

  @override
  String get scorePercentage => '得分率';

  @override
  String get endBreakdown => '分组详情';

  // Settings
  @override
  String get settingsTitle => '设置';

  @override
  String get languageSettings => '语言设置';

  @override
  String get selectLanguage => '选择语言';

  @override
  String get chinese => '简体中文';

  @override
  String get english => 'English';

  @override
  String get systemDefault => '跟随系统';

  @override
  String get about => '关于';

  @override
  String get version => '版本';

  @override
  String get privacyPolicy => '隐私政策';

  @override
  String get termsOfService => '服务条款';

  // Messages
  @override
  String get loading => '加载中...';

  @override
  String get noData => '暂无数据';

  @override
  String get error => '错误';

  @override
  String get success => '成功';

  // Date Formats
  @override
  String formatDate(DateTime date) {
    return DateFormat('yyyy年M月d日').format(date);
  }

  @override
  String formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  // Time Periods
  @override
  String get period7Days => '7天';
  @override
  String get period1Month => '30天';
  @override
  String get periodCurrentYear => '本年';
  @override
  String get periodAll => '全部';

  // Analysis Charts
  @override
  String get growthTrendChart => '成长趋势图';
  @override
  String get growthTrendSubtitle => '分数走势 + 训练量';
  @override
  String get noDataForPeriod => '所选时段暂无数据';
  @override
  String get stabilityRadarChart => '稳定性雷达图';
  @override
  String get needMoreData => '需要更多训练数据';
  @override
  String get stabilityRadarSubtitle => '6维度能力评估';
  @override
  String get quadrantRadarChart => '顽固偏差诊断';
  @override
  String get quadrantRadarSubtitle => '9环以下箭支方向分布';
  @override
  String get allArrowsGood => '太棒了！所有箭支都在9环及以上';

  // Analysis Insights & AI
  @override
  String get aiPeriodAnalysis => 'AI 周期分析';
  @override
  String get aiCoachAdvice => 'AI 教练建议';
  @override
  String get keepTrainingForInsights => '继续训练以获取AI周期分析建议';
  @override
  String get actionableTip => '可执行建议';

  // Insight Messages
  @override
  String get insightPlateauTitle => '平台期识别';
  @override
  String get insightPlateauMessage => '近期成绩进入平台期，建议尝试新的训练方法或技术调整以突破瓶颈。';
  @override
  String get insightVolumeWarningTitle => '训练量下降预警';
  @override
  String insightVolumeWarningMessage(String decline) => '本周期训练量较上周期下降$decline%，建议增加训练频次或进行恢复性训练。';
  @override
  String get insightAdvancementTitle => '进阶建议';
  @override
  String insightAdvancementMessage(String rate) => '10环率达到$rate%且稳定性优秀，建议尝试增加射击距离或提高难度。';
  @override
  String get insightChronicBiasTitle => '顽固偏差诊断';
  @override
  String insightChronicBiasMessage(String percent, String direction) => '脱靶箭支$percent%偏向$direction，建议针对性调整动作或器材。';
  @override
  String get insightExcellenceTitle => '稳定性优秀';
  @override
  String insightExcellenceMessage(String consistency) => '稳定性达到$consistency%，动作一致性表现优异！';
  @override
  String insightGroupingTitle(String tendency) => '分组倾向：$tendency';
  @override
  String insightGroupingMessage(String tendency) => '你的箭组倾向于靶心$tendency方。请练习光靶，专注于对齐和撒放。';

  // Directions
  @override
  String get directionTopLeft => '左上';
  @override
  String get directionTopRight => '右上';
  @override
  String get directionBottomLeft => '左下';
  @override
  String get directionBottomRight => '右下';
  @override
  String get directionTop => '偏上';
  @override
  String get directionBottom => '偏下';
  @override
  String get directionLeft => '偏左';
  @override
  String get directionRight => '偏右';

  // Chart Titles
  @override
  String get visualization => '数据可视化';
  @override
  String get heatmapTitle => '本次落点热力图';
  @override
  String get heatmapSubtitle => '所有箭支位置分布 + 几何中心';
  @override
  String get endTrendTitle => '组间走势图';
  @override
  String get endTrendSubtitle => '各组平均分趋势';
  @override
  String get scoreDistTitle => '分数分布';
  @override
  String get scoreDistSubtitle => '各环数箭支统计';

  // Dialogs
  @override
  String get deleteRecordTitle => '删除记录';
  @override
  String get deleteRecordMessage => '确定要删除这条训练记录吗？此操作无法撤销。';
  @override
  String get recordDeleted => '记录已删除';
  @override
  String get featureInDev => '编辑功能开发中';

  // Dashboard
  @override
  String get sessions => '次训练';
  @override
  String monthlyArrowsMessage(String count) => '本月已射 $count 支箭';
  @override
  String get average => '平均';
  @override
  String get trend => '趋势';
  @override
  String monthlyGoalMessage(String count) => '月度目标：$count 支箭';
  @override
  String get noRecords => '暂无训练记录';
  @override
  String get clickToAdd => '点击"添加"开始第一次训练';
  @override
  String showingRecentMessage(String count) => '显示最近 $count 次训练';
  
  @override
  String get totalArrows => '总箭数';

  // Bow Types
  @override
  String get bowCompound => '复合弓';
  @override
  String get bowRecurve => '反曲弓';
  @override
  String get bowBarebow => '光弓';
  @override
  String get bowLongbow => '长弓';
  
  // Units
  @override
  String get unitArrows => '支箭';

  // AI Coach
  @override
  String get aiCoachAnalysis => 'AI 教练分析';
  @override
  String get aiCoachDeepAnalysis => 'AI 教练深度分析';
  @override
  String get aiCoachPeriodAnalysis => 'AI 周期分析';
  @override
  String get aiCoachBasedOnData => '基于训练数据的专业建议';
  @override
  String get aiCoachGetProfessionalAdvice => '获取更详细的专业建议和训练计划';
  @override
  String get aiCoachAnalyzeButton => '分析';
  @override
  String get aiCoachDeepAnalyzeButton => '深度分析';
  @override
  String get aiCoachReanalyzeButton => '重新分析';
  @override
  String get aiCoachAnalyzing => 'AI 教练分析中...';
  @override
  String get aiCoachAnalyzingPeriod => '正在分析周期表现...';
  @override
  String get aiCoachAnalysisComplete => '分析完成';
  @override
  String get aiCoachAnalysisFailed => '分析失败';
  @override
  String get aiCoachNetworkError => '网络连接失败，请检查网络后重试';
  @override
  String get aiCoachClickToAnalyze => '点击"分析"按钮获取 AI 教练的专业建议';
  @override
  String get aiCoachClickForDeepAnalysis => '点击"深度分析"获取 AI 教练的全面建议和训练计划';
  @override
  String get aiCoachDismiss => '关闭';
  @override
  String get aiCoachClose => '关闭';
  @override
  String get aiCoachDiagnosis => '核心诊断';
  @override
  String get aiCoachStrengths => '优势';
  @override
  String get aiCoachWeaknesses => '待改进';
  @override
  String get aiCoachSuggestions => '改进建议';
  @override
  String get aiCoachTrainingPlan => '训练计划';
  @override
  String get aiCoachEncouragement => '鼓励';
  @override
  String get aiCoachSourceOnline => 'AI 在线分析';
  @override
  String get aiCoachSourceLocal => '本地分析';
  @override
  String get aiCoachSourceOffline => '离线模式';
  @override
  String get aiCoachCategoryTechnique => '技术';
  @override
  String get aiCoachCategoryPhysical => '体能';
  @override
  String get aiCoachCategoryMental => '心理';
  @override
  String get aiCoachCategoryEquipment => '器材';
  @override
  String get aiCoachCategoryGeneral => '综合';
  @override
  String get aiCoachActionSteps => '行动步骤';
  @override
  String get aiCoachPhaseFocus => '训练重点';
  @override
  String get aiCoachDrills => '训练项目';
  @override
  String get aiCoachDays => '天';
  @override
  String get aiCoachArrowsUnit => '支';
  @override
  String get aiCoachPhase => '阶段';
  @override
  String get aiCoachSuggestionsCount => '条';
}
