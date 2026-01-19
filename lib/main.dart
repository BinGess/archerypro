import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/app_colors.dart';
import 'screens/dashboard_screen.dart';
import 'screens/analysis_screen.dart';
import 'screens/session_setup_screen.dart';
import 'services/storage_service.dart';
import 'services/scoring_service.dart';
import 'providers/scoring_provider.dart';
import 'providers/session_provider.dart';
import 'utils/sample_data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage service
  final storageService = StorageService();
  await storageService.initialize();

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storageService),
      ],
      child: const ArcheryApp(),
    ),
  );
}

class ArcheryApp extends StatelessWidget {
  const ArcheryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Archery Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.backgroundLight,
        primaryColor: AppColors.primary,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        useMaterial3: true,
        fontFamily: GoogleFonts.manrope().fontFamily,
        textTheme: GoogleFonts.manropeTextTheme(Theme.of(context).textTheme),
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
    // Generate sample data on first launch
    final sessionService = ref.read(sessionServiceProvider);
    final scoringService = ref.read(scoringServiceProvider);
    final generator = SampleDataGenerator(sessionService, scoringService);

    await generator.generateSampleSessions();

    // Refresh session list
    await ref.read(sessionProvider.notifier).loadSessions();

    setState(() {
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
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
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.history), label: '历史'),
            BottomNavigationBarItem(icon: Icon(Icons.add_circle, size: 32), label: '添加'),
            BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), label: '统计'),
          ],
        ),
      ),
    );
  }
}
