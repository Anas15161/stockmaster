import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/theme_viewmodel.dart';
import '../viewmodels/language_viewmodel.dart';
import '../utils/app_colors.dart';
import 'login_screen.dart';
import 'settings/general_settings_screen.dart';
import 'settings/users_roles_screen.dart';
import 'settings/settings_sub_page.dart';
import 'settings/categories_settings_screen.dart';
import 'settings/suppliers_settings_screen.dart';
import 'settings/reports_settings_screen.dart';
import '../services/import_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final themeViewModel = Provider.of<ThemeViewModel>(context);
    final languageViewModel = Provider.of<LanguageViewModel>(context);
    final isDark = themeViewModel.themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black87 : const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // User Profile Section
            Container(
              padding: const EdgeInsets.all(24),
              color: isDark ? Colors.grey[900] : Colors.white,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.bleuStock.withValues(alpha: 0.2),
                    child: Text(
                      authViewModel.currentUser?.username.substring(0, 1).toUpperCase() ?? "U",
                      style: const TextStyle(fontSize: 28, color: AppColors.bleuStock, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authViewModel.currentUser?.username ?? "User",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        authViewModel.currentUser?.role.toUpperCase() ?? "ROLE",
                        style: const TextStyle(
                          color: AppColors.grisMaster,
                          fontSize: 14,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Main Menu
            if (authViewModel.hasPermission('manage_settings'))
              _buildMenuTile(
                context,
                title: languageViewModel.translate('general_settings'),
                icon: Icons.settings,
                isDark: isDark,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GeneralSettingsScreen())),
              ),
            
            if (authViewModel.hasPermission('manage_users'))
              _buildMenuTile(
                context,
                title: languageViewModel.translate('users_roles'),
                icon: Icons.people,
                isDark: isDark,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UsersRolesScreen())),
              ),
            
            if (authViewModel.hasPermission('manage_products'))
              _buildMenuTile(
                context,
                title: languageViewModel.translate('product_settings'),
                icon: Icons.inventory,
                isDark: isDark,
                onTap: () => Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (_) => SettingsSubPage(
                    title: languageViewModel.translate('product_settings'),
                    items: [
                      SettingsItem(
                        title: languageViewModel.translate('categories'), 
                        icon: Icons.category,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoriesSettingsScreen())),
                      ),
                      SettingsItem(
                        title: languageViewModel.translate('import_data'),
                        icon: Icons.file_upload,
                        onTap: () async {
                          final importService = ImportService();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Select a JSON or CSV file to import...")),
                          );
                          final result = await importService.importData();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(result['message']),
                                backgroundColor: result['success'] ? Colors.green : Colors.red,
                                duration: const Duration(seconds: 4),
                              ),
                            );
                          }
                        },
                      ),
                      /** SettingsItem(title: "Reference / SKU Config", icon: Icons.qr_code),**/
                      SettingsItem(title: languageViewModel.translate('tax_rate(Coming soon)'), icon: Icons.attach_money),
                    ],
                  )),
                ),
              ),

            if (authViewModel.hasPermission('manage_stock')) ...[
              _buildMenuTile(
                context,
                title: languageViewModel.translate('stock_settings'),
                icon: Icons.warehouse,
                isDark: isDark,
                onTap: () => Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (_) => SettingsSubPage(
                    title: languageViewModel.translate('stock_settings'),
                    items: [
                      SettingsItem(title: languageViewModel.translate('min_stock'), icon: Icons.trending_down),
                      SettingsItem(title: languageViewModel.translate('max_stock'), icon: Icons.trending_up),
                      SettingsItem(title: languageViewModel.translate('locations'), icon: Icons.location_on),
                    ],
                  )),
                ),
              ),
              _buildMenuTile(
                context,
                title: languageViewModel.translate('suppliers'),
                icon: Icons.local_shipping,
                isDark: isDark,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SuppliersSettingsScreen())),
              ),
            ],

            _buildMenuTile(
              context,
              title: languageViewModel.translate('customers (Coming soon)'),
              icon: Icons.person_pin,
              isDark: isDark,
              onTap: () => Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => SettingsSubPage(
                  title: languageViewModel.translate('customers (Coming soon)'),
                  items: [
                    SettingsItem(title: "Customer Info", icon: Icons.info),
                    SettingsItem(title: "Order History", icon: Icons.history),
                    SettingsItem(title: "Discounts / Promos", icon: Icons.local_offer),
                  ],
                )),
              ),
            ),
            
            if (authViewModel.hasPermission('manage_stock'))
              _buildMenuTile(
                context,
                title: languageViewModel.translate('Alerts & Notifications (Coming soon)'),
                icon: Icons.notifications_active,
                isDark: isDark,
                onTap: () => Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (_) => SettingsSubPage(
                    title: languageViewModel.translate('Alerts & Notifications (Coming soon)'),
                    items: [
                      SettingsItem(title: languageViewModel.translate('low_stock_alert'), icon: Icons.warning_amber, trailing: Switch(value: true, onChanged: (v){})),
                      SettingsItem(title: languageViewModel.translate('out_of_stock_alert'), icon: Icons.error_outline, trailing: Switch(value: true, onChanged: (v){})),
                      SettingsItem(title: languageViewModel.translate('email_notifications'), icon: Icons.email, trailing: Switch(value: false, onChanged: (v){})),
                    ],
                  )),
                ),
              ),

            if (authViewModel.hasPermission('view_reports'))
              _buildMenuTile(
                context,
                title: languageViewModel.translate('reports_stats'),
                icon: Icons.bar_chart,
                isDark: isDark,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsSettingsScreen())),
              ),
              
            if (authViewModel.hasPermission('manage_settings'))
              _buildMenuTile(
                context,
                title: languageViewModel.translate('security_backup (Coming soon)'),
                icon: Icons.security,
                isDark: isDark,
                onTap: () => Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (_) => SettingsSubPage(
                    title: languageViewModel.translate('security_backup (Coming soon)'),
                    items: [
                      SettingsItem(title: languageViewModel.translate('auto_backup'), icon: Icons.backup, trailing: Switch(value: true, onChanged: (v){})),
                      SettingsItem(title: languageViewModel.translate('restore_data'), icon: Icons.restore),
                      SettingsItem(title: "Access Protection", icon: Icons.lock),
                    ],
                  )),
                ),
              ),

            const SizedBox(height: 20),
            _buildSectionHeader(languageViewModel.translate("account"), isDark),
            _buildMenuTile(
              context,
              title: languageViewModel.translate("logout"),
              icon: Icons.logout,
              isDark: isDark,
              onTap: () {
                _showLogoutDialog(context, authViewModel, languageViewModel);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            color: isDark ? Colors.grey[400] : AppColors.grisMaster,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Container(
      color: isDark ? Colors.grey[900] : Colors.white,
      margin: const EdgeInsets.only(bottom: 1), // Separator line effect
      child: ListTile(
        leading: Icon(icon, color: AppColors.bleuStock),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthViewModel authViewModel, LanguageViewModel languageViewModel) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(languageViewModel.translate("logout")),
        content: Text(languageViewModel.translate("confirm_logout")),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(languageViewModel.translate("cancel")),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              authViewModel.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: Text(languageViewModel.translate("logout"), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}