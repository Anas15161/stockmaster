import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/stock_viewmodel.dart';
import '../../viewmodels/theme_viewmodel.dart';
import '../../viewmodels/language_viewmodel.dart';
import '../../utils/app_colors.dart';

class SuppliersSettingsScreen extends StatelessWidget {
  const SuppliersSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<StockViewModel>(context);
    final themeViewModel = Provider.of<ThemeViewModel>(context);
    final languageViewModel = Provider.of<LanguageViewModel>(context);
    final isDark = themeViewModel.themeMode == ThemeMode.dark;

    final suppliers = viewModel.suppliers;

    return Scaffold(
      appBar: AppBar(
        title: Text(languageViewModel.translate('suppliers')),
        backgroundColor: AppColors.bleuStock,
        foregroundColor: Colors.white,
      ),
      backgroundColor: isDark ? Colors.black87 : const Color(0xFFF5F5F5),
      body: suppliers.isEmpty
          ? Center(
              child: Text(
                "No suppliers found", // Could add translation key
                style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
            )
          : ListView.separated(
              itemCount: suppliers.length,
              separatorBuilder: (ctx, i) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final supplier = suppliers[index];
                return Container(
                  color: isDark ? Colors.grey[900] : Colors.white,
                  child: ListTile(
                    leading: const Icon(Icons.business, color: AppColors.bleuStock),
                    title: Text(
                      supplier,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    ),
                    subtitle: Text(
                      "${viewModel.products.where((p) => p.supplier == supplier).length} Products",
                      style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 12),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
