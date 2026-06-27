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
  
  List<String> _permissions = [];
  List<String> get permissions => _permissions;

  bool hasPermission(String permission) {
    return _permissions.contains(permission);
  }

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    final role = prefs.getString('role');
    final email = prefs.getString('email') ?? '';

    if (username != null && role != null) {
      // Restore session (simulate JWT validation)
      _currentUser = User(
        username: username,
        role: role,
        email: email,
        passwordHash: '', // Not needed for session
      );
      _permissions = await DatabaseHelper.instance.getPermissionsForRole(role);
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
        _permissions = await DatabaseHelper.instance.getPermissionsForRole(user.role);
        
        // Save session
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', user.username);
        await prefs.setString('role', user.role);
        await prefs.setString('email', user.email);
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

  Future<String?> register(String username, String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final existingUser = await DatabaseHelper.instance.getUserByUsername(username);
      if (existingUser != null) {
        _isLoading = false;
        notifyListeners();
        return "Username already taken";
      }

      final newUser = User(
        username: username,
        email: email,
        passwordHash: '', // Set by helper
        role: 'employee', // Default role
      );

      await DatabaseHelper.instance.createUser(newUser, password);
      
      _isLoading = false;
      notifyListeners();
      return null; // Success
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return "Registration failed: $e";
    }
  }

  // --- Password Reset Logic ---
  final Map<String, String> _resetCodes = {};

  Future<bool> sendPasswordResetCode(String email) async {
    _isLoading = true;
    notifyListeners();
    
    final user = await DatabaseHelper.instance.getUserByEmail(email);
    if (user == null) {
      _isLoading = false;
      notifyListeners();
      return false; // Email not found
    }

    // Generate mock code
    const code = "123456"; 
    _resetCodes[email] = code;
    
    // In a real app, send email here.
    debugPrint("Reset code for $email: $code");
    
    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> verifyAndResetPassword(String email, String code, String newPassword) async {
    _isLoading = true;
    notifyListeners();

    if (_resetCodes[email] != code) {
      _isLoading = false;
      notifyListeners();
      return false; // Invalid code
    }

    final user = await DatabaseHelper.instance.getUserByEmail(email);
    if (user != null) {
      await DatabaseHelper.instance.updateUser(user, newPassword);
      _resetCodes.remove(email);
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    _currentUser = null;
    _permissions = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }
}
