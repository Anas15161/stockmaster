import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_translations.dart';

class LanguageViewModel extends ChangeNotifier {
  Locale _locale = const Locale('en');
  static const String _prefKey = 'selected_language';

  Locale get locale => _locale;

  LanguageViewModel() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final String? langCode = prefs.getString(_prefKey);
    if (langCode != null) {
      _locale = Locale(langCode);
      notifyListeners();
    }
  }

  Future<void> changeLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, locale.languageCode);
  }

  String translate(String key) {
    final Map<String, String>? localizedStrings = AppTranslations.translations[_locale.languageCode];
    if (localizedStrings != null && localizedStrings.containsKey(key)) {
      return localizedStrings[key]!;
    }
    // Fallback to English if key missing in current locale
    return AppTranslations.translations['en']?[key] ?? key;
  }
}
