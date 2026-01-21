import 'package:intl/intl.dart';
import 'app_localizations.dart';

/// English localizations
class AppLocalizationsEn extends AppLocalizations {
  // Common
  @override
  String get appName => 'Archery Tracker';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get confirm => 'Confirm';

  @override
  String get back => 'Back';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  // Bottom Navigation
  @override
  String get navHome => 'Home';

  @override
  String get navAdd => 'Add';

  @override
  String get navStatistics => 'Stats';

  // Dashboard
  @override
  String get dashboard => 'Home';

  @override
  String get refresh => 'Refresh';

  @override
  String get noTrainingRecords => 'No training records';

  @override
  String get clickAddToStart => 'Tap "Add" to start your first training';

  @override
  String get highScore => 'High Score';

  @override
  String get arrows => 'Arrows';

  @override
  String get totalScore => 'Total Score';

  @override
  String get averageScore => 'Average';

  @override
  String get xCount => 'X Count';

  @override
  String get tenCount => '10s Count';

  // Scoring
  @override
  String get scoring => 'Scoring';

  @override
  String get endNumber => 'End';

  @override
  String get arrowNumber => 'Arrow';

  @override
  String get miss => 'Miss';

  @override
  String get removeScore => 'Remove';

  @override
  String get completeSession => 'Complete';

  @override
  String get sessionSaved => 'Session saved!';

  @override
  String get endCompleted => 'End completed';

  @override
  String get sessionCompleted => 'Training completed!';

  // Session Setup
  @override
  String get newTraining => 'New Training';

  @override
  String get distance => 'Distance';

  @override
  String get meters => 'm';

  @override
  String get targetFaceSize => 'Target Size';

  @override
  String get bowType => 'Bow Type';

  @override
  String get arrowsPerEnd => 'Arrows per End';

  @override
  String get numberOfEnds => 'Number of Ends';

  @override
  String get startTraining => 'Start Training';

  // Bow Types
  @override
  String get recurveBow => 'Recurve Bow';

  @override
  String get compoundBow => 'Compound Bow';

  @override
  String get traditionalBow => 'Traditional Bow';

  @override
  String get barebow => 'Barebow';

  // Analysis
  @override
  String get analysis => 'Analysis';

  @override
  String get statistics => 'Statistics';

  @override
  String get trends => 'Trends';

  @override
  String get heatmap => 'Heatmap';

  @override
  String get scoreDistribution => 'Score Distribution';

  @override
  String get performanceAnalysis => 'Performance Analysis';

  @override
  String get consistency => 'Consistency';

  @override
  String get accuracy => 'Accuracy';

  @override
  String get precision => 'Precision';

  // Details
  @override
  String get sessionDetails => 'Session Details';

  @override
  String get date => 'Date';

  @override
  String get equipment => 'Equipment';

  @override
  String get scorePercentage => 'Score %';

  @override
  String get endBreakdown => 'End Breakdown';

  // Settings
  @override
  String get settingsTitle => 'Settings';

  @override
  String get languageSettings => 'Language Settings';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get chinese => '简体中文';

  @override
  String get english => 'English';

  @override
  String get systemDefault => 'System Default';

  @override
  String get about => 'About';

  @override
  String get version => 'Version';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get termsOfService => 'Terms of Service';

  // Messages
  @override
  String get loading => 'Loading...';

  @override
  String get noData => 'No data';

  @override
  String get error => 'Error';

  @override
  String get success => 'Success';

  // Date Formats
  @override
  String formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  @override
  String formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  // Time Periods
  @override
  String get period7Days => '7 Days';
  @override
  String get period1Month => '30 Days';
  @override
  String get periodCurrentYear => 'Year';
  @override
  String get periodAll => 'All';

  // Analysis Charts
  @override
  String get growthTrendChart => 'Growth Trends';
  @override
  String get growthTrendSubtitle => 'Score Trend + Volume';
  @override
  String get noDataForPeriod => 'No data for selected period';
  @override
  String get stabilityRadarChart => 'Stability Radar';
  @override
  String get needMoreData => 'Need more data';
  @override
  String get stabilityRadarSubtitle => '6-Dimension Assessment';
  @override
  String get quadrantRadarChart => 'Bias Diagnosis';
  @override
  String get quadrantRadarSubtitle => 'Direction of <9 Ring Arrows';
  @override
  String get allArrowsGood => 'Great! All arrows are 9+';

  // Analysis Insights & AI
  @override
  String get aiPeriodAnalysis => 'AI Analysis';
  @override
  String get aiCoachAdvice => 'AI Coach Advice';
  @override
  String get keepTrainingForInsights => 'Keep training to get AI insights';
  @override
  String get actionableTip => 'Actionable Tip';

  // Insight Messages
  @override
  String get insightPlateauTitle => 'Plateau Detected';
  @override
  String get insightPlateauMessage => 'Performance has plateaued. Try new drills or technique adjustments.';
  @override
  String get insightVolumeWarningTitle => 'Volume Decline';
  @override
  String insightVolumeWarningMessage(String decline) => 'Training volume dropped by $decline% compared to last period.';
  @override
  String get insightAdvancementTitle => 'Ready to Advance';
  @override
  String insightAdvancementMessage(String rate) => '10-ring rate is $rate% with great stability. Try increasing distance.';
  @override
  String get insightChronicBiasTitle => 'Chronic Bias';
  @override
  String insightChronicBiasMessage(String percent, String direction) => '$percent% of misses are bias to $direction. Check form or tuning.';
  @override
  String get insightExcellenceTitle => 'Excellent Stability';
  @override
  String insightExcellenceMessage(String consistency) => 'Consistency reached $consistency%. Outstanding form!';
  @override
  String insightGroupingTitle(String tendency) => 'Grouping: $tendency';
  @override
  String insightGroupingMessage(String tendency) => 'Your group tends to be $tendency. Focus on alignment.';

  // Directions
  @override
  String get directionTopLeft => 'Top-Left';
  @override
  String get directionTopRight => 'Top-Right';
  @override
  String get directionBottomLeft => 'Bottom-Left';
  @override
  String get directionBottomRight => 'Bottom-Right';
  @override
  String get directionTop => 'High';
  @override
  String get directionBottom => 'Low';
  @override
  String get directionLeft => 'Left';
  @override
  String get directionRight => 'Right';

  // Chart Titles
  @override
  String get visualization => 'Visualization';
  @override
  String get heatmapTitle => 'Heatmap';
  @override
  String get heatmapSubtitle => 'Arrow distribution + Center';
  @override
  String get endTrendTitle => 'End Trends';
  @override
  String get endTrendSubtitle => 'Average score per end';
  @override
  String get scoreDistTitle => 'Score Distribution';
  @override
  String get scoreDistSubtitle => 'Arrow counts by ring';

  // Dialogs
  @override
  String get deleteRecordTitle => 'Delete Record';
  @override
  String get deleteRecordMessage => 'Are you sure you want to delete this record? This cannot be undone.';
  @override
  String get recordDeleted => 'Record deleted';
  @override
  String get featureInDev => 'Feature in development';

  // Dashboard
  @override
  String get sessions => 'Sessions';
  @override
  String monthlyArrowsMessage(String count) => '$count arrows this month';
  @override
  String get average => 'Avg';
  @override
  String get trend => 'Trend';
  @override
  String monthlyGoalMessage(String count) => 'Monthly Goal: $count arrows';
  @override
  String get noRecords => 'No training records';
  @override
  String get clickToAdd => 'Tap "+" to start your first session';
  @override
  String showingRecentMessage(String count) => 'Showing recent $count sessions';

  @override
  String get totalArrows => 'Total Arrows';

  // Bow Types
  @override
  String get bowCompound => 'Compound';
  @override
  String get bowRecurve => 'Recurve';
  @override
  String get bowBarebow => 'Barebow';
  @override
  String get bowLongbow => 'Longbow';
  
  // Units
  @override
  String get unitArrows => 'arrows';
}
