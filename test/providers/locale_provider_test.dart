import 'dart:ui';

import 'package:archery_tracker/providers/locale_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Locale systemLocale;
  late LocaleNotifier notifier;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    systemLocale = const Locale('en', 'US');
    notifier = LocaleNotifier(systemLocaleGetter: () => systemLocale);
  });

  test('initialize follows supported system locale', () async {
    systemLocale = const Locale('zh', 'CN');
    await notifier.initialize();

    expect(notifier.state.isSystemDefault, isTrue);
    expect(notifier.state.locale.languageCode, 'zh');
    expect(notifier.state.languageCode, 'zh');
  });

  test('initialize follows Japanese system locale', () async {
    systemLocale = const Locale('ja', 'JP');
    await notifier.initialize();

    expect(notifier.state.isSystemDefault, isTrue);
    expect(notifier.state.locale.languageCode, 'ja');
    expect(notifier.state.languageCode, 'ja');
  });

  test('initialize falls back to English for unsupported system locale',
      () async {
    systemLocale = const Locale('fr', 'FR');
    await notifier.initialize();

    expect(notifier.state.isSystemDefault, isTrue);
    expect(notifier.state.locale.languageCode, 'en');
    expect(notifier.state.languageCode, 'en');
  });

  test('initialize restores manual saved locale', () async {
    SharedPreferences.setMockInitialValues({
      'use_system_locale': false,
      'app_locale': 'zh',
    });
    systemLocale = const Locale('en', 'US');
    notifier = LocaleNotifier(systemLocaleGetter: () => systemLocale);
    await notifier.initialize();

    expect(notifier.state.isSystemDefault, isFalse);
    expect(notifier.state.locale.languageCode, 'zh');
    expect(notifier.state.languageCode, 'zh');
  });

  test('initialize restores manual saved Japanese locale', () async {
    SharedPreferences.setMockInitialValues({
      'use_system_locale': false,
      'app_locale': 'ja',
    });
    systemLocale = const Locale('en', 'US');
    notifier = LocaleNotifier(systemLocaleGetter: () => systemLocale);
    await notifier.initialize();

    expect(notifier.state.isSystemDefault, isFalse);
    expect(notifier.state.locale.languageCode, 'ja');
    expect(notifier.state.languageCode, 'ja');
  });

  test('refreshSystemLocale updates state only in system mode', () async {
    systemLocale = const Locale('en', 'US');
    await notifier.initialize();
    expect(notifier.state.locale.languageCode, 'en');

    systemLocale = const Locale('zh', 'CN');
    notifier.refreshSystemLocale();
    expect(notifier.state.locale.languageCode, 'zh');

    await notifier.setLocale(const Locale('en', 'US'));
    systemLocale = const Locale('zh', 'CN');
    notifier.refreshSystemLocale();

    expect(notifier.state.isSystemDefault, isFalse);
    expect(notifier.state.locale.languageCode, 'en');
  });
}
