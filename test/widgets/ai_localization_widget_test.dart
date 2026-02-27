import 'package:archery_tracker/l10n/app_localizations.dart';
import 'package:archery_tracker/widgets/ai_coach/ai_loading_widget.dart';
import 'package:archery_tracker/widgets/ai_coach/ai_source_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _testApp({required Locale locale, required Widget child}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  testWidgets('AI source badge localizes source text in Chinese',
      (tester) async {
    await tester.pumpWidget(
      _testApp(
        locale: const Locale('zh', 'CN'),
        child: const AISourceBadge(source: 'coze'),
      ),
    );
    await tester.pump();

    expect(find.text('AI 在线分析'), findsOneWidget);
  });

  testWidgets('AI source badge localizes source text in English',
      (tester) async {
    await tester.pumpWidget(
      _testApp(
        locale: const Locale('en', 'US'),
        child: const AISourceBadge(source: 'coze'),
      ),
    );
    await tester.pump();

    expect(find.text('AI Online Analysis'), findsOneWidget);
  });

  testWidgets('AI loading widget falls back to localized default message',
      (tester) async {
    await tester.pumpWidget(
      _testApp(
        locale: const Locale('en', 'US'),
        child: const AILoadingWidget(),
      ),
    );
    await tester.pump();

    expect(find.text('AI Coach analyzing...'), findsOneWidget);
  });
}
