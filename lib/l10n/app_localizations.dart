import 'package:flutter/material.dart';
import 'app_localizations_zh.dart';
import 'app_localizations_en.dart';

/// Base class for app localizations
abstract class AppLocalizations {
  // Common
  String get appName;
  String get ok;
  String get cancel;
  String get close;
  String get save;
  String get delete;
  String get edit;
  String get reset;
  String get discard;
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
  String get currentEnd;
  String get completeSession;
  String get sessionSaved;
  String get endCompleted;
  String get sessionCompleted;
  String get noActiveTraining;
  String get clickStartScoring;
  String get oneMoreEnd;
  String get removeShort;
  String get scoringExitTitle;
  String get scoringExitMessage;
  String endLabel(String number);
  String endCompletedLabel(String number);
  String scoreLabel(String score);
  String totalScoreLabel(String total);

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
  String get tenRingRate;
  String get groupingDensity;
  String get endurance;
  String get centerPrecision;

  // Details
  String get sessionDetails;
  String get date;
  String get equipment;
  String get scorePercentage;
  String get endBreakdown;
  String get noSessionDetailsHint;
  String get endsScoreTitle;
  String totalEndsLabel(String count);

  // Settings
  String get settingsTitle;
  String get languageSettings;
  String get monthlyGoalSettings;
  String get monthlyGoalSettingsSubtitle;
  String get monthlyGoalCurrentProgress;
  String get monthlyGoalCompletion;
  String get monthlyGoalSetTitle;
  String get monthlyGoalInputHint;
  String get monthlyGoalInputLabel;
  String get monthlyGoalSaveSuccess;
  String get monthlyGoalInvalidValue;
  String get selectLanguage;
  String get chinese;
  String get english;
  String get systemDefault;
  String get about;
  String get version;
  String get privacyPolicy;
  String get termsOfService;
  String get debugSection;
  String get viewLogs;
  String get viewLogsSubtitle;
  String get logsTitle;
  String logsFailedToLoad(String error);
  String get logsCopied;
  String get clearLogsTitle;
  String get clearLogsMessage;
  String get refreshLogsTooltip;
  String get copyLogsTooltip;
  String get clearLogsTooltip;
  String get logsLocalOnlyHint;
  String get noLogsAvailable;
  String get logsCleared;

  // Messages
  String get loading;
  String get noData;
  String get noValidData;
  String get ringNumber;
  String get noBiasData;
  String get missDistribution;
  String get currentPeriod;
  String get previousPeriod;
  String get overallScore;
  String strengthLabel(String strongest);
  String weaknessLabel(String weakest);
  String quadrantDominanceMessage(String direction, String percent);
  String get error;
  String get success;
  String get initializationFailed;
  String get resetDataAndRetry;
  String get somethingWentWrong;
  String get restartApp;
  String get failedToStartApp;

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
  String get homeEmptyPrompt;
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

  // AI Coach
  String get aiCoachAnalysis;
  String get aiCoachDeepAnalysis;
  String get aiCoachPeriodAnalysis;
  String get aiCoachBasedOnData;
  String get aiCoachBasedOnCurrentSession;
  String get aiCoachGetProfessionalAdvice;
  String get aiCoachAnalyzeButton;
  String get aiCoachDeepAnalyzeButton;
  String get aiCoachReanalyzeButton;
  String get aiCoachAnalyzing;
  String get aiCoachAnalyzingPeriod;
  String get aiCoachAnalysisComplete;
  String get aiCoachAnalysisFailed;
  String get aiCoachNetworkError;
  String get aiCoachClickToAnalyze;
  String get aiCoachClickForDeepAnalysis;
  String get aiCoachPreferOnlineFallbackToLocal;
  String get aiCoachPreferOnlineFallbackToOffline;
  String get aiCoachDismiss;
  String get aiCoachClose;
  String get aiCoachDiagnosis;
  String get aiCoachStrengths;
  String get aiCoachWeaknesses;
  String get aiCoachSuggestions;
  String get aiCoachTrainingPlan;
  String get aiCoachEncouragement;
  String get aiCoachSourceOnline;
  String get aiCoachSourceLocal;
  String get aiCoachSourceOffline;
  String get aiCoachCategoryTechnique;
  String get aiCoachCategoryPhysical;
  String get aiCoachCategoryMental;
  String get aiCoachCategoryEquipment;
  String get aiCoachCategoryGeneral;
  String get aiCoachActionSteps;
  String get aiCoachPhaseFocus;
  String get aiCoachDrills;
  String get aiCoachDays;
  String get aiCoachArrowsUnit;
  String get aiCoachPhase;
  String get aiCoachSuggestionsCount;

  // Session setup
  String get environment;
  String get indoor;
  String get outdoor;
  String get sessionSetupEquipment;
  String get sessionSetupVenue;
  String get sessionSetupRules;
  String get sessionSetupDisplayMode;
  String get scoringView;
  String get listView;
  String get targetView;
  String get competitionMode;
  String get competitionWaStandard;
  String get competitionTimePerArrow;
  String get competitionCustom;
  String get competitionSecondsPerArrow;
  String get competitionWhistleSounds;
  String get competitionWaWhistleDesc;
  String get competitionInputMode;
  String get competitionKeyboardEntry;
  String get competitionTargetEntry;
  String get competitionTapTargetHint;
  String get competitionPrep;
  String get competitionShoot;
  String get competitionWarn;
  String get competitionWarningLeft;
  String get competitionTotal;
  String get competitionStartBtn;
  String get competitionReady;
  String get competitionGetReady;
  String get competitionDoNotRaiseBow;
  String get competitionHurryUp;
  String get competitionSkip;
  String get competitionStop;
  String get competitionShooting;
  String get competitionPaused;
  String get competitionSafetyHalt;
  String competitionRemainingTime(int seconds);
  String get competitionResume;
  String get competitionResetEnd;
  String get competitionResetEndTitle;
  String get competitionResetEndMessage;
  String get competitionComplete;
  String get competitionAvgPerEnd;
  String get competitionBest;
  String get competitionWorst;
  String get competitionEnds;
  String get competitionDone;
  String get competitionIncompleteEnd;
  String competitionIncompleteMessage(int current, int total);
  String get competitionSubmit;
  String get competitionLeaveTitle;
  String get competitionLeaveMessage;
  String get competitionStay;
  String get competitionLeave;
  String get estimatedTotalArrows;
  String get centimeters;
  String sessionSetupSelectLabel(String label);
  String myBowName(String bowName);

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('zh', 'CN'),
    Locale('en', 'US'),
  ];
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
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
