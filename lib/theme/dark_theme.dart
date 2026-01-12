import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glow/theme/colors.dart';

/// Padding for snackbars on the home screen to ensure they appear below the FAB
const EdgeInsets kHomeScreenSnackBarPadding = EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0);

/// Theme extension for warning box colors
class WarningBoxTheme extends ThemeExtension<WarningBoxTheme> {
  const WarningBoxTheme({
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
  });

  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;

  @override
  WarningBoxTheme copyWith({Color? backgroundColor, Color? borderColor, Color? textColor}) {
    return WarningBoxTheme(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      textColor: textColor ?? this.textColor,
    );
  }

  @override
  WarningBoxTheme lerp(WarningBoxTheme? other, double t) {
    if (other is! WarningBoxTheme) {
      return this;
    }
    return WarningBoxTheme(
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t)!,
      borderColor: Color.lerp(borderColor, other.borderColor, t)!,
      textColor: Color.lerp(textColor, other.textColor, t)!,
    );
  }
}

const WarningBoxTheme darkWarningBoxTheme = WarningBoxTheme(
  backgroundColor: BreezColors.warningBoxBackground,
  borderColor: BreezColors.warningBoxBorder,
  textColor: BreezColors.warningDark,
);

const ColorScheme darkColorScheme = ColorScheme.dark(
  primary: Colors.white,
  onPrimary: Colors.white,
  secondary: Colors.white,
  onSecondary: Colors.white,
  surface: BreezColors.darkBackground,
  surfaceContainer: BreezColors.darkSurface,
  error: BreezColors.warningDark,
);

const AppBarTheme darkAppBarTheme = AppBarTheme(
  centerTitle: false,
  elevation: 0,
  scrolledUnderElevation: 0,
  backgroundColor: BreezColors.darkBackground,
  foregroundColor: Colors.white,
  iconTheme: IconThemeData(color: Colors.white),
  titleTextStyle: TextStyle(color: Colors.white, fontSize: 18.0, letterSpacing: 0.22),
  systemOverlayStyle: SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarBrightness: Brightness.dark,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: BreezColors.darkBackground,
    systemStatusBarContrastEnforced: false,
  ),
);

const BottomAppBarThemeData darkBottomAppBarTheme = BottomAppBarThemeData(
  height: 60,
  elevation: 0,
  color: BreezColors.primaryLight,
);

final FilledButtonThemeData darkFilledButtonTheme = FilledButtonThemeData(
  style: FilledButton.styleFrom(
    backgroundColor: BreezColors.primaryLight,
    foregroundColor: Colors.white,
    minimumSize: const Size.fromHeight(48),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  ),
);

final ElevatedButtonThemeData darkElevatedButtonTheme = ElevatedButtonThemeData(
  style: ElevatedButton.styleFrom(
    backgroundColor: BreezColors.primaryLight,
    foregroundColor: Colors.white,
    minimumSize: const Size(0, 48),
    elevation: 0.0,
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  ),
);

final OutlinedButtonThemeData darkOutlinedButtonTheme = OutlinedButtonThemeData(
  style: OutlinedButton.styleFrom(
    side: BorderSide(color: Colors.white.withValues(alpha: .4)),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    minimumSize: const Size(0, 48),
  ),
);

const SliderThemeData darkSliderTheme = SliderThemeData(
  valueIndicatorColor: BreezColors.primaryLight,
);

const FloatingActionButtonThemeData darkFabTheme = FloatingActionButtonThemeData(
  backgroundColor: BreezColors.primaryLight,
  foregroundColor: Colors.white,
  sizeConstraints: BoxConstraints(minHeight: 64, minWidth: 64),
);

const DialogThemeData darkDialogTheme = DialogThemeData(
  backgroundColor: BreezColors.darkSurface,
  titleTextStyle: TextStyle(
    color: Colors.white,
    fontSize: 20.5,
    letterSpacing: 0.25,
    fontWeight: FontWeight.w500,
  ),
  contentTextStyle: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
);

const CardThemeData darkCardTheme = CardThemeData(
  color: BreezColors.darkSurface,
  elevation: 0,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
);

const DrawerThemeData darkDrawerTheme = DrawerThemeData(
  backgroundColor: BreezColors.darkSurface,
  scrimColor: Colors.black54,
);

final DatePickerThemeData darkDatePickerTheme = DatePickerThemeData(
  backgroundColor: BreezColors.darkSurface,
  headerBackgroundColor: BreezColors.primary,
  headerForegroundColor: Colors.white,
  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
  dayBackgroundColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
    if (states.contains(WidgetState.selected)) {
      return BreezColors.primary;
    }
    return Colors.transparent;
  }),
  dayForegroundColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
    if (states.contains(WidgetState.selected)) {
      return Colors.white;
    }
    if (states.contains(WidgetState.disabled)) {
      return Colors.white38;
    }
    return Colors.white;
  }),
  todayBorder: const BorderSide(color: BreezColors.primary),
  todayForegroundColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
    if (states.contains(WidgetState.selected)) {
      return Colors.white;
    }
    return BreezColors.primary;
  }),
);

const SnackBarThemeData darkSnackBarTheme = SnackBarThemeData(
  backgroundColor: Color(0xFF334560),
  actionTextColor: BreezColors.warningDark,
  contentTextStyle: TextStyle(
    color: Colors.white,
    fontSize: 14.0,
    letterSpacing: 0.25,
    height: 1.2,
  ),
  behavior: SnackBarBehavior.fixed,
);

const PopupMenuThemeData darkPopupMenuTheme = PopupMenuThemeData(
  color: BreezColors.darkSurface,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(5))),
);

const DropdownMenuThemeData darkDropdownMenuTheme = DropdownMenuThemeData();

const BottomSheetThemeData darkBottomSheetTheme = BottomSheetThemeData(
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
);

const ProgressIndicatorThemeData darkProgressIndicatorTheme = ProgressIndicatorThemeData(
  strokeWidth: 2.0,
  color: BreezColors.primaryLight,
  linearTrackColor: Color(0x33FFFFFF),
  circularTrackColor: Color(0x33FFFFFF),
);

/// Builds the dark theme by composing all theme components
ThemeData buildDarkTheme() {
  return ThemeData(
    useMaterial3: false,
    brightness: Brightness.dark,
    fontFamily: 'IBMPlexSans',
    colorScheme: darkColorScheme,
    scaffoldBackgroundColor: BreezColors.darkBackground,
    canvasColor: BreezColors.darkBackground,
    primaryColor: BreezColors.primary,
    primaryColorDark: BreezColors.darkBackground,
    primaryColorLight: BreezColors.primaryLight,
    cardColor: const Color(0xFF121212),
    highlightColor: BreezColors.primary,
    dividerColor: const Color(0x337aa5eb),
    appBarTheme: darkAppBarTheme,
    bottomAppBarTheme: darkBottomAppBarTheme,
    filledButtonTheme: darkFilledButtonTheme,
    elevatedButtonTheme: darkElevatedButtonTheme,
    outlinedButtonTheme: darkOutlinedButtonTheme,
    sliderTheme: darkSliderTheme,
    floatingActionButtonTheme: darkFabTheme,
    dialogTheme: darkDialogTheme,
    cardTheme: darkCardTheme,
    chipTheme: const ChipThemeData(backgroundColor: BreezColors.primary),
    drawerTheme: darkDrawerTheme,
    datePickerTheme: darkDatePickerTheme,
    snackBarTheme: darkSnackBarTheme,
    popupMenuTheme: darkPopupMenuTheme,
    dropdownMenuTheme: darkDropdownMenuTheme,
    bottomSheetTheme: darkBottomSheetTheme,
    progressIndicatorTheme: darkProgressIndicatorTheme,
    primaryIconTheme: const IconThemeData(color: Colors.white),
    textSelectionTheme: TextSelectionThemeData(
      selectionColor: Colors.white.withValues(alpha: .5),
      selectionHandleColor: BreezColors.primary,
    ),
    extensions: const <ThemeExtension<dynamic>>[darkWarningBoxTheme],
  );
}
