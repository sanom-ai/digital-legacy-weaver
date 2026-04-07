import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color ivory = Color(0xFFF6F1E9);
  static const Color onyx = Color(0xFF1B1A17);
  static const Color sand = Color(0xFFE5D7C5);
  static const Color bronze = Color(0xFF8B6A46);
  static const Color forest = Color(0xFF2E4A3F);
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

    return base.copyWith(
      visualDensity: VisualDensity.standard,
      scaffoldBackgroundColor: ivory,
      colorScheme: ColorScheme.fromSeed(
        seedColor: bronze,
        brightness: Brightness.light,
        primary: bronze,
        secondary: forest,
        surface: ivory,
      ),
      textTheme: textTheme,
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white.withValues(alpha: 0.96),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0x33C8B69F), width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: onyx,
        elevation: 0,
        centerTitle: false,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
        elevation: 1.2,
        surfaceTintColor: Colors.transparent,
        shadowColor: const Color(0x220E0A06),
        color: Colors.white.withValues(alpha: 0.75),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0x33C8B69F), width: 0.9),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.8),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        isDense: false,
        helperMaxLines: 2,
        floatingLabelStyle: const TextStyle(
          color: warmOutlineFocused,
          fontWeight: FontWeight.w600,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: warmOutline, width: 1.1),
          borderRadius: BorderRadius.circular(14),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: warmOutlineFocused, width: 1.6),
          borderRadius: BorderRadius.circular(14),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red.shade300, width: 1.2),
          borderRadius: BorderRadius.circular(14),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red.shade500, width: 1.6),
          borderRadius: BorderRadius.circular(14),
        ),
        border: OutlineInputBorder(
          borderSide: const BorderSide(color: warmOutline, width: 1.1),
          borderRadius: BorderRadius.circular(14),
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
        side: const BorderSide(color: warmOutline, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          minimumSize: const Size(0, 46),
          tapTargetSize: MaterialTapTargetSize.padded,
          backgroundColor: bronze,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: GoogleFonts.notoSerifThai(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onyx,
          minimumSize: const Size(0, 44),
          tapTargetSize: MaterialTapTargetSize.padded,
          side: const BorderSide(color: warmOutline, width: 1.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          textStyle: GoogleFonts.notoSerifThai(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      expansionTileTheme: ExpansionTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
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
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: GoogleFonts.notoSerifThai(
          color: onyx,
          fontSize: 14,
        ),
        menuStyle: MenuStyle(
          backgroundColor:
              WidgetStatePropertyAll(Colors.white.withValues(alpha: 0.98)),
          side: const WidgetStatePropertyAll(
            BorderSide(color: warmOutline, width: 1),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: Colors.white.withValues(alpha: 0.98),
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: warmOutline, width: 1),
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
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          side: BorderSide(color: Color(0x33C8B69F), width: 1),
        ),
      ),
    );
  }
}
