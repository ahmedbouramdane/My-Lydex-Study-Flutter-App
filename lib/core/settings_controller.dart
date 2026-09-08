import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme preference, independent of Flutter's own ThemeMode enum so the
/// settings page can offer a System / Light / Dark choice.
enum AppThemeMode { system, light, dark }

/// Central application state. Owned by [MyApp] and shared with the home page,
/// the drawer and the settings page via the widget tree.
///
/// Values (theme mode, last visited section) are persisted through
/// [SharedPreferences], so they survive app restarts.
class SettingsController extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _sectionKey = 'last_section';
  static const String _verifiedKey = 'access_verified';

  /// Hard cutoff date: after this day, nobody can enter the app, even with a
  /// valid code.
  static final DateTime accessExpiry = DateTime(2027, 1, 1);

  /// The code students must enter to unlock the app.
  static const String accessCode = 'lydex-de-rabat-students';

  AppThemeMode _themeMode = AppThemeMode.light;
  int _lastSection = 0;
  bool _verified = false;
  late final SharedPreferences _prefs;

  AppThemeMode get themeMode => _themeMode;
  int get lastSection => _lastSection;

  /// Whether access has already been granted on this device.
  bool get isVerified => _verified;

  /// Whether the free-access period has ended for everyone.
  bool get isExpired => DateTime.now().isAfter(accessExpiry);

  /// `true` when the app is unlocked and still within the free-access period.
  bool get hasAccess => isVerified && !isExpired;

  /// Loads persisted settings. Call once before building the app.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    final storedTheme = _prefs.getString(_themeKey);
    if (storedTheme != null) {
      _themeMode = AppThemeMode.values.firstWhere(
        (mode) => mode.name == storedTheme,
        orElse: () => AppThemeMode.light,
      );
    }
    _lastSection = _prefs.getInt(_sectionKey) ?? 0;
    _verified = _prefs.getBool(_verifiedKey) ?? false;

    notifyListeners();
  }

  /// Stores that the user entered the correct code on this device so the
  /// verification page is not shown again until the access period expires.
  Future<void> markVerified() async {
    _verified = true;
    notifyListeners();
    await _prefs.setBool(_verifiedKey, true);
  }

  ThemeMode get flutterThemeMode {
    switch (_themeMode) {
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
    }
  }

  /// Resolves to `true` when the effective theme is dark, given the platform's
  /// brightness. Used to keep the website (WebView) in sync with Flutter.
  bool isDark(BuildContext context) {
    switch (_themeMode) {
      case AppThemeMode.dark:
        return true;
      case AppThemeMode.light:
        return false;
      case AppThemeMode.system:
        return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    }
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    await _prefs.setString(_themeKey, mode.name);
  }

  /// Quick toggle between light and dark (used by the app bar button).
  Future<void> toggleLightDark() async {
    _themeMode = _themeMode == AppThemeMode.dark
        ? AppThemeMode.light
        : AppThemeMode.dark;
    notifyListeners();
    await _prefs.setString(_themeKey, _themeMode.name);
  }

  Future<void> setLastSection(int index) async {
    if (index == _lastSection) return;
    _lastSection = index;
    notifyListeners();
    await _prefs.setInt(_sectionKey, index);
  }
}
