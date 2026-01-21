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
import 'services/storage_service.dart';
import 'services/scoring_service.dart';
import 'services/logger_service.dart';
import 'providers/scoring_provider.dart';
import 'providers/session_provider.dart';
import 'providers/locale_provider.dart';
import 'l10n/app_localizations.dart';
import 'utils/sample_data.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logger first
  final logger = LoggerService();
  await logger.initialize();
  logger.log('🚀 App starting...', level: LogLevel.info);

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

  runZonedGuarded<Future<void>>(() async {
    logger.logLifecycle('Initializing services...');

    // Initialize storage service with error handling
    final storageService = StorageService();
    try {
      logger.log('📦 Initializing storage...', level: LogLevel.info);
      await storageService.initialize();
      logger.log('✅ Storage initialized', level: LogLevel.info);
    } catch (e, stack) {
      logger.logError(
        'Failed to initialize storage',
        error: e,
        stackTrace: stack,
      );

      // Try to recover by deleting corrupted boxes
      try {
        logger.log('🧹 Attempting storage recovery...', level: LogLevel.warning);
        await storageService.deleteDataFromDisk();
        await storageService.initialize();
        logger.log('✅ Storage recovered', level: LogLevel.info);
      } catch (e2, stack2) {
        logger.logError(
          'Failed to recover storage',
          error: e2,
          stackTrace: stack2,
        );
        // App continues without persistent storage
      }
    }

    // Create provider container
    final container = ProviderContainer(
      overrides: [
        storageServiceProvider.overrideWithValue(storageService),
      ],
    );

    // Initialize locale
    try {
      logger.log('🌐 Initializing locale...', level: LogLevel.info);
      await container.read(localeProvider.notifier).initialize();
      logger.log('✅ Locale initialized', level: LogLevel.info);
    } catch (e, stack) {
      logger.logError(
        'Locale initialization failed',
        error: e,
        stackTrace: stack,
      );
    }

    logger.logLifecycle('Starting app...');

    runApp(
      UncontrolledProviderScope(
        container: container,
        child: const ArcheryApp(),
      ),
    );
  }, (error, stack) {
    logger.logFatal(
      'Uncaught error in main zone',
      error: error,
      stackTrace: stack,
    );
  });
}

class ArcheryApp extends ConsumerWidget {
  const ArcheryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      home: const MainContainer(),
    );
  }
}

class MainContainer extends ConsumerStatefulWidget {
  const MainContainer({super.key});

  @override
  ConsumerState<MainContainer> createState() => _MainContainerState();
}

class _MainContainerState extends ConsumerState<MainContainer> {
  int _currentIndex = 0;
  bool _isInitialized = false;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const AnalysisScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Generate sample data on first launch
      final sessionService = ref.read(sessionServiceProvider);
      final scoringService = ref.read(scoringServiceProvider);
      final generator = SampleDataGenerator(sessionService, scoringService);

      await generator.generateSampleSessions();

      // Refresh session list
      await ref.read(sessionProvider.notifier).loadSessions();
    } catch (e) {
      debugPrint('Initialization error: $e');
    }

    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

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
