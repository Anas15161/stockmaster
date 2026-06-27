import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/theme_viewmodel.dart';
import '../../utils/app_colors.dart';

class SettingsSubPage extends StatelessWidget {
  final String title;
  final List<SettingsItem> items;

  const SettingsSubPage({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final themeViewModel = Provider.of<ThemeViewModel>(context);
    final isDark = themeViewModel.themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.bleuStock,
        foregroundColor: Colors.white,
      ),
      backgroundColor: isDark ? Colors.black87 : const Color(0xFFF5F5F5),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          if (item.isHeader) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(
                item.title.toUpperCase(),
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : AppColors.grisMaster,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            );
          }
          return Container(
            color: isDark ? Colors.grey[900] : Colors.white,
            child: ListTile(
              leading: Icon(item.icon, color: AppColors.bleuStock),
              title: Text(
                item.title,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w500),
              ),
              subtitle: item.subtitle != null ? Text(item.subtitle!, style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600])) : null,
              trailing: item.trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: item.onTap ?? () {
                // Placeholder action
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("${item.title} configuration")),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class SettingsItem {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool isHeader;
  final Widget? trailing;
  final VoidCallback? onTap;

  SettingsItem({required this.title, this.subtitle, this.icon, this.isHeader = false, this.trailing, this.onTap});
  
  factory SettingsItem.header(String title) => SettingsItem(title: title, isHeader: true);
}
