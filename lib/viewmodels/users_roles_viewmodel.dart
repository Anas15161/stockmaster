import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/database_helper.dart';

class UsersRolesViewModel extends ChangeNotifier {
  List<User> _users = [];
  List<String> _roles = [];
  final Map<String, List<String>> _rolePermissions = {}; // role -> permissions
  bool _isLoading = false;

  List<User> get users => _users;
  List<String> get roles => _roles;
  Map<String, List<String>> get rolePermissions => _rolePermissions;
  bool get isLoading => _isLoading;

  // --- Users ---

  Future<void> fetchUsers() async {
    _isLoading = true;
    notifyListeners();
    _users = await DatabaseHelper.instance.getAllUsers();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> createUser(String username, String password, String role) async {
    final user = User(username: username, email: "$username@stockmaster.com", role: role, passwordHash: '');
    await DatabaseHelper.instance.createUser(user, password);
    await fetchUsers();
  }

  Future<void> updateUser(User user, String? newPassword) async {
    await DatabaseHelper.instance.updateUser(user, newPassword);
    await fetchUsers();
  }

  Future<void> deleteUser(int id) async {
    await DatabaseHelper.instance.deleteUser(id);
    await fetchUsers();
  }

  // --- Roles & Permissions ---

  Future<void> fetchRoles() async {
    _roles = await DatabaseHelper.instance.getAllRoles();
    notifyListeners();
  }

  Future<void> createRole(String name) async {
    await DatabaseHelper.instance.createRole(name);
    await fetchRoles();
  }

  Future<void> deleteRole(String name) async {
    await DatabaseHelper.instance.deleteRole(name);
    await fetchRoles();
  }

  Future<void> fetchPermissionsForRole(String role) async {
    final perms = await DatabaseHelper.instance.getPermissionsForRole(role);
    _rolePermissions[role] = perms;
    notifyListeners();
  }

  Future<void> updatePermissions(String role, List<String> permissions) async {
    await DatabaseHelper.instance.updateRolePermissions(role, permissions);
    await fetchPermissionsForRole(role);
  }

  Future<void> refreshAll() async {
    await Future.wait([fetchUsers(), fetchRoles()]);
  }
}
