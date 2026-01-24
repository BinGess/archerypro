import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// State for locale management
class LocaleState {
  final Locale? locale;
  final bool isSystemDefault;

  const LocaleState({
    this.locale,
    this.isSystemDefault = true,
  });

  LocaleState copyWith({
    Locale? locale,
    bool? isSystemDefault,
  }) {
    return LocaleState(
      locale: locale ?? this.locale,
      isSystemDefault: isSystemDefault ?? this.isSystemDefault,
    );
  }

  String get languageCode {
    return locale?.languageCode ?? PlatformDispatcher.instance.locale.languageCode;
  }
}

/// Notifier for locale management with persistence
class LocaleNotifier extends StateNotifier<LocaleState> {
  static const String _localeKey = 'app_locale';
  static const String _systemDefaultKey = 'use_system_locale';

  LocaleNotifier() : super(const LocaleState());

  /// Initialize locale from saved preferences
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    final useSystemDefault = prefs.getBool(_systemDefaultKey) ?? true;

    if (useSystemDefault) {
      // Use system locale
      final systemLocale = PlatformDispatcher.instance.locale;
      state = LocaleState(
        locale: _getSupportedLocale(systemLocale),
        isSystemDefault: true,
      );
    } else {
      // Use saved locale
      final savedLanguageCode = prefs.getString(_localeKey);
      if (savedLanguageCode != null) {
        state = LocaleState(
          locale: Locale(savedLanguageCode),
          isSystemDefault: false,
        );
      } else {
        // Fallback to system locale
        final systemLocale = PlatformDispatcher.instance.locale;
        state = LocaleState(
          locale: _getSupportedLocale(systemLocale),
          isSystemDefault: true,
        );
      }
    }
  }

  /// Set locale manually (user selection)
  Future<void> setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
    await prefs.setBool(_systemDefaultKey, false);

    state = LocaleState(
      locale: locale,
      isSystemDefault: false,
    );
  }

  /// Use system default locale
  Future<void> useSystemDefault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_systemDefaultKey, true);
    await prefs.remove(_localeKey);

    final systemLocale = PlatformDispatcher.instance.locale;
    state = LocaleState(
      locale: _getSupportedLocale(systemLocale),
      isSystemDefault: true,
    );
  }

  /// Get supported locale from system locale
  Locale _getSupportedLocale(Locale systemLocale) {
    // Supported language codes
    const supportedLanguages = ['zh', 'en'];

    if (supportedLanguages.contains(systemLocale.languageCode)) {
      return Locale(systemLocale.languageCode);
    }

    // Default to Chinese
    return const Locale('zh');
  }

  /// Clear saved preferences
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_localeKey);
    await prefs.remove(_systemDefaultKey);

    state = const LocaleState();
  }
}

/// Provider for locale management
final localeProvider = StateNotifierProvider<LocaleNotifier, LocaleState>((ref) {
  return LocaleNotifier();
});
