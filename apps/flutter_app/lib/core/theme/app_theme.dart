import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color ivory = Color(0xFFF6F1E9);
  static const Color porcelain = Color(0xFFFBF8F3);
  static const Color onyx = Color(0xFF1B1A17);
  static const Color sand = Color(0xFFE5D7C5);
  static const Color bronze = Color(0xFF8B6A46);
  static const Color forest = Color(0xFF2E4A3F);
  static const Color deepTeal = Color(0xFF1E6C77);
  static const Color warmOutline = Color(0xFFD9C5AA);
  static const Color warmOutlineFocused = Color(0xFF9C7347);
  static const Color softTrack = Color(0xFFEDE2D2);

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    final textTheme =
        GoogleFonts.cormorantGaramondTextTheme(base.textTheme).copyWith(
      displayLarge: GoogleFonts.cormorantGaramond(
        color: onyx,
        fontWeight: FontWeight.w700,
      ),
      displayMedium: GoogleFonts.cormorantGaramond(
        color: onyx,
        fontWeight: FontWeight.w700,
      ),
      headlineLarge: GoogleFonts.cormorantGaramond(
        color: onyx,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: GoogleFonts.cormorantGaramond(
        color: onyx,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: GoogleFonts.notoSerifThai(
        color: onyx,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: GoogleFonts.notoSerifThai(
        color: onyx,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: GoogleFonts.notoSerifThai(fontSize: 16, color: onyx),
      bodyMedium: GoogleFonts.notoSerifThai(fontSize: 14, color: onyx),
      bodySmall: GoogleFonts.notoSerifThai(fontSize: 12, color: onyx),
      labelLarge: GoogleFonts.notoSerifThai(
        color: onyx,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: GoogleFonts.notoSerifThai(
        color: onyx,
        fontWeight: FontWeight.w600,
      ),
    );
    final scheme = ColorScheme.fromSeed(
      seedColor: bronze,
      brightness: Brightness.light,
      primary: bronze,
      secondary: forest,
      tertiary: deepTeal,
      surface: porcelain,
      surfaceContainerHighest: const Color(0xFFF2EADF),
    );

    return base.copyWith(
      visualDensity: VisualDensity.standard,
      scaffoldBackgroundColor: porcelain,
      colorScheme: scheme,
      canvasColor: Colors.white,
      textTheme: textTheme,
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white.withValues(alpha: 0.985),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
          side: BorderSide(
            color: warmOutline.withValues(alpha: 0.58),
            width: 1.15,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: onyx,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.notoSerifThai(
          color: onyx,
          fontSize: 21,
          fontWeight: FontWeight.w700,
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        iconColor: const Color(0xFF5B3E26),
        titleTextStyle: GoogleFonts.notoSerifThai(
          color: onyx,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        subtitleTextStyle: GoogleFonts.notoSerifThai(
          color: onyx.withValues(alpha: 0.82),
          fontSize: 13.5,
          height: 1.35,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: warmOutline.withValues(alpha: 0.6),
        thickness: 1,
        space: 20,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: const Color(0x140E0A06),
        color: Colors.white.withValues(alpha: 0.84),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(
            color: warmOutline.withValues(alpha: 0.48),
            width: 1.0,
          ),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.92),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        isDense: false,
        helperMaxLines: 2,
        hintStyle: GoogleFonts.notoSerifThai(
          color: onyx.withValues(alpha: 0.42),
          fontSize: 14,
        ),
        helperStyle: GoogleFonts.notoSerifThai(
          color: onyx.withValues(alpha: 0.6),
          fontSize: 12.5,
          height: 1.3,
        ),
        labelStyle: GoogleFonts.notoSerifThai(
          color: onyx.withValues(alpha: 0.78),
          fontSize: 14.5,
        ),
        floatingLabelStyle: GoogleFonts.notoSerifThai(
          color: warmOutlineFocused,
          fontWeight: FontWeight.w700,
          fontSize: 13.5,
        ),
        prefixIconColor: const Color(0xFF6F5942),
        suffixIconColor: const Color(0xFF6F5942),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: warmOutline.withValues(alpha: 0.92),
            width: 1.15,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: warmOutlineFocused, width: 1.7),
          borderRadius: BorderRadius.circular(16),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red.shade300, width: 1.2),
          borderRadius: BorderRadius.circular(16),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red.shade500, width: 1.6),
          borderRadius: BorderRadius.circular(16),
        ),
        border: OutlineInputBorder(
          borderSide: BorderSide(
            color: warmOutline.withValues(alpha: 0.92),
            width: 1.15,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: bronze,
        inactiveTrackColor: softTrack,
        secondaryActiveTrackColor: const Color(0xFFE5C7A5),
        thumbColor: const Color(0xFFF6C18B),
        overlayColor: bronze.withValues(alpha: 0.14),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
        trackHeight: 6,
        valueIndicatorColor: const Color(0xFF3D2A1B),
        showValueIndicator: ShowValueIndicator.onlyForDiscrete,
        valueIndicatorTextStyle: GoogleFonts.notoSerifThai(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: Colors.white.withValues(alpha: 0.88),
        selectedColor: const Color(0xFFF3E3C9),
        secondarySelectedColor: const Color(0xFFE3F0EE),
        disabledColor: scheme.surfaceContainerHighest,
        shadowColor: const Color(0x0A0E0A06),
        side: BorderSide(color: warmOutline.withValues(alpha: 0.85), width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        labelStyle: GoogleFonts.notoSerifThai(
          color: onyx,
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: GoogleFonts.notoSerifThai(
          color: onyx,
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
        ),
        checkmarkColor: const Color(0xFF6F4A28),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          minimumSize: const Size(0, 48),
          tapTargetSize: MaterialTapTargetSize.padded,
          backgroundColor: bronze,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          textStyle: GoogleFonts.notoSerifThai(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onyx,
          minimumSize: const Size(0, 46),
          tapTargetSize: MaterialTapTargetSize.padded,
          side: BorderSide(
              color: warmOutline.withValues(alpha: 0.9), width: 1.15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          textStyle: GoogleFonts.notoSerifThai(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF5B3E26),
          minimumSize: const Size(0, 42),
          tapTargetSize: MaterialTapTargetSize.padded,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          textStyle: GoogleFonts.notoSerifThai(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          visualDensity: VisualDensity.standard,
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.notoSerifThai(
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
            ),
          ),
          side: WidgetStateProperty.resolveWith(
            (states) => BorderSide(
              color: states.contains(WidgetState.selected)
                  ? const Color(0xFFE7C892)
                  : warmOutline.withValues(alpha: 0.72),
              width: states.contains(WidgetState.selected) ? 1.15 : 1,
            ),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
      expansionTileTheme: ExpansionTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        iconColor: const Color(0xFF5B3E26),
        collapsedIconColor: const Color(0xFF6F5942),
        textColor: onyx,
        collapsedTextColor: onyx,
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return bronze.withValues(alpha: 0.45);
          }
          return softTrack;
        }),
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF6B4A2F);
          }
          return Colors.white;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return bronze;
          }
          return Colors.white;
        }),
        side: const BorderSide(color: warmOutline, width: 1.1),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: onyx,
          backgroundColor: Colors.white.withValues(alpha: 0.72),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: warmOutline.withValues(alpha: 0.55)),
          ),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: GoogleFonts.notoSerifThai(
          color: onyx,
          fontSize: 14,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.92),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: warmOutline.withValues(alpha: 0.9),
              width: 1.15,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: warmOutline.withValues(alpha: 0.9),
              width: 1.15,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: warmOutlineFocused, width: 1.7),
          ),
        ),
        menuStyle: MenuStyle(
          backgroundColor:
              WidgetStatePropertyAll(Colors.white.withValues(alpha: 0.98)),
          side: WidgetStatePropertyAll(
            BorderSide(color: warmOutline.withValues(alpha: 0.9), width: 1),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          elevation: const WidgetStatePropertyAll(6),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(vertical: 8),
          ),
        ),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor:
              WidgetStatePropertyAll(Colors.white.withValues(alpha: 0.98)),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shadowColor: const WidgetStatePropertyAll(Color(0x140E0A06)),
          elevation: const WidgetStatePropertyAll(8),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(
                color: warmOutline.withValues(alpha: 0.75),
                width: 1,
              ),
            ),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(vertical: 8),
          ),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: Colors.white.withValues(alpha: 0.98),
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side:
              BorderSide(color: warmOutline.withValues(alpha: 0.85), width: 1),
        ),
        textStyle: GoogleFonts.notoSerifThai(
          color: onyx,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.white.withValues(alpha: 0.98),
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: Colors.white.withValues(alpha: 0.985),
        elevation: 0,
        showDragHandle: true,
        dragHandleColor: const Color(0xFFCCB797),
        dragHandleSize: const Size(44, 4),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          side: BorderSide(color: warmOutline.withValues(alpha: 0.5), width: 1),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF2F241C),
        contentTextStyle: GoogleFonts.notoSerifThai(
          color: Colors.white,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
