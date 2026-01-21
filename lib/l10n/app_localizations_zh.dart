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
}
