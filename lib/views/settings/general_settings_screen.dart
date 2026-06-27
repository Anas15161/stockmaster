import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../viewmodels/theme_viewmodel.dart';
import '../../viewmodels/language_viewmodel.dart';
import '../../viewmodels/settings_viewmodel.dart';
import '../../utils/app_colors.dart';

class GeneralSettingsScreen extends StatelessWidget {
  const GeneralSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeViewModel = Provider.of<ThemeViewModel>(context);
    final languageViewModel = Provider.of<LanguageViewModel>(context);
    final settingsViewModel = Provider.of<SettingsViewModel>(context);
    final isDark = themeViewModel.themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(languageViewModel.translate('general_settings')),
        backgroundColor: AppColors.bleuStock,
        foregroundColor: Colors.white,
      ),
      backgroundColor: isDark ? Colors.black87 : const Color(0xFFF5F5F5),
      body: ListView(
        children: [
          _buildSectionHeader(context, "App Info", isDark),
          _buildListTile(
            context,
            title: languageViewModel.translate('app_name'),
            subtitle: "StockMaster",
            icon: Icons.title,
            isDark: isDark,
          ),
          _buildListTile(
            context,
            title: languageViewModel.translate('company_logo'),
            subtitle: "Tap to change",
            icon: Icons.image,
            isDark: isDark,
            trailing: settingsViewModel.companyLogoPath != null
                ? CircleAvatar(
                    backgroundImage: FileImage(File(settingsViewModel.companyLogoPath!)),
                    radius: 20,
                  )
                : null,
            onTap: () async {
              final ImagePicker picker = ImagePicker();
              final XFile? image = await picker.pickImage(source: ImageSource.gallery);
              if (image != null) {
                settingsViewModel.setCompanyLogo(image.path);
              }
            },
          ),
          
          _buildSectionHeader(context, "Localization", isDark),
          _buildListTile(
            context,
            title: languageViewModel.translate('language'),
            subtitle: languageViewModel.locale.languageCode == 'en' ? "English" : "Français",
            icon: Icons.language,
            isDark: isDark,
            trailing: DropdownButton<String>(
              value: languageViewModel.locale.languageCode,
              dropdownColor: isDark ? Colors.grey[800] : Colors.white,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              underline: Container(),
              items: const [
                DropdownMenuItem(value: 'en', child: Text("English")),
                DropdownMenuItem(value: 'fr', child: Text("Français")),
              ],
              onChanged: (val) {
                if (val != null) languageViewModel.changeLocale(Locale(val));
              },
            ),
          ),
          _buildListTile(
            context,
            title: languageViewModel.translate('timezone'),
            subtitle: "GMT+01:00 (Casablanca)",
            icon: Icons.access_time,
            isDark: isDark,
          ),
          _buildListTile(
            context,
            title: languageViewModel.translate('currency'),
            subtitle: settingsViewModel.currency,
            icon: Icons.attach_money,
            isDark: isDark,
            trailing: DropdownButton<String>(
              value: settingsViewModel.currency,
              dropdownColor: isDark ? Colors.grey[800] : Colors.white,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              underline: Container(),
              items: const [
                DropdownMenuItem(value: 'MAD', child: Text("MAD (DH)")),
                DropdownMenuItem(value: 'USD', child: Text("USD (\$)")),
                DropdownMenuItem(value: 'EUR', child: Text("EUR (€)")),
              ],
              onChanged: (val) {
                if (val != null) settingsViewModel.setCurrency(val);
              },
            ),
          ),

          _buildSectionHeader(context, "Appearance", isDark),
          _buildListTile(
            context,
            title: languageViewModel.translate('dark_mode'),
            subtitle: isDark ? languageViewModel.translate('on') : languageViewModel.translate('off'),
            icon: isDark ? Icons.light_mode : Icons.dark_mode,
            isDark: isDark,
            trailing: Switch(
              value: isDark,
              thumbColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppColors.bleuStock;
                  }
                  return null;
              }),
              onChanged: (val) => themeViewModel.toggleTheme(val),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: isDark ? Colors.grey[400] : AppColors.grisMaster,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildListTile(BuildContext context, {
    required String title,
    String? subtitle,
    required IconData icon,
    required bool isDark,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      color: isDark ? Colors.grey[900] : Colors.white,
      child: ListTile(
        leading: Icon(icon, color: AppColors.bleuStock),
        title: Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w500)),
        subtitle: subtitle != null ? Text(subtitle, style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600])) : null,
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}
