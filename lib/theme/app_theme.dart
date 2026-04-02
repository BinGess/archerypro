import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

class AppTheme {
  AppTheme._();

  static const List<String> _cjkFallback = [
    'Noto Sans SC',
    'PingFang SC',
    'Hiragino Sans GB',
    'Microsoft YaHei',
    'sans-serif',
  ];

  static final ThemeData lightTheme = _buildLightTheme();

  static TextStyle _body(TextStyle? base) {
    return GoogleFonts.notoSansSc(
      textStyle: (base ?? const TextStyle()).copyWith(
        fontFamilyFallback: _cjkFallback,
      ),
    );
  }

  static TextStyle _display(TextStyle? base) {
    return GoogleFonts.barlowSemiCondensed(
      textStyle: (base ?? const TextStyle()).copyWith(
        fontFamilyFallback: _cjkFallback,
      ),
    );
  }

  static TextStyle _numeric(TextStyle? base) {
    return GoogleFonts.robotoMono(
      textStyle: (base ?? const TextStyle()).copyWith(
        fontFamilyFallback: _cjkFallback,
      ),
    );
  }

  static ThemeData _buildLightTheme() {
    const colorScheme = ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.backgroundLight,
      error: AppColors.danger,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.textSlate900,
      onError: Colors.white,
    );

    final baseTextTheme =
        GoogleFonts.notoSansScTextTheme(ThemeData.light().textTheme).apply(
            bodyColor: AppColors.textSlate900,
            displayColor: AppColors.textSlate900);
    final textTheme = baseTextTheme.copyWith(
      displayLarge: _display(baseTextTheme.displayLarge).copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
      ),
      displayMedium: _display(baseTextTheme.displayMedium).copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      displaySmall: _display(baseTextTheme.displaySmall).copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.15,
      ),
      headlineLarge: _display(baseTextTheme.headlineLarge).copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.15,
      ),
      headlineMedium: _display(baseTextTheme.headlineMedium).copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.1,
      ),
      headlineSmall: _display(baseTextTheme.headlineSmall).copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.05,
      ),
      titleLarge: _display(baseTextTheme.titleLarge).copyWith(
        fontSize: AppTextStyles.appBarTitle.fontSize,
        fontWeight: AppTextStyles.appBarTitle.fontWeight,
        color: AppColors.textSlate900,
      ),
      titleMedium: _display(baseTextTheme.titleMedium).copyWith(
        fontSize: AppTextStyles.cardSectionTitle.fontSize,
        fontWeight: AppTextStyles.cardSectionTitle.fontWeight,
        color: AppColors.textSlate900,
      ),
      bodyLarge: _body(baseTextTheme.bodyLarge).copyWith(
        fontSize: AppTextStyles.body.fontSize,
        fontWeight: AppTextStyles.body.fontWeight,
        height: AppTextStyles.body.height,
        color: AppColors.textSlate700,
      ),
      bodyMedium: _body(baseTextTheme.bodyMedium).copyWith(
        fontSize: 13,
        height: 1.4,
        color: AppColors.textSlate500,
      ),
      labelLarge: _display(baseTextTheme.labelLarge).copyWith(
        fontSize: AppTextStyles.primaryButton.fontSize,
        fontWeight: AppTextStyles.primaryButton.fontWeight,
        letterSpacing: AppTextStyles.primaryButton.letterSpacing,
      ),
      labelMedium: _body(baseTextTheme.labelMedium).copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textSlate500,
      ),
      bodySmall: _numeric(baseTextTheme.bodySmall).copyWith(
        color: AppColors.textSlate500,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      textTheme: textTheme,
      dividerTheme: const DividerThemeData(
        color: AppColors.borderLight,
        thickness: 1,
        space: 1,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.cardBackground,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.lg)),
          side: BorderSide(color: AppColors.borderLight),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        titleTextStyle: _display(textTheme.titleLarge).copyWith(
          fontSize: AppTextStyles.appBarTitle.fontSize,
          fontWeight: AppTextStyles.appBarTitle.fontWeight,
          color: AppColors.textSlate900,
          letterSpacing: AppTextStyles.appBarTitle.letterSpacing,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.textSlate900,
          size: 22,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.cardBackground,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSlate400,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: _display(textTheme.labelSmall).copyWith(
          fontSize: AppTextStyles.navSelected.fontSize,
          fontWeight: AppTextStyles.navSelected.fontWeight,
          letterSpacing: 0.1,
        ),
        unselectedLabelStyle: _body(textTheme.labelSmall).copyWith(
          fontSize: AppTextStyles.navUnselected.fontSize,
          fontWeight: AppTextStyles.navUnselected.fontWeight,
          letterSpacing: 0.05,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.surfaceMid,
          elevation: 0,
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          textStyle: _display(textTheme.labelLarge).copyWith(
            fontSize: AppTextStyles.primaryButton.fontSize,
            fontWeight: AppTextStyles.primaryButton.fontWeight,
            letterSpacing: AppTextStyles.primaryButton.letterSpacing,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(44, 44),
          textStyle: _body(textTheme.labelLarge).copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceSubtle,
        selectedColor: AppColors.primary.withValues(alpha: 0.12),
        side: const BorderSide(color: AppColors.borderLight),
        labelStyle: textTheme.labelMedium ?? const TextStyle(fontSize: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardBackground,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      visualDensity: VisualDensity.standard,
    );
  }
}
