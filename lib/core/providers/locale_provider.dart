import 'package:flutter/material.dart';
import '../storage/hive_storage.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');

  LocaleProvider() {
    _loadLocale();
  }

  Locale get locale => _locale;

  Future<void> _loadLocale() async {
    final languageCode = HiveStorage.load<String>(HiveStorage.appStateBox, 'language_code', defaultValue: 'en');
    _locale = Locale(languageCode!);
    notifyListeners();
  }

  Future<void> setLocale(String languageCode) async {
    _locale = Locale(languageCode);
    await HiveStorage.save(HiveStorage.appStateBox, 'language_code', languageCode);
    notifyListeners();
  }

  static Map<String, String> getLanguageMap() {
    return {
      'English': 'en',
      'Hindi': 'hi',
      'Spanish': 'es',
      'French': 'fr',
      'German': 'de',
      'Chinese': 'zh',
      'Japanese': 'ja',
      'Arabic': 'ar',
      'Portuguese': 'pt',
      'Russian': 'ru',
    };
  }
}
