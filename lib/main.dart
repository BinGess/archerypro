import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'theme/app_colors.dart';
import 'screens/dashboard_screen.dart';
import 'screens/analysis_screen.dart';
import 'screens/session_setup_screen.dart';
import 'services/logger_service.dart';
import 'providers/scoring_provider.dart';
import 'providers/session_provider.dart';
import 'providers/locale_provider.dart';
import 'l10n/app_localizations.dart';
import 'utils/sample_data.dart';

void main() async {
  // Run everything in a guarded zone
  runZonedGuarded<Future<void>>(() async {
    // Ensure Flutter binding is initialized - MUST be in the same zone as runApp
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize logger first
    final logger = LoggerService();
    await logger.initialize();

    // Log startup attempt with timestamp
    final startTime = DateTime.now();
    logger.log('🚀 App starting...', level: LogLevel.info);
    logger.log('📅 Startup time: ${startTime.toIso8601String()}', level: LogLevel.info);
    logger.log('🔢 Process attempt ID: ${startTime.millisecondsSinceEpoch}', level: LogLevel.info);

    // Force flush immediately to ensure these logs are persisted
    await logger.forceFlush();

    // Set up Flutter error handler
    FlutterError.onError = (FlutterErrorDetails details) {
      logger.logError(
        'Flutter framework error',
        error: details.exception,
        stackTrace: details.stack,
        context: details.context?.toString(),
      );
      FlutterError.presentError(details);
    };

    // Set up platform error handler
    PlatformDispatcher.instance.onError = (error, stack) {
      logger.logFatal(
        'Platform dispatcher error',
        error: error,
        stackTrace: stack,
      );
      return true;
    };

    logger.logLifecycle('Initializing services...');

    final container = ProviderContainer();

    logger.logLifecycle('Starting app...');

    runApp(
      UncontrolledProviderScope(
        container: container,
        child: const ArcheryApp(),
      ),
    );
  }, (error, stack) {
    debugPrint('💥 Uncaught error in main zone: $error');
    debugPrint('Stack trace: $stack');

    // Try to log even if logger might not be initialized
    try {
      LoggerService().logFatal(
        'Uncaught error in main zone',
        error: error,
        stackTrace: stack,
      );
    } catch (_) {
      // Logger not available, just print
    }
  });
}

class ArcheryApp extends ConsumerWidget {
  const ArcheryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logger = LoggerService();

    try {
      logger.log('🎨 Building ArcheryApp...', level: LogLevel.info);
      final localeState = ref.watch(localeProvider);

      return MaterialApp(
        title: 'Archery Tracker',
        debugShowCheckedModeBanner: false,

        // Localization delegates
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],

        // Supported locales
        supportedLocales: AppLocalizations.supportedLocales,

        // Current locale
        locale: localeState.locale,

        theme: ThemeData(
          scaffoldBackgroundColor: AppColors.backgroundLight,
          primaryColor: AppColors.primary,
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
          useMaterial3: true,
          // fontFamily: GoogleFonts.manrope().fontFamily,
          // textTheme: GoogleFonts.manropeTextTheme(Theme.of(context).textTheme),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
          ),
        ),
        home: const InitializationWrapper(),
        builder: (context, child) {
          // Error boundary for the entire app
          ErrorWidget.builder = (FlutterErrorDetails details) {
            logger.logError(
              'Widget error',
              error: details.exception,
              stackTrace: details.stack,
            );
            return Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text(
                        'Something went wrong',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        details.exception.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          // Try to restart the app
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const MainContainer()),
                            (route) => false,
                          );
                        },
                        child: const Text('Restart App'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          };
          return child ?? const SizedBox.shrink();
        },
      );
    } catch (e, stack) {
      logger.logError(
        'Failed to build ArcheryApp',
        error: e,
        stackTrace: stack,
      );

      // Return a minimal error screen
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Failed to start app',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    e.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }
}

class InitializationWrapper extends ConsumerStatefulWidget {
  const InitializationWrapper({super.key});

  @override
  ConsumerState<InitializationWrapper> createState() => _InitializationWrapperState();
}

class _InitializationWrapperState extends ConsumerState<InitializationWrapper> {
  bool _isInitialized = false;
  bool _isRecovering = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _initializeApp());
  }

  Future<void> _initializeApp() async {
    final logger = LoggerService();

    try {
      logger.log('📦 Initializing storage...', level: LogLevel.info);
      final storageService = ref.read(storageServiceProvider);
      await storageService.initialize();
      logger.log('✅ Storage initialized', level: LogLevel.info);

      logger.log('🌐 Initializing locale...', level: LogLevel.info);
      await ref.read(localeProvider.notifier).initialize();
      logger.log('✅ Locale initialized', level: LogLevel.info);

      logger.log('📂 Loading sessions...', level: LogLevel.info);
      await ref.read(sessionProvider.notifier).loadSessions();
      logger.log('✅ Sessions loaded successfully', level: LogLevel.info);

      final sessions = ref.read(sessionProvider).sessions;
      logger.log('Found ${sessions.length} existing sessions', level: LogLevel.info);

      if (sessions.isEmpty) {
        logger.log('🎲 No sessions found, generating sample data...', level: LogLevel.info);
        try {
          final sessionService = ref.read(sessionServiceProvider);
          final scoringService = ref.read(scoringServiceProvider);
          final generator = SampleDataGenerator(sessionService, scoringService);

          await generator.generateSampleSessions();
          logger.log('✅ Sample data generated', level: LogLevel.info);

          await ref.read(sessionProvider.notifier).loadSessions();
        } catch (e, stack) {
          logger.logError(
            'Failed to generate sample data',
            error: e,
            stackTrace: stack,
          );
        }
      }
    } catch (e, stack) {
      logger.logError(
        'Initialization error',
        error: e,
        stackTrace: stack,
      );
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    }

    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  '初始化失败',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                _isRecovering
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _recoverApp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('重置数据并重试'),
                      ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('加载中...'),
            ],
          ),
        ),
      );
    }

    return const MainContainer();
  }

  Future<void> _recoverApp() async {
    setState(() => _isRecovering = true);
    final logger = LoggerService();

    try {
      final storageService = ref.read(storageServiceProvider);
      await storageService.deleteDataFromDisk();
      setState(() {
        _error = null;
        _isRecovering = false;
        _isInitialized = false;
      });
      await _initializeApp();
    } catch (e, stack) {
      logger.logError(
        'Recovery failed',
        error: e,
        stackTrace: stack,
      );
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isRecovering = false;
        });
      }
    }
  }
}

class MainContainer extends ConsumerStatefulWidget {
  const MainContainer({super.key});

  @override
  ConsumerState<MainContainer> createState() => _MainContainerState();
}

class _MainContainerState extends ConsumerState<MainContainer> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const AnalysisScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex == 2 ? 1 : _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.borderLight)),
          color: Colors.white,
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            if (index == 1) {
              // Middle button - open session setup
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SessionSetupScreen(),
                ),
              );
            } else {
              setState(() => _currentIndex = index);
            }
          },
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSlate400,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
          elevation: 0,
          items: [
            BottomNavigationBarItem(icon: const Icon(Icons.history), label: l10n.navHome),
            BottomNavigationBarItem(
              icon: const SizedBox(
                width: 44,
                height: 44,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  child: Icon(Icons.add, color: Colors.white),
                ),
              ),
              activeIcon: const SizedBox(
                width: 44,
                height: 44,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  child: Icon(Icons.add, color: Colors.white),
                ),
              ),
              label: l10n.navAdd,
            ),
            BottomNavigationBarItem(icon: const Icon(Icons.analytics_outlined), label: l10n.navStatistics),
          ],
        ),
      ),
    );
  }
}
