import '../ai_insight.dart';

/// AI 教练分析结果统一模型
class AICoachResult {
  final String diagnosis;              // 核心诊断
  final List<String> strengths;        // 优势点
  final List<String> weaknesses;       // 待改进点
  final List<CoachingSuggestion> suggestions;  // 改进建议
  final TrainingPlan? trainingPlan;    // 训练计划（可选）
  final String? encouragement;         // 鼓励语
  final String source;                 // 来源：'coze' 或 'local'
  final DateTime timestamp;            // 分析时间
  final String? rawResponse;           // 原始响应（用于调试）

  AICoachResult({
    required this.diagnosis,
    required this.strengths,
    required this.weaknesses,
    required this.suggestions,
    this.trainingPlan,
    this.encouragement,
    required this.source,
    required this.timestamp,
    this.rawResponse,
  });

  /// 从 Coze AI 响应创建结果
  factory AICoachResult.fromCozeJson(
    Map<String, dynamic> json,
    String source,
  ) {
    return AICoachResult(
      diagnosis: json['诊断'] ?? json['diagnosis'] ?? '',
      strengths: List<String>.from(json['优势'] ?? json['strengths'] ?? []),
      weaknesses: List<String>.from(json['弱点'] ?? json['weaknesses'] ?? []),
      suggestions: (json['建议'] ?? json['suggestions'] ?? [])
          .map<CoachingSuggestion>(
            (s) => CoachingSuggestion.fromJson(s),
          )
          .toList(),
      trainingPlan: json['训练计划'] != null || json['trainingPlan'] != null
          ? TrainingPlan.fromJson(json['训练计划'] ?? json['trainingPlan'])
          : null,
      encouragement: json['鼓励'] ?? json['encouragement'],
      source: source,
      timestamp: DateTime.now(),
      rawResponse: json.toString(),
    );
  }

  /// 从本地 AI 结果创建
  factory AICoachResult.fromLocal(
    AIInsight insight,
    String source,
  ) {
    return AICoachResult(
      diagnosis: insight.description,
      strengths: [],
      weaknesses: [],
      suggestions: [
        CoachingSuggestion(
          category: _mapInsightTypeToCategory(insight.type),
          title: insight.title,
          description: insight.description,
          priority: insight.priority,
          actionSteps: [],
        ),
      ],
      trainingPlan: null,
      encouragement: null,
      source: source,
      timestamp: DateTime.now(),
    );
  }

  static String _mapInsightTypeToCategory(InsightType type) {
    switch (type) {
      case InsightType.technique:
        return 'technique';
      case InsightType.drill:
        return 'physical';
      default:
        return 'general';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'diagnosis': diagnosis,
      'strengths': strengths,
      'weaknesses': weaknesses,
      'suggestions': suggestions.map((s) => s.toJson()).toList(),
      'trainingPlan': trainingPlan?.toJson(),
      'encouragement': encouragement,
      'source': source,
      'timestamp': timestamp.toIso8601String(),
      'rawResponse': rawResponse,
    };
  }

  factory AICoachResult.fromJson(Map<String, dynamic> json) {
    return AICoachResult(
      diagnosis: json['diagnosis'] ?? '',
      strengths: List<String>.from(json['strengths'] ?? []),
      weaknesses: List<String>.from(json['weaknesses'] ?? []),
      suggestions: (json['suggestions'] as List?)
              ?.map((s) => CoachingSuggestion.fromJson(s))
              .toList() ??
          [],
      trainingPlan: json['trainingPlan'] != null
          ? TrainingPlan.fromJson(json['trainingPlan'])
          : null,
      encouragement: json['encouragement'],
      source: json['source'] ?? 'unknown',
      timestamp: DateTime.parse(json['timestamp']),
      rawResponse: json['rawResponse'],
    );
  }
}

/// 教练建议
class CoachingSuggestion {
  final String category;    // technique|physical|mental|equipment
  final String title;
  final String description;
  final int priority;       // 1-5
  final List<String> actionSteps;

  CoachingSuggestion({
    required this.category,
    required this.title,
    required this.description,
    required this.priority,
    required this.actionSteps,
  });

  factory CoachingSuggestion.fromJson(Map<String, dynamic> json) {
    return CoachingSuggestion(
      category: json['类别'] ?? json['category'] ?? 'general',
      title: json['标题'] ?? json['title'] ?? '',
      description: json['描述'] ?? json['description'] ?? '',
      priority: json['优先级'] ?? json['priority'] ?? 3,
      actionSteps: List<String>.from(
        json['行动步骤'] ?? json['actionSteps'] ?? [],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'title': title,
      'description': description,
      'priority': priority,
      'actionSteps': actionSteps,
    };
  }
}

/// 训练计划
class TrainingPlan {
  final String planName;
  final String duration;
  final List<TrainingPhase> phases;

  TrainingPlan({
    required this.planName,
    required this.duration,
    required this.phases,
  });

  factory TrainingPlan.fromJson(Map<String, dynamic> json) {
    return TrainingPlan(
      planName: json['计划名称'] ?? json['planName'] ?? '',
      duration: json['时长'] ?? json['duration'] ?? '',
      phases: (json['阶段'] ?? json['phases'] ?? [])
          .map<TrainingPhase>((p) => TrainingPhase.fromJson(p))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'planName': planName,
      'duration': duration,
      'phases': phases.map((p) => p.toJson()).toList(),
    };
  }
}

/// 训练阶段
class TrainingPhase {
  final String phaseName;
  final int durationDays;
  final String focus;
  final List<TrainingDrill> drills;

  TrainingPhase({
    required this.phaseName,
    required this.durationDays,
    required this.focus,
    required this.drills,
  });

  factory TrainingPhase.fromJson(Map<String, dynamic> json) {
    return TrainingPhase(
      phaseName: json['阶段名称'] ?? json['phaseName'] ?? '',
      durationDays: json['天数'] ?? json['durationDays'] ?? 7,
      focus: json['重点'] ?? json['focus'] ?? '',
      drills: (json['训练项目'] ?? json['drills'] ?? [])
          .map<TrainingDrill>((d) => TrainingDrill.fromJson(d))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phaseName': phaseName,
      'durationDays': durationDays,
      'focus': focus,
      'drills': drills.map((d) => d.toJson()).toList(),
    };
  }
}

/// 训练项目
class TrainingDrill {
  final String name;
  final String description;
  final int arrows;
  final String frequency;

  TrainingDrill({
    required this.name,
    required this.description,
    required this.arrows,
    required this.frequency,
  });

  factory TrainingDrill.fromJson(Map<String, dynamic> json) {
    return TrainingDrill(
      name: json['名称'] ?? json['name'] ?? '',
      description: json['描述'] ?? json['description'] ?? '',
      arrows: json['箭数'] ?? json['arrows'] ?? 0,
      frequency: json['频率'] ?? json['frequency'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'arrows': arrows,
      'frequency': frequency,
    };
  }
}
