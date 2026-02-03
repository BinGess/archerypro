import '../../models/training_session.dart';
import '../../models/ai_insight.dart';
import '../../models/ai_coach/ai_coach_result.dart';
import '../session_analysis_service.dart' as session_analysis;
import '../analytics_service.dart';

/// 本地 AI 服务 - 离线降级方案
/// 使用现有的 AnalyticsService 和 SessionAnalysisService 提供本地分析
class LocalAIService {
  final session_analysis.SessionAnalysisService _sessionAnalysisService;
  final AnalyticsService _analyticsService;

  LocalAIService({
    required session_analysis.SessionAnalysisService sessionAnalysisService,
    required AnalyticsService analyticsService,
  })  : _sessionAnalysisService = sessionAnalysisService,
        _analyticsService = analyticsService;

  /// 分析单次训练（本地降级）
  Future<AICoachResult> analyzeSession(
    TrainingSession session,
    List<TrainingSession> historicalSessions,
  ) async {
    // 使用现有的 SessionAnalysisService 生成洞察
    final sessionInsight = _sessionAnalysisService.generateSessionInsight(
      session,
      historicalSessions,
    );

    // 转换 SessionInsight 为 AIInsight 格式
    final aiInsight = _convertSessionInsightToAIInsight(sessionInsight, session);

    // 转换为 AICoachResult
    return AICoachResult.fromLocal(aiInsight, 'local');
  }

  /// 分析周期表现（本地降级）
  Future<AICoachResult> analyzePeriod(
    String period,
    List<TrainingSession> allSessions,
  ) async {
    // 使用 AnalyticsService 计算统计数据
    final stats = _analyticsService.calculateStatistics(
      sessions: allSessions,
      period: period,
    );

    // 生成基于统计的简单洞察
    final diagnosis = _generatePeriodDiagnosis(stats, allSessions);
    final suggestions = _generatePeriodSuggestions(stats, allSessions);

    return AICoachResult(
      diagnosis: diagnosis,
      strengths: _identifyStrengths(stats),
      weaknesses: _identifyWeaknesses(stats),
      suggestions: suggestions,
      trainingPlan: null, // 本地模式不生成训练计划
      encouragement: _generateEncouragement(stats),
      source: 'local',
      timestamp: DateTime.now(),
    );
  }

  /// 将 SessionInsight 转换为 AIInsight
  AIInsight _convertSessionInsightToAIInsight(
    dynamic sessionInsight,
    TrainingSession session,
  ) {
    // 注意：sessionInsight 是 SessionInsight 类型，但我们需要转换为 AIInsight
    // 根据 type 创建对应的 AIInsight
    final insightType = _mapSessionInsightType(sessionInsight.type);

    return AIInsight(
      id: 'local_${session.id}_${DateTime.now().millisecondsSinceEpoch}',
      type: insightType,
      title: sessionInsight.title,
      description: sessionInsight.message,
      icon: sessionInsight.icon,
      color: sessionInsight.color,
      priority: _mapSeverityToPriority(sessionInsight.severity),
    );
  }

  /// 映射 SessionInsight type 到 AIInsight InsightType
  InsightType _mapSessionInsightType(dynamic sessionType) {
    final typeString = sessionType.toString().split('.').last;
    switch (typeString) {
      case 'equipment':
        return InsightType.equipment;
      case 'endurance':
      case 'warmUp':
        return InsightType.drill;
      case 'stability':
        return InsightType.stability;
      case 'excellence':
        return InsightType.achievement;
      default:
        return InsightType.technique;
    }
  }

  /// 映射严重程度到优先级
  int _mapSeverityToPriority(dynamic severity) {
    final severityString = severity.toString().split('.').last;
    switch (severityString) {
      case 'high':
        return 5;
      case 'medium':
        return 3;
      case 'low':
        return 2;
      case 'positive':
        return 1;
      default:
        return 3;
    }
  }

  /// 生成周期诊断
  String _generatePeriodDiagnosis(dynamic stats, List<TrainingSession> sessions) {
    if (sessions.isEmpty) {
      return '本周期暂无训练数据，建议保持规律训练。';
    }

    final avgScore = stats.avgArrowScore;
    final consistency = stats.avgConsistency;
    final trend = stats.trend;

    String trendDesc = trend > 0 ? '上升' : (trend < 0 ? '下降' : '稳定');
    String performanceLevel = avgScore >= 9.0
        ? '优秀'
        : avgScore >= 8.0
            ? '良好'
            : avgScore >= 7.0
                ? '中等'
                : '需提升';

    return '本周期共完成${sessions.length}次训练，平均得分${avgScore.toStringAsFixed(2)}，'
        '表现水平为$performanceLevel。稳定性${consistency.toStringAsFixed(1)}%，'
        '趋势呈$trendDesc态势。';
  }

  /// 生成周期建议
  List<CoachingSuggestion> _generatePeriodSuggestions(
    dynamic stats,
    List<TrainingSession> sessions,
  ) {
    final suggestions = <CoachingSuggestion>[];

    // 基于平均分给建议
    if (stats.avgArrowScore < 7.0) {
      suggestions.add(CoachingSuggestion(
        category: 'technique',
        title: '加强基础技术训练',
        description: '当前平均分较低，建议回归基础动作训练，重点关注站姿、勾弦和释放动作的一致性。',
        priority: 5,
        actionSteps: [
          '每次训练前进行10分钟空拉练习',
          '减少射程，专注于动作质量而非分数',
          '录制视频分析自己的动作',
        ],
      ));
    }

    // 基于稳定性给建议
    if (stats.avgConsistency < 70.0) {
      suggestions.add(CoachingSuggestion(
        category: 'physical',
        title: '提升稳定性',
        description: '稳定性偏低，需要加强核心力量和射箭肌肉记忆。',
        priority: 4,
        actionSteps: [
          '增加核心力量训练（平板支撑、侧平板）',
          '进行盲射练习，培养肌肉记忆',
          '保持训练频率，建议每周至少3次',
        ],
      ));
    }

    // 基于趋势给建议
    if (stats.trend < -5.0) {
      suggestions.add(CoachingSuggestion(
        category: 'mental',
        title: '关注心态调整',
        description: '近期表现呈下降趋势，可能存在疲劳或心理压力。',
        priority: 4,
        actionSteps: [
          '适当休息，避免过度训练',
          '回顾最佳表现的训练日志，找回状态',
          '降低对自己的期望，享受射箭过程',
        ],
      ));
    }

    // 如果没有明显问题，给鼓励性建议
    if (suggestions.isEmpty) {
      suggestions.add(CoachingSuggestion(
        category: 'technique',
        title: '保持训练节奏',
        description: '当前表现良好，继续保持训练节奏和强度。',
        priority: 2,
        actionSteps: [
          '维持当前训练频率',
          '可以尝试增加训练距离或难度',
          '设定新的挑战目标',
        ],
      ));
    }

    return suggestions;
  }

  /// 识别优势
  List<String> _identifyStrengths(dynamic stats) {
    final strengths = <String>[];

    if (stats.avgArrowScore >= 8.5) {
      strengths.add('平均得分优秀，基础技术扎实');
    }

    if (stats.avgConsistency >= 75.0) {
      strengths.add('稳定性良好，动作一致性高');
    }

    if (stats.tenRingRate >= 30.0) {
      strengths.add('10环率出色，精准度高');
    }

    if (stats.trend > 5.0) {
      strengths.add('进步趋势明显，训练效果显著');
    }

    if (strengths.isEmpty) {
      strengths.add('保持规律训练，这是最大的优势');
    }

    return strengths;
  }

  /// 识别弱点
  List<String> _identifyWeaknesses(dynamic stats) {
    final weaknesses = <String>[];

    if (stats.avgArrowScore < 7.0) {
      weaknesses.add('平均得分偏低，需加强基础技术');
    }

    if (stats.avgConsistency < 65.0) {
      weaknesses.add('稳定性不足，动作一致性需改进');
    }

    if (stats.tenRingRate < 20.0) {
      weaknesses.add('10环率较低，精准度有待提升');
    }

    if (stats.trend < -5.0) {
      weaknesses.add('表现呈下降趋势，需调整训练方法');
    }

    if (weaknesses.isEmpty) {
      weaknesses.add('暂无明显弱点，继续保持');
    }

    return weaknesses;
  }

  /// 生成鼓励语
  String _generateEncouragement(dynamic stats) {
    if (stats.trend > 5.0) {
      return '进步很明显！继续保持这个训练节奏，你会越来越好！';
    } else if (stats.avgArrowScore >= 8.5) {
      return '表现非常出色！你已经达到了很高的水平，继续努力！';
    } else if (stats.trend < -5.0) {
      return '暂时的下滑不代表什么，调整好状态，你一定能重回巅峰！';
    } else {
      return '坚持就是胜利！每一次训练都是进步的积累！';
    }
  }
}
