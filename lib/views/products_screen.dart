import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/stock_viewmodel.dart';
import '../viewmodels/theme_viewmodel.dart';
import '../models/product.dart';
import '../utils/app_colors.dart';
import 'add_product_screen.dart';
import 'product_detail_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<StockViewModel>(context);
    final themeViewModel = Provider.of<ThemeViewModel>(context);
    final isDark = themeViewModel.themeMode == ThemeMode.dark;

    // Filtrage local
    final filteredProducts = viewModel.products.where((product) {
      final query = _searchQuery.toLowerCase();
      return product.name.toLowerCase().contains(query) ||
             product.sku.toLowerCase().contains(query) ||
             product.category.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? Colors.black87 : const Color(0xFFF5F5F5), // White/Light Grey background
      appBar: AppBar(
        title: const Text(
          'Products',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.bleuStock,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar & Filter Section
          Container(
            color: AppColors.bleuStock, // Extend header color slightly
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20, top: 0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _searchQuery = value),
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        hintText: "Search products...",
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.grey),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = "");
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Filter Icon Button
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.filter_list, color: AppColors.bleuStock),
                    onPressed: () {
                      // TODO: Implement advanced filter
                    },
                  ),
                ),
              ],
            ),
          ),

          // Product List
          Expanded(
            child: viewModel.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredProducts.isEmpty
                    ? _buildEmptyState(isDark)
                    : RefreshIndicator(
                        onRefresh: () => viewModel.fetchProducts(),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredProducts.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            return _buildProductCard(
                              context, 
                              filteredProducts[index], 
                              isDark,
                              viewModel
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      // FAB
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.vertCroissance, // Green
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

  Widget _buildProductCard(BuildContext context, Product product, bool isDark, StockViewModel viewModel) {
    // Stock Logic
    Color statusColor;
    String statusText;
    
    if (product.quantity == 0) {
      statusColor = AppColors.rougeErreur;
      statusText = "Out of Stock";
    } else if (product.quantity < 20) {
      statusColor = AppColors.orangeAlerte;
      statusText = "Low Stock";
    } else {
      statusColor = AppColors.vertCroissance;
      statusText = "In Stock";
    }

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDark ? Colors.grey[900] : Colors.white,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(product: product),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center, // Center vertically
            children: [
              // Thumbnail
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  image: product.images.isNotEmpty
                      ? DecorationImage(
                          image: FileImage(File(product.images.first)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: product.images.isEmpty
                    ? Icon(
                        Icons.image_not_supported_outlined,
                        color: isDark ? Colors.grey[600] : Colors.grey[400],
                        size: 32,
                      )
                    : null,
              ),
              const SizedBox(width: 16),

              // Info Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.category,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Qty: ${product.quantity}",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey[300] : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 12,
                            color: statusColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // "+ Add Stock" Button
              Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      _showAddStockDialog(context, product, viewModel);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.vertCroissance.withOpacity(0.1),
                      foregroundColor: AppColors.vertCroissance,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      "+ Add Stock",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  // Edit Icon below (Optional, for full access)
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20, color: Colors.grey),
                    onPressed: () {
                       Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddProductScreen(product: product),
                        ),
                      );
                    },
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: isDark ? Colors.grey[700] : Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            "No products found",
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.grey[400] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  // Quick Add Stock Dialog
  void _showAddStockDialog(BuildContext context, Product product, StockViewModel viewModel) {
    final qtyController = TextEditingController(text: "10");
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Add Stock: ${product.name}"),
        content: TextField(
          controller: qtyController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "Quantity to Add",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.vertCroissance),
            onPressed: () {
              final int? addQty = int.tryParse(qtyController.text);
              if (addQty != null && addQty > 0) {
                // Update Logic
                final updatedProduct = Product(
                  id: product.id,
                  name: product.name,
                  sku: product.sku,
                  category: product.category,
                  quantity: product.quantity + addQty,
                  costPrice: product.costPrice,
                  sellingPrice: product.sellingPrice,
                  supplier: product.supplier,
                );
                viewModel.updateProduct(updatedProduct);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Added $addQty to ${product.name}")),
                );
              }
            },
            child: const Text("Add", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}