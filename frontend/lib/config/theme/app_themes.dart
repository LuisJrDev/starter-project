import 'package:flutter/material.dart';

/// Light and dark themes. The app follows the phone's appearance setting.
ThemeData theme() => _themeFor(Brightness.light);

ThemeData darkTheme() => _themeFor(Brightness.dark);

ThemeData _themeFor(Brightness brightness) {
  // The Material 3 baseline colors, whose purple the buttons and tabs already use.
  final colors = ThemeData(brightness: brightness).colorScheme;
  final background = brightness == Brightness.light ? Colors.white : colors.surface;
  return ThemeData(
    colorScheme: colors,
    scaffoldBackgroundColor: background,
    fontFamily: 'Muli',
    appBarTheme: appBarTheme(colors, background),
  );
}

AppBarTheme appBarTheme(ColorScheme colors, Color background) {
  return AppBarTheme(
    color: background,
    elevation: 0,
    centerTitle: true,
    iconTheme: IconThemeData(color: colors.onSurface),
    titleTextStyle: TextStyle(color: colors.onSurface, fontSize: 18),
  );
}

/// Background of an image that is loading or failed to load.
Color placeholderColorOf(BuildContext context) {
  return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08);
}
