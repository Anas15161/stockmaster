import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/stock_viewmodel.dart';
import '../../viewmodels/theme_viewmodel.dart';
import '../../viewmodels/language_viewmodel.dart';
import '../../utils/app_colors.dart';

class CategoriesSettingsScreen extends StatelessWidget {
  const CategoriesSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<StockViewModel>(context);
    final themeViewModel = Provider.of<ThemeViewModel>(context);
    final languageViewModel = Provider.of<LanguageViewModel>(context);
    final isDark = themeViewModel.themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(languageViewModel.translate('categories')),
        backgroundColor: AppColors.bleuStock,
        foregroundColor: Colors.white,
      ),
      backgroundColor: isDark ? Colors.black87 : const Color(0xFFF5F5F5),
      body: viewModel.categories.isEmpty
          ? const Center(child: Text("No categories"))
          : ListView.separated(
              itemCount: viewModel.categories.length,
              separatorBuilder: (ctx, i) => Divider(height: 1, color: Colors.grey[300]),
              itemBuilder: (context, index) {
                final category = viewModel.categories[index];
                return Container(
                  color: isDark ? Colors.grey[900] : Colors.white,
                  child: ListTile(
                    title: Text(
                      category,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        _showDeleteConfirmation(context, viewModel, category);
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.vertCroissance,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showAddCategoryDialog(context, viewModel, languageViewModel),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context, StockViewModel viewModel, LanguageViewModel languageViewModel) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Add Category"), // Need translation key if strict
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "Category Name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(languageViewModel.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                viewModel.addCategory(controller.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: Text(languageViewModel.translate('add')),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, StockViewModel viewModel, String category) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: Text("Delete category '$category'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              viewModel.deleteCategoryByName(category);
              Navigator.pop(ctx);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}