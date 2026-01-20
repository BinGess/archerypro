/// Application-wide constants

// Scoring Constants
const int kMinScore = 0; // Miss
const int kMaxScore = 10;
const int kXRingScore = 11; // X represented as 11 internally, counts as 10 points

// Arrow Counts
const int kDefaultArrowsPerEnd = 6;
const int kAlternateArrowsPerEnd = 3;

// Target Face Sizes (in cm)
const List<int> kTargetFaceSizes = [40, 60, 80, 122];
const int kDefaultTargetSize = 40;

// Common Shooting Distances (in meters)
const List<double> kIndoorDistances = [18.0, 25.0];
const List<double> kOutdoorDistances = [30.0, 50.0, 70.0, 90.0];
const double kDefaultDistance = 18.0;

// Goals
const int kDefaultMonthlyGoal = 3000; // arrows per month
const int kDefaultWeeklyGoal = 750; // arrows per week

// Time Periods for Analysis
const String kPeriod7Days = '7天';
const String kPeriod1Month = '1个月';
const String kPeriod3Months = '3个月';
const String kPeriodAll = '全部';

const List<String> kAnalysisPeriods = [
  kPeriod7Days,
  kPeriod1Month,
  kPeriod3Months,
  kPeriodAll,
];

// Performance Thresholds
const double kExcellentScoreThreshold = 9.0; // Average arrow score
const double kGoodScoreThreshold = 8.0;
const double kFairScoreThreshold = 7.0;

const double kHighConsistencyThreshold = 85.0; // Percentage
const double kMediumConsistencyThreshold = 70.0;

// Hive Box Names
const String kSessionsBoxName = 'training_sessions';
const String kSettingsBoxName = 'app_settings';

// Settings Keys
const String kMonthlyGoalKey = 'monthly_goal';
const String kUserNameKey = 'user_name';
const String kDefaultEquipmentKey = 'default_equipment';

// Score Display Colors (based on target rings)
const Map<int, String> kScoreColorMap = {
  10: 'Gold',
  9: 'Gold',
  8: 'Red',
  7: 'Red',
  6: 'Blue',
  5: 'Blue',
  4: 'Black',
  3: 'Black',
  2: 'White',
  1: 'White',
  0: 'Miss',
};

// Date Format Patterns
const String kDateFormatShort = 'MM月dd日'; // 10月24日
const String kDateFormatLong = 'yyyy年MM月dd日'; // 2023年10月24日
const String kDateFormatFull = 'yyyy-MM-dd HH:mm'; // 2023-10-24 14:30

// Session Defaults
const int kDefaultSessionDurationMinutes = 90;

// AI Insight Generation Thresholds
const int kMinSessionsForInsights = 3; // Minimum sessions needed to generate insights
const int kMinArrowsForHeatmap = 12; // Minimum arrows needed for heatmap

// UI Constants
const double kDefaultCardElevation = 2.0;
const double kDefaultBorderRadius = 12.0;
const double kDefaultPadding = 16.0;

// Validation
const int kMaxSessionsToLoad = 100; // Prevent loading too many sessions at once
const int kMaxNotesLength = 500; // Maximum characters for session notes
