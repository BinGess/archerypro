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
}
