import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stock_master/viewmodels/language_viewmodel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LanguageViewModel Tests', () {
    test('Initial locale should be English (default) or loaded from prefs', () async {
      SharedPreferences.setMockInitialValues({}); // Empty prefs
      final viewModel = LanguageViewModel();
      
      // Wait for async load if necessary, though constructor triggers it.
      // Since _loadLocale is async but called in constructor without await, 
      // we might need a small delay or trust the default. 
      // Actually, better to test changeLocale which is clearer.
      
      expect(viewModel.locale.languageCode, 'en');
    });

    test('changeLocale should update locale and notify listeners', () async {
      SharedPreferences.setMockInitialValues({});
      final viewModel = LanguageViewModel();
      bool notified = false;
      viewModel.addListener(() {
        notified = true;
      });

      await viewModel.changeLocale(const Locale('fr'));

      expect(viewModel.locale.languageCode, 'fr');
      expect(notified, true);
    });

    test('translate should return correct string for English', () {
      final viewModel = LanguageViewModel(); // Default en
      expect(viewModel.translate('dashboard'), 'Dashboard');
      expect(viewModel.translate('settings'), 'Settings');
    });

    test('translate should return correct string for French after switch', () async {
      SharedPreferences.setMockInitialValues({});
      final viewModel = LanguageViewModel();
      await viewModel.changeLocale(const Locale('fr'));
      
      expect(viewModel.translate('dashboard'), 'Tableau de bord');
      expect(viewModel.translate('settings'), 'Paramètres');
    });

    test('translate should fallback to key if missing', () {
      final viewModel = LanguageViewModel();
      expect(viewModel.translate('non_existent_key'), 'non_existent_key');
    });
  });
}
