import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class SettingsViewModel extends ChangeNotifier {
  String _currency = 'USD';
  String? _companyLogoPath;
  static const String _currencyKey = 'selected_currency';
  static const String _logoKey = 'company_logo_path';

  String get currency => _currency;
  String? get companyLogoPath => _companyLogoPath;

  SettingsViewModel() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _currency = prefs.getString(_currencyKey) ?? 'USD';
    _companyLogoPath = prefs.getString(_logoKey);
    notifyListeners();
  }

  Future<void> setCurrency(String newCurrency) async {
    if (_currency == newCurrency) return;
    _currency = newCurrency;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, _currency);
  }

  Future<void> setCompanyLogo(String path) async {
    if (_companyLogoPath == path) return;
    _companyLogoPath = path;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_logoKey, _companyLogoPath!);
  }

  String formatPrice(double price) {
    final format = NumberFormat.currency(
      symbol: _getSymbol(_currency),
      decimalDigits: 2,
      customPattern: _currency == 'MAD' ? '#,##0.00 \u00A4' : null, // \u00A4 is the symbol placeholder
    );
    return format.format(price);
  }

  String _getSymbol(String currencyCode) {
    switch (currencyCode) {
      case 'MAD': return 'DH';
      case 'EUR': return '€';
      case 'USD': return '\$';
      default: return '\$';
    }
  }
}
