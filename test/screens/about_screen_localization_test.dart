import 'package:archery_tracker/l10n/app_localizations.dart';
import 'package:archery_tracker/screens/about_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('about screen uses English copy in English locale',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: AboutScreen(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('About'), findsOneWidget);
    expect(find.text('Archery Record Pro'), findsNWidgets(2));
    expect(find.text('App Name'), findsOneWidget);
    expect(find.text('Feedback'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);

    expect(find.text('App 名称'), findsNothing);
    expect(find.text('反馈联系方式'), findsNothing);
    expect(find.text('隐私协议'), findsNothing);
  });
}
