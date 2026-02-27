import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// State for locale management
class LocaleState {
  final Locale locale;
  final bool isSystemDefault;

  const LocaleState({
    required this.locale,
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

  String get languageCode => locale.languageCode;
}

/// Notifier for locale management with persistence
class LocaleNotifier extends StateNotifier<LocaleState> {
  static const String _localeKey = 'app_locale';
  static const String _systemDefaultKey = 'use_system_locale';
  static const Locale zhLocale = Locale('zh', 'CN');
  static const Locale enLocale = Locale('en', 'US');
  final Locale Function() _systemLocaleGetter;
  static Locale _platformLocale() => PlatformDispatcher.instance.locale;

  LocaleNotifier({Locale Function()? systemLocaleGetter})
      : _systemLocaleGetter = systemLocaleGetter ?? _platformLocale,
        super(
          LocaleState(
            locale: resolveSupportedLocale(
                (systemLocaleGetter ?? _platformLocale)()),
            isSystemDefault: true,
          ),
        );

  /// Initialize locale from saved preferences
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    final useSystemDefault = prefs.getBool(_systemDefaultKey) ?? true;
    final savedLanguageCode = prefs.getString(_localeKey);

    if (!useSystemDefault && savedLanguageCode != null) {
      state = LocaleState(
        locale: resolveSupportedLocale(Locale(savedLanguageCode)),
        isSystemDefault: false,
      );
      return;
    }

    state = LocaleState(
      locale: resolveSupportedLocale(_systemLocaleGetter()),
      isSystemDefault: true,
    );
  }

  /// Set locale manually (user selection)
  Future<void> setLocale(Locale locale) async {
    final resolvedLocale = resolveSupportedLocale(locale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, resolvedLocale.languageCode);
    await prefs.setBool(_systemDefaultKey, false);

    state = LocaleState(
      locale: resolvedLocale,
      isSystemDefault: false,
    );
  }

  /// Use system default locale
  Future<void> useSystemDefault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_systemDefaultKey, true);
    await prefs.remove(_localeKey);

    state = LocaleState(
      locale: resolveSupportedLocale(_systemLocaleGetter()),
      isSystemDefault: true,
    );
  }

  /// Refresh locale when following system language.
  void refreshSystemLocale() {
    if (!state.isSystemDefault) {
      return;
    }

    final resolvedLocale = resolveSupportedLocale(_systemLocaleGetter());
    if (state.locale.languageCode == resolvedLocale.languageCode &&
        state.locale.countryCode == resolvedLocale.countryCode) {
      return;
    }

    state = state.copyWith(locale: resolvedLocale);
  }

  /// Normalize locale to supported locales (zh/en only).
  static Locale resolveSupportedLocale(Locale systemLocale) {
    final languageCode = systemLocale.languageCode.toLowerCase();

    if (languageCode == 'zh') {
      return zhLocale;
    }
    if (languageCode == 'en') {
      return enLocale;
    }

    // Default fallback for unsupported system locales.
    return enLocale;
  }

  /// Clear saved preferences
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_localeKey);
    await prefs.remove(_systemDefaultKey);

    state = LocaleState(
      locale: resolveSupportedLocale(_systemLocaleGetter()),
      isSystemDefault: true,
    );
  }
}

/// Provider for locale management
final localeProvider =
    StateNotifierProvider<LocaleNotifier, LocaleState>((ref) {
  return LocaleNotifier();
});
