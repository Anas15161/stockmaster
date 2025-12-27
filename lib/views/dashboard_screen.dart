import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../viewmodels/stock_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/theme_viewmodel.dart';
import '../utils/app_colors.dart';
import 'add_product_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<StockViewModel>(context);
    final authViewModel = Provider.of<AuthViewModel>(context);
    final themeViewModel = Provider.of<ThemeViewModel>(context);
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final isDark = themeViewModel.themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black87 : AppColors.grisClair,
      appBar: AppBar(
        title: const Text('StockMaster Dashboard'),
        backgroundColor: AppColors.bleuStock,
        foregroundColor: Colors.white,
        actions: [
          // Theme Toggle
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              themeViewModel.toggleTheme(!isDark);
            },
          ),
          // Logout
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              authViewModel.logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: CircleAvatar(
              backgroundColor: isDark ? Colors.grey : AppColors.grisMaster,
              child: Text(
                authViewModel.currentUser?.username.substring(0, 1).toUpperCase() ?? "U",
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats
            Row(
              children: [
                _buildStatCard(
                  "Total Stock Value",
                  currencyFormat.format(viewModel.totalStockValue),
                  AppColors.bleuStock,
                  Icons.monetization_on,
                  isDark
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  "Low Stock Items",
                  "${viewModel.lowStockCount}",
                  AppColors.orangeAlerte,
                  Icons.warning_amber_rounded,
                  isDark
                ),
              ],
            ),
            const SizedBox(height: 24),

            const Text(
              "Recent Products",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            // List
            Expanded(
              child: viewModel.products.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                itemCount: viewModel.products.length,
                itemBuilder: (context, index) {
                  final product = viewModel.products[index];
                  return Card(
                    color: isDark ? Colors.grey[900] : Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      leading: Container(
                        width: 50, height: 50,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.image, color: isDark ? Colors.grey : Colors.grey),
                      ),
                      title: Text(
                        product.name,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black
                        ),
                      ),
                      subtitle: Text(
                        "Qty: ${product.quantity}  •  ${product.category}",
                        style: TextStyle(
                          color: product.quantity < 5
                              ? AppColors.rougeErreur
                              : (isDark ? Colors.grey[400] : AppColors.grisMaster),
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            currencyFormat.format(product.sellingPrice),
                            style: const TextStyle(
                              color: AppColors.vertCroissance,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Edit Button
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AddProductScreen(product: product),
                                ),
                              );
                            },
                          ),
                          // Delete Button (Admin only)
                          if (authViewModel.isAdmin)
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                _showDeleteConfirmation(context, viewModel, product.id!);
                              },
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.vertCroissance,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddProductScreen()),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.grisFonce
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : AppColors.grisMaster
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 60, color: AppColors.grisMaster),
          SizedBox(height: 10),
          Text("No products yet", style: TextStyle(color: AppColors.grisMaster)),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, StockViewModel viewModel, int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this product?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              viewModel.deleteProduct(id);
              Navigator.of(ctx).pop();
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
