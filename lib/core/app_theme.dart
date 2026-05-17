import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  // ── ✅ FIX 1: main.dart compatibility ─────────────
  static ThemeData get lightTheme => light;
  static ThemeData get darkTheme => dark;

  // ── ✅ FIX 2: _SplashGate compatibility ───────────
  static const Color primaryColor = AppColors.primary;

  // ── Gujarati Text Style Helper ────────────────────
  static TextStyle gujarati({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
    double height = 1.4,
    double? letterSpacing,
  }) =>
      GoogleFonts.notoSansGujarati(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  // ════════════════════════════════════════════════════
  // LIGHT THEME
  // ════════════════════════════════════════════════════
  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);

    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ).copyWith(
        primary: AppColors.primary,
        primaryContainer: AppColors.primarySurface,
        secondary: AppColors.accent,
        surface: Colors.white,
        onSurface: const Color(0xFF28251D),
        onPrimary: Colors.white,
        error: AppColors.expense,
      ),
      scaffoldBackgroundColor: const Color(0xFFF7F6F2),

      // ── Text Theme ──────────────────────────────────
      textTheme: GoogleFonts.notoSansGujaratiTextTheme(
        base.textTheme,
      ).copyWith(
        displayLarge: GoogleFonts.notoSansGujarati(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF28251D),
          height: 1.2,
        ),
        displayMedium: GoogleFonts.notoSansGujarati(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF28251D),
          height: 1.2,
        ),
        displaySmall: GoogleFonts.notoSansGujarati(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF28251D),
        ),
        headlineLarge: GoogleFonts.notoSansGujarati(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF28251D),
        ),
        headlineMedium: GoogleFonts.notoSansGujarati(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF28251D),
        ),
        headlineSmall: GoogleFonts.notoSansGujarati(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF28251D),
        ),
        titleLarge: GoogleFonts.notoSansGujarati(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF28251D),
        ),
        titleMedium: GoogleFonts.notoSansGujarati(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF28251D),
        ),
        titleSmall: GoogleFonts.notoSansGujarati(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF7A7974),
        ),
        bodyLarge: GoogleFonts.notoSansGujarati(
          fontSize: 15,
          fontWeight: FontWeight.normal,
          color: const Color(0xFF28251D),
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.notoSansGujarati(
          fontSize: 13,
          fontWeight: FontWeight.normal,
          color: const Color(0xFF28251D),
          height: 1.5,
        ),
        bodySmall: GoogleFonts.notoSansGujarati(
          fontSize: 11,
          fontWeight: FontWeight.normal,
          color: const Color(0xFF7A7974),
          height: 1.4,
        ),
        labelLarge: GoogleFonts.notoSansGujarati(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF28251D),
        ),
        labelMedium: GoogleFonts.notoSansGujarati(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF7A7974),
        ),
        labelSmall: GoogleFonts.notoSansGujarati(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF7A7974),
          letterSpacing: 0.4,
        ),
      ),

      // ── AppBar ──────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFFF7F6F2),
        foregroundColor: const Color(0xFF28251D),
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        shadowColor: Colors.black12,
        titleTextStyle: GoogleFonts.notoSansGujarati(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF28251D),
        ),
        iconTheme: const IconThemeData(
          color: AppColors.primary,
          size: 22,
        ),
        actionsIconTheme: const IconThemeData(
          color: AppColors.primary,
          size: 22,
        ),
      ),

      // ── Card ────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200),
        ),
      ),

      // ── Input Decoration ────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.expense, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.expense, width: 2),
        ),
        labelStyle: GoogleFonts.notoSansGujarati(
          fontSize: 13,
          color: const Color(0xFF7A7974),
        ),
        hintStyle: GoogleFonts.notoSansGujarati(
          fontSize: 13,
          color: Colors.grey.shade400,
        ),
        errorStyle: GoogleFonts.notoSansGujarati(
          fontSize: 11,
          color: AppColors.expense,
        ),
        prefixIconColor: AppColors.primary,
        suffixIconColor: Colors.grey,
        floatingLabelStyle: GoogleFonts.notoSansGujarati(
          fontSize: 13,
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),

      // ── Elevated Button ─────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade200,
          disabledForegroundColor: Colors.grey.shade400,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.notoSansGujarati(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),

      // ── Text Button ─────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: GoogleFonts.notoSansGujarati(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),

      // ── Outlined Button ─────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.notoSansGujarati(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),

      // ── Tab Bar ─────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: Colors.grey.shade500,
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: GoogleFonts.notoSansGujarati(
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        unselectedLabelStyle: GoogleFonts.notoSansGujarati(
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
      ),

      // ── Bottom Navigation Bar ────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey.shade400,
        elevation: 12,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: GoogleFonts.notoSansGujarati(
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
        unselectedLabelStyle: GoogleFonts.notoSansGujarati(
          fontSize: 10,
        ),
      ),

      // ── FAB ─────────────────────────────────────────
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),

      // ── Segmented Button ────────────────────────────
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStateProperty.all(
            GoogleFonts.notoSansGujarati(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? AppColors.primarySurface
                : Colors.transparent,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? AppColors.primary
                : Colors.grey.shade500,
          ),
          side: WidgetStateProperty.all(
            const BorderSide(color: AppColors.primary, width: 1),
          ),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ),

      // ── Chip ────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF3F0EC),
        selectedColor: AppColors.primarySurface,
        labelStyle: GoogleFonts.notoSansGujarati(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),

      // ── Dialog ──────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: GoogleFonts.notoSansGujarati(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF28251D),
        ),
        contentTextStyle: GoogleFonts.notoSansGujarati(
          fontSize: 13,
          color: const Color(0xFF7A7974),
          height: 1.5,
        ),
      ),

      // ── Bottom Sheet ────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        showDragHandle: true,
        dragHandleColor: Color(0xFFDCD9D5),
        dragHandleSize: Size(40, 4),
        modalElevation: 16,
        clipBehavior: Clip.antiAlias,
      ),

      // ── List Tile ───────────────────────────────────
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        titleTextStyle: GoogleFonts.notoSansGujarati(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF28251D),
        ),
        subtitleTextStyle: GoogleFonts.notoSansGujarati(
          fontSize: 12,
          color: const Color(0xFF7A7974),
        ),
        iconColor: AppColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // ── Switch ──────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.primary
              : Colors.grey.shade400,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.primarySurface
              : Colors.grey.shade200,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      // ── Checkbox ────────────────────────────────────
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.primary
              : Colors.transparent,
        ),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: const BorderSide(color: AppColors.primary, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),

      // ── Divider ─────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade200,
        thickness: 1,
        space: 1,
      ),

      // ── SnackBar ────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF28251D),
        contentTextStyle: GoogleFonts.notoSansGujarati(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),

      // ── Progress Indicator ──────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.primarySurface,
      ),

      // ── Icon ────────────────────────────────────────
      iconTheme: const IconThemeData(
        color: Color(0xFF28251D),
        size: 22,
      ),
    );
  }

  // ════════════════════════════════════════════════════
  // DARK THEME
  // ════════════════════════════════════════════════════
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
      ).copyWith(
        primary: const Color(0xFF4F98A3),
        primaryContainer: const Color(0xFF313B3B),
        secondary: const Color(0xFF5591C7),
        surface: const Color(0xFF1C1B19),
        onSurface: const Color(0xFFCDCCCA),
        onPrimary: Colors.white,
        error: const Color(0xFFDD6974),
      ),
      scaffoldBackgroundColor: const Color(0xFF171614),

      // ── Text Theme ──────────────────────────────────
      textTheme: GoogleFonts.notoSansGujaratiTextTheme(
        base.textTheme,
      ).copyWith(
        displayLarge: GoogleFonts.notoSansGujarati(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: const Color(0xFFCDCCCA),
          height: 1.2,
        ),
        displayMedium: GoogleFonts.notoSansGujarati(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: const Color(0xFFCDCCCA),
        ),
        displaySmall: GoogleFonts.notoSansGujarati(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: const Color(0xFFCDCCCA),
        ),
        headlineLarge: GoogleFonts.notoSansGujarati(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: const Color(0xFFCDCCCA),
        ),
        headlineMedium: GoogleFonts.notoSansGujarati(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: const Color(0xFFCDCCCA),
        ),
        headlineSmall: GoogleFonts.notoSansGujarati(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: const Color(0xFFCDCCCA),
        ),
        titleLarge: GoogleFonts.notoSansGujarati(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: const Color(0xFFCDCCCA),
        ),
        titleMedium: GoogleFonts.notoSansGujarati(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: const Color(0xFFCDCCCA),
        ),
        titleSmall: GoogleFonts.notoSansGujarati(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF797876),
        ),
        bodyLarge: GoogleFonts.notoSansGujarati(
          fontSize: 15,
          color: const Color(0xFFCDCCCA),
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.notoSansGujarati(
          fontSize: 13,
          color: const Color(0xFFCDCCCA),
          height: 1.5,
        ),
        bodySmall: GoogleFonts.notoSansGujarati(
          fontSize: 11,
          color: const Color(0xFF797876),
          height: 1.4,
        ),
        labelLarge: GoogleFonts.notoSansGujarati(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: const Color(0xFFCDCCCA),
        ),
        labelMedium: GoogleFonts.notoSansGujarati(
          fontSize: 11,
          color: const Color(0xFF797876),
        ),
        labelSmall: GoogleFonts.notoSansGujarati(
          fontSize: 10,
          color: const Color(0xFF797876),
          letterSpacing: 0.4,
        ),
      ),

      // ── AppBar ──────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF171614),
        foregroundColor: const Color(0xFFCDCCCA),
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: GoogleFonts.notoSansGujarati(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: const Color(0xFFCDCCCA),
        ),
        iconTheme: const IconThemeData(
          color: Color(0xFF4F98A3),
          size: 22,
        ),
        actionsIconTheme: const IconThemeData(
          color: Color(0xFF4F98A3),
          size: 22,
        ),
      ),

      // ── Card ────────────────────────────────────────
      cardTheme: const CardThemeData(
        elevation: 0,
        color: Color(0xFF1C1B19),
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: Color(0xFF393836)),
        ),
      ),

      // ── Input Decoration ────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1C1B19),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF393836)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF393836)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4F98A3), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDD6974)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDD6974), width: 2),
        ),
        labelStyle: GoogleFonts.notoSansGujarati(
          fontSize: 13,
          color: const Color(0xFF797876),
        ),
        hintStyle: GoogleFonts.notoSansGujarati(
          fontSize: 13,
          color: const Color(0xFF5A5957),
        ),
        errorStyle: GoogleFonts.notoSansGujarati(
          fontSize: 11,
          color: const Color(0xFFDD6974),
        ),
        prefixIconColor: const Color(0xFF4F98A3),
        suffixIconColor: const Color(0xFF797876),
        floatingLabelStyle: GoogleFonts.notoSansGujarati(
          fontSize: 13,
          color: const Color(0xFF4F98A3),
          fontWeight: FontWeight.w600,
        ),
      ),

      // ── Elevated Button ─────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4F98A3),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF2D2C2A),
          disabledForegroundColor: const Color(0xFF5A5957),
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.notoSansGujarati(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),

      // ── Text Button ─────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF4F98A3),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: GoogleFonts.notoSansGujarati(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),

      // ── Outlined Button ─────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF4F98A3),
          side: const BorderSide(color: Color(0xFF4F98A3), width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.notoSansGujarati(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),

      // ── Tab Bar ─────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor: const Color(0xFF4F98A3),
        unselectedLabelColor: const Color(0xFF797876),
        indicatorColor: const Color(0xFF4F98A3),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: GoogleFonts.notoSansGujarati(
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        unselectedLabelStyle: GoogleFonts.notoSansGujarati(
          fontSize: 13,
        ),
      ),

      // ── Bottom Navigation Bar ────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: const Color(0xFF1C1B19),
        selectedItemColor: const Color(0xFF4F98A3),
        unselectedItemColor: const Color(0xFF797876),
        elevation: 12,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: GoogleFonts.notoSansGujarati(
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
        unselectedLabelStyle: GoogleFonts.notoSansGujarati(
          fontSize: 10,
        ),
      ),

      // ── FAB ─────────────────────────────────────────
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF4F98A3),
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),

      // ── Segmented Button ────────────────────────────
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStateProperty.all(
            GoogleFonts.notoSansGujarati(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? const Color(0xFF313B3B)
                : Colors.transparent,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? const Color(0xFF4F98A3)
                : const Color(0xFF797876),
          ),
          side: WidgetStateProperty.all(
            const BorderSide(color: Color(0xFF4F98A3), width: 1),
          ),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ),

      // ── Chip ────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF2D2C2A),
        selectedColor: const Color(0xFF313B3B),
        labelStyle: GoogleFonts.notoSansGujarati(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: const Color(0xFFCDCCCA),
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),

      // ── Dialog ──────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF1C1B19),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: GoogleFonts.notoSansGujarati(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: const Color(0xFFCDCCCA),
        ),
        contentTextStyle: GoogleFonts.notoSansGujarati(
          fontSize: 13,
          color: const Color(0xFF797876),
          height: 1.5,
        ),
      ),

      // ── Bottom Sheet ────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF1C1B19),
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        showDragHandle: true,
        dragHandleColor: Color(0xFF393836),
        dragHandleSize: Size(40, 4),
        modalElevation: 16,
        clipBehavior: Clip.antiAlias,
      ),

      // ── List Tile ───────────────────────────────────
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        titleTextStyle: GoogleFonts.notoSansGujarati(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: const Color(0xFFCDCCCA),
        ),
        subtitleTextStyle: GoogleFonts.notoSansGujarati(
          fontSize: 12,
          color: const Color(0xFF797876),
        ),
        iconColor: const Color(0xFF4F98A3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // ── Switch ──────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? const Color(0xFF4F98A3)
              : const Color(0xFF5A5957),
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? const Color(0xFF313B3B)
              : const Color(0xFF2D2C2A),
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      // ── Checkbox ────────────────────────────────────
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? const Color(0xFF4F98A3)
              : Colors.transparent,
        ),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: const BorderSide(color: Color(0xFF4F98A3), width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),

      // ── Divider ─────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: Color(0xFF262523),
        thickness: 1,
        space: 1,
      ),

      // ── SnackBar ────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF2D2C2A),
        contentTextStyle: GoogleFonts.notoSansGujarati(
          color: const Color(0xFFCDCCCA),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),

      // ── Progress Indicator ──────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Color(0xFF4F98A3),
        linearTrackColor: Color(0xFF313B3B),
      ),

      // ── Icon ────────────────────────────────────────
      iconTheme: const IconThemeData(
        color: Color(0xFFCDCCCA),
        size: 22,
      ),
    );
  }
}
