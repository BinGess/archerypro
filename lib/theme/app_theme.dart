import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

class AppTheme {
  AppTheme._();

  static final ThemeData lightTheme = _buildLightTheme();

  static ThemeData _buildLightTheme() {
    final colorScheme = const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.backgroundLight,
      error: AppColors.danger,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.textSlate900,
      onError: Colors.white,
    );

    final baseTextTheme = GoogleFonts.notoSansScTextTheme();
    final textTheme = baseTextTheme.copyWith(
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        fontSize: AppTextStyles.appBarTitle.fontSize,
        fontWeight: AppTextStyles.appBarTitle.fontWeight,
        color: AppColors.textSlate900,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        fontSize: AppTextStyles.cardSectionTitle.fontSize,
        fontWeight: AppTextStyles.cardSectionTitle.fontWeight,
        color: AppColors.textSlate900,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        fontSize: AppTextStyles.body.fontSize,
        height: AppTextStyles.body.height,
        color: AppColors.textSlate700,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        fontSize: 13,
        height: 1.4,
        color: AppColors.textSlate500,
      ),
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        fontSize: AppTextStyles.primaryButton.fontSize,
        fontWeight: AppTextStyles.primaryButton.fontWeight,
      ),
      labelMedium: baseTextTheme.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
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
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        titleTextStyle: AppTextStyles.appBarTitle,
        iconTheme: IconThemeData(
          color: AppColors.textSlate900,
          size: 22,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.cardBackground,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSlate400,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: AppTextStyles.navSelected,
        unselectedLabelStyle: AppTextStyles.navUnselected,
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
          textStyle: AppTextStyles.primaryButton,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(44, 44),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
