import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/database_helper.dart';

class AuthViewModel extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAdmin => _currentUser?.role == 'admin';

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    final role = prefs.getString('role');

    if (username != null && role != null) {
      // Restore session (simulate JWT validation)
      _currentUser = User(
        username: username,
        role: role,
        passwordHash: '', // Not needed for session
      );
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = await DatabaseHelper.instance.getUserByUsername(username);
      if (user == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final inputHash = sha256.convert(utf8.encode(password)).toString();
      if (user.passwordHash == inputHash) {
        _currentUser = user;
        
        // Save session
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', user.username);
        await prefs.setString('role', user.role);
        // Simulate JWT Token
        final token = base64Encode(utf8.encode("${user.username}:${DateTime.now().toIso8601String()}"));
        await prefs.setString('jwt_token', token);

        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("Login error: $e");
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }
}
