import 'package:flutter/material.dart';
import 'app_localizations_zh.dart';
import 'app_localizations_en.dart';

/// Base class for app localizations
abstract class AppLocalizations {
  // Common
  String get appName;
  String get ok;
  String get cancel;
  String get save;
  String get delete;
  String get edit;
  String get confirm;
  String get back;
  String get settings;
  String get language;

  // Bottom Navigation
  String get navHome;
  String get navAdd;
  String get navStatistics;

  // Dashboard
  String get dashboard;
  String get refresh;
  String get noTrainingRecords;
  String get clickAddToStart;
  String get highScore;
  String get arrows;
  String get totalScore;
  String get averageScore;
  String get xCount;
  String get tenCount;

  // Scoring
  String get scoring;
  String get endNumber;
  String get arrowNumber;
  String get miss;
  String get removeScore;
  String get completeSession;
  String get sessionSaved;
  String get endCompleted;
  String get sessionCompleted;

  // Session Setup
  String get newTraining;
  String get distance;
  String get meters;
  String get targetFaceSize;
  String get bowType;
  String get arrowsPerEnd;
  String get numberOfEnds;
  String get startTraining;

  // Bow Types
  String get recurveBow;
  String get compoundBow;
  String get traditionalBow;
  String get barebow;

  // Analysis
  String get analysis;
  String get statistics;
  String get trends;
  String get heatmap;
  String get scoreDistribution;
  String get performanceAnalysis;
  String get consistency;
  String get accuracy;
  String get precision;

  // Details
  String get sessionDetails;
  String get date;
  String get equipment;
  String get scorePercentage;
  String get endBreakdown;

  // Settings
  String get settingsTitle;
  String get languageSettings;
  String get selectLanguage;
  String get chinese;
  String get english;
  String get systemDefault;
  String get about;
  String get version;
  String get privacyPolicy;
  String get termsOfService;

  // Messages
  String get loading;
  String get noData;
  String get error;
  String get success;

  // Date Formats
  String formatDate(DateTime date);
  String formatTime(DateTime time);

  // Helpers
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  // Time Periods
  String get period7Days;
  String get period1Month;
  String get periodCurrentYear;
  String get periodAll;

  // Analysis Charts
  String get growthTrendChart;
  String get growthTrendSubtitle;
  String get noDataForPeriod;
  String get stabilityRadarChart;
  String get needMoreData;
  String get stabilityRadarSubtitle;
  String get quadrantRadarChart;
  String get quadrantRadarSubtitle;
  String get allArrowsGood;

  // Analysis Insights & AI
  String get aiPeriodAnalysis;
  String get aiCoachAdvice;
  String get keepTrainingForInsights;
  String get actionableTip;
  
  // Insight Messages
  String get insightPlateauTitle;
  String get insightPlateauMessage;
  String get insightVolumeWarningTitle;
  String insightVolumeWarningMessage(String decline);
  String get insightAdvancementTitle;
  String insightAdvancementMessage(String rate);
  String get insightChronicBiasTitle;
  String insightChronicBiasMessage(String percent, String direction);
  String get insightExcellenceTitle;
  String insightExcellenceMessage(String consistency);
  String insightGroupingTitle(String tendency);
  String insightGroupingMessage(String tendency);
  
  // Directions
  String get directionTopLeft;
  String get directionTopRight;
  String get directionBottomLeft;
  String get directionBottomRight;
  String get directionTop;
  String get directionBottom;
  String get directionLeft;
  String get directionRight;

  // Chart Titles
  String get visualization;
  String get heatmapTitle;
  String get heatmapSubtitle;
  String get endTrendTitle;
  String get endTrendSubtitle;
  String get scoreDistTitle;
  String get scoreDistSubtitle;
  
  // Dialogs
  String get deleteRecordTitle;
  String get deleteRecordMessage;
  String get recordDeleted;
  String get featureInDev;

  // Dashboard
  String get sessions;
  String monthlyArrowsMessage(String count);
  String get average;
  String get trend;
  String monthlyGoalMessage(String count);
  String get noRecords;
  String get clickToAdd;
  String showingRecentMessage(String count);
  String get totalArrows; // New key added for fix

  // Bow Types
  String get bowCompound;
  String get bowRecurve;
  String get bowBarebow;
  String get bowLongbow;
  
  // Units
  String get unitArrows; // "支箭" / "arrows"

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('zh', 'CN'),
    Locale('en', 'US'),
  ];
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['zh', 'en'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    switch (locale.languageCode) {
      case 'zh':
        return AppLocalizationsZh();
      case 'en':
        return AppLocalizationsEn();
      default:
        return AppLocalizationsZh();
    }
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
