import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/language_viewmodel.dart';
import '../../viewmodels/theme_viewmodel.dart';
import '../../viewmodels/users_roles_viewmodel.dart';
import '../../models/user.dart';
import '../../utils/app_colors.dart';

class UsersRolesScreen extends StatefulWidget {
  const UsersRolesScreen({super.key});

  @override
  State<UsersRolesScreen> createState() => _UsersRolesScreenState();
}

class _UsersRolesScreenState extends State<UsersRolesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> availablePermissions = ['manage_products', 'manage_stock', 'view_reports', 'manage_users', 'manage_settings'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final languageViewModel = Provider.of<LanguageViewModel>(context);
    final themeViewModel = Provider.of<ThemeViewModel>(context);
    final usersRolesViewModel = Provider.of<UsersRolesViewModel>(context);
    final isDark = themeViewModel.themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(languageViewModel.translate('users_roles')),
        backgroundColor: AppColors.bleuStock,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: languageViewModel.translate('users')),
            Tab(text: languageViewModel.translate('roles')),
          ],
        ),
      ),
      backgroundColor: isDark ? Colors.black87 : const Color(0xFFF5F5F5),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUsersTab(usersRolesViewModel, isDark),
          _buildRolesTab(usersRolesViewModel, isDark),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.vertCroissance,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          if (_tabController.index == 0) {
            _showAddUserDialog(context, usersRolesViewModel);
          } else {
            _showAddRoleDialog(context, usersRolesViewModel);
          }
        },
      ),
    );
  }

  Widget _buildUsersTab(UsersRolesViewModel viewModel, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: viewModel.users.length,
      itemBuilder: (context, index) {
        final user = viewModel.users[index];
        return Card(
          color: isDark ? Colors.grey[900] : Colors.white,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.bleuStock.withValues(alpha: 0.2),
              child: const Icon(Icons.person, color: AppColors.bleuStock),
            ),
            title: Text(user.username, style: TextStyle(color: isDark ? Colors.white : Colors.black)),
            subtitle: Text(user.role, style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600])),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _showUserOptionsDialog(context, viewModel, user),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRolesTab(UsersRolesViewModel viewModel, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: viewModel.roles.length,
      itemBuilder: (context, index) {
        final role = viewModel.roles[index];
        return Card(
          color: isDark ? Colors.grey[900] : Colors.white,
          child: ListTile(
            leading: const Icon(Icons.security, color: AppColors.bleuStock),
            title: Text(role, style: TextStyle(color: isDark ? Colors.white : Colors.black)),
            onTap: () => _showRolePermissionsDialog(context, viewModel, role),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _showDeleteRoleDialog(context, viewModel, role),
            ),
          ),
        );
      },
    );
  }

  // --- Dialogs ---

  void _showAddUserDialog(BuildContext context, UsersRolesViewModel viewModel) {
    final userController = TextEditingController();
    final passController = TextEditingController();
    String? selectedRole = viewModel.roles.isNotEmpty ? viewModel.roles.first : null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("Add User"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: userController, decoration: const InputDecoration(labelText: "Username")),
                TextField(controller: passController, decoration: const InputDecoration(labelText: "Password"), obscureText: true),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  key: ValueKey(selectedRole),
                  initialValue: selectedRole,
                  decoration: const InputDecoration(labelText: "Role"),
                  items: viewModel.roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (val) => setState(() => selectedRole = val),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: () {
                  if (userController.text.isNotEmpty && passController.text.isNotEmpty && selectedRole != null) {
                    viewModel.createUser(userController.text, passController.text, selectedRole!);
                    Navigator.pop(ctx);
                  }
                },
                child: const Text("Create"),
              ),
            ],
          );
        }
      ),
    );
  }

  void _showUserOptionsDialog(BuildContext context, UsersRolesViewModel viewModel, User user) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text("Edit User"),
            onTap: () {
              Navigator.pop(ctx);
              _showEditUserDialog(context, viewModel, user);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text("Delete User", style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(ctx);
              _showDeleteUserDialog(context, viewModel, user);
            },
          ),
        ],
      ),
    );
  }

  void _showEditUserDialog(BuildContext context, UsersRolesViewModel viewModel, User user) {
    final userController = TextEditingController(text: user.username);
    final passController = TextEditingController();
    String? selectedRole = user.role;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("Edit User"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: userController, decoration: const InputDecoration(labelText: "Username")),
                TextField(controller: passController, decoration: const InputDecoration(labelText: "New Password (Optional)"), obscureText: true),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  key: ValueKey(selectedRole),
                  initialValue: viewModel.roles.contains(selectedRole) ? selectedRole : null,
                  decoration: const InputDecoration(labelText: "Role"),
                  items: viewModel.roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (val) => setState(() => selectedRole = val),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: () {
                  if (userController.text.isNotEmpty && selectedRole != null) {
                    final updatedUser = User(id: user.id, username: userController.text, email: user.email, role: selectedRole!, passwordHash: user.passwordHash);
                    viewModel.updateUser(updatedUser, passController.text.isEmpty ? null : passController.text);
                    Navigator.pop(ctx);
                  }
                },
                child: const Text("Update"),
              ),
            ],
          );
        }
      ),
    );
  }

  void _showDeleteUserDialog(BuildContext context, UsersRolesViewModel viewModel, User user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: Text("Delete user '${user.username}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              viewModel.deleteUser(user.id!);
              Navigator.pop(ctx);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddRoleDialog(BuildContext context, UsersRolesViewModel viewModel) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Add Role"),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: "Role Name")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                viewModel.createRole(controller.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }

  void _showDeleteRoleDialog(BuildContext context, UsersRolesViewModel viewModel, String role) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: Text("Delete role '$role' and its permissions?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              viewModel.deleteRole(role);
              Navigator.pop(ctx);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showRolePermissionsDialog(BuildContext context, UsersRolesViewModel viewModel, String role) async {
    await viewModel.fetchPermissionsForRole(role);
    List<String> currentPerms = List.from(viewModel.rolePermissions[role] ?? []);

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text("Permissions: $role"),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: availablePermissions.map((perm) {
                  return CheckboxListTile(
                    title: Text(perm),
                    value: currentPerms.contains(perm),
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          currentPerms.add(perm);
                        } else {
                          currentPerms.remove(perm);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: () {
                  viewModel.updatePermissions(role, currentPerms);
                  Navigator.pop(ctx);
                },
                child: const Text("Save"),
              ),
            ],
          );
        }
      ),
    );
  }
}