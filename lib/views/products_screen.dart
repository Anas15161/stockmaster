import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/stock_viewmodel.dart';
import '../viewmodels/theme_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/language_viewmodel.dart';
import '../models/product.dart';
import '../models/stock_movement.dart';
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
  bool _isGridView = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<StockViewModel>(context);
    final themeViewModel = Provider.of<ThemeViewModel>(context);
    final languageViewModel = Provider.of<LanguageViewModel>(context);
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
      body: Column(
        children: [
          // Search Bar & Filter Section
          Container(
            color: AppColors.bleuStock,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                          color: Colors.black.withValues(alpha: 0.1),
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
                        hintText: languageViewModel.translate('search_products'),
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
                const SizedBox(width: 10),
                // View Toggle Button
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(
                      _isGridView ? Icons.view_list : Icons.grid_view,
                      color: AppColors.bleuStock,
                    ),
                    onPressed: () {
                      setState(() {
                        _isGridView = !_isGridView;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                // Filter Button (Placeholder for now)
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
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

          // Product Count
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: isDark ? Colors.grey[900] : Colors.grey[200],
            child: Text(
              "${filteredProducts.length} ${languageViewModel.translate('products_found')}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.grey[400] : Colors.grey[700],
              ),
            ),
          ),

          // Product List/Grid
          Expanded(
            child: viewModel.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredProducts.isEmpty
                    ? _buildEmptyState(isDark, languageViewModel)
                    : RefreshIndicator(
                        onRefresh: () => viewModel.refreshAll(),
                        child: _isGridView
                            ? GridView.builder(
                                padding: const EdgeInsets.all(16),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.65, // Adjust for card height
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                                itemCount: filteredProducts.length,
                                itemBuilder: (context, index) {
                                  return _buildProductGridItem(
                                    context,
                                    filteredProducts[index],
                                    isDark,
                                    viewModel,
                                    languageViewModel,
                                  );
                                },
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: filteredProducts.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  return _buildProductCard(
                                    context,
                                    filteredProducts[index],
                                    isDark,
                                    viewModel,
                                    languageViewModel,
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

  Widget _buildProductCard(BuildContext context, Product product, bool isDark, StockViewModel viewModel, LanguageViewModel languageViewModel) {
    // Stock Logic
    Color statusColor;
    String statusText;
    
    if (product.quantity == 0) {
      statusColor = AppColors.rougeErreur;
      statusText = languageViewModel.translate('out_of_stock');
    } else if (product.quantity < 20) {
      statusColor = AppColors.orangeAlerte;
      statusText = languageViewModel.translate('low_stock');
    } else {
      statusColor = AppColors.vertCroissance;
      statusText = languageViewModel.translate('in_stock');
    }

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
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
                  image: (product.images.isNotEmpty && product.images.first.startsWith('http'))
                      ? DecorationImage(
                          image: NetworkImage(product.images.first),
                          fit: BoxFit.cover,
                          onError: (exception, stackTrace) {}, // Prevent crash
                        )
                      : (product.images.isNotEmpty && File(product.images.first).existsSync())
                          ? DecorationImage(
                              image: FileImage(File(product.images.first)),
                              fit: BoxFit.cover,
                            )
                          : null,
                ),
                child: (product.images.isEmpty || (!product.images.first.startsWith('http') && !File(product.images.first).existsSync()))
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
                      "${languageViewModel.translate('qty')}: ${product.quantity}",
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
                      _showStockAdjustmentDialog(context, product, viewModel, languageViewModel);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.vertCroissance.withValues(alpha: 0.1),
                      foregroundColor: AppColors.vertCroissance,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      languageViewModel.translate('adjust'),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  // Edit and Delete Icons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                        onPressed: () {
                          _showDeleteConfirmDialog(context, product, viewModel, languageViewModel);
                        },
                      ),
                    ],
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductGridItem(BuildContext context, Product product, bool isDark, StockViewModel viewModel, LanguageViewModel languageViewModel) {
    Color statusColor;
    String statusText;
    
    if (product.quantity == 0) {
      statusColor = AppColors.rougeErreur;
      statusText = languageViewModel.translate('out_of_stock');
    } else if (product.quantity < 20) {
      statusColor = AppColors.orangeAlerte;
      statusText = languageViewModel.translate('low_stock');
    } else {
      statusColor = AppColors.vertCroissance;
      statusText = languageViewModel.translate('in_stock');
    }

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDark ? Colors.grey[900] : Colors.white,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(product: product),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Section
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[100],
                  image: product.images.isNotEmpty
                      ? DecorationImage(
                          image: product.images.first.startsWith('http')
                              ? NetworkImage(product.images.first) as ImageProvider
                              : FileImage(File(product.images.first)),
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
            ),
            
            // Details Section
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          product.category,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "\$${product.sellingPrice}",
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.vertCroissance,
                              ),
                            ),
                            Text(
                              "${languageViewModel.translate('qty')}: ${product.quantity}",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.grey[300] : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 10,
                                color: statusColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 30,
                            child: ElevatedButton(
                              onPressed: () {
                                _showStockAdjustmentDialog(context, product, viewModel, languageViewModel);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.vertCroissance.withValues(alpha: 0.1),
                                foregroundColor: AppColors.vertCroissance,
                                elevation: 0,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                languageViewModel.translate('adjust'),
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddProductScreen(product: product),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Icon(Icons.edit, size: 18, color: Colors.grey[400]),
                          ),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () {
                            _showDeleteConfirmDialog(context, product, viewModel, languageViewModel);
                          },
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, LanguageViewModel languageViewModel) {
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
            languageViewModel.translate('no_products_found'),
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.grey[400] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  // Stock Adjustment Dialog
  void _showStockAdjustmentDialog(BuildContext context, Product product, StockViewModel viewModel, LanguageViewModel languageViewModel) {
    final qtyController = TextEditingController();
    bool isStockIn = true; // Default to IN

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text("${languageViewModel.translate('adjust_stock')}: ${product.name}"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ChoiceChip(
                      label: Text(languageViewModel.translate('stock_in')),
                      selected: isStockIn,
                      selectedColor: AppColors.vertCroissance.withValues(alpha: 0.3),
                      onSelected: (selected) {
                        setState(() => isStockIn = true);
                      },
                    ),
                    const SizedBox(width: 16),
                    ChoiceChip(
                      label: Text(languageViewModel.translate('stock_out')),
                      selected: !isStockIn,
                      selectedColor: AppColors.rougeErreur.withValues(alpha: 0.3),
                      onSelected: (selected) {
                        setState(() => isStockIn = false);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: qtyController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: languageViewModel.translate('quantity'),
                    border: const OutlineInputBorder(),
                    helperText: !isStockIn ? "${languageViewModel.translate('available')}: ${product.quantity}" : null,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(languageViewModel.translate('cancel')),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isStockIn ? AppColors.vertCroissance : AppColors.rougeErreur,
                ),
                onPressed: () async {
                  final int? qty = int.tryParse(qtyController.text);
                  if (qty != null && qty > 0) {
                    if (!isStockIn && qty > product.quantity) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(languageViewModel.translate('cannot_remove_more'))),
                      );
                      return;
                    }
                    
                    if (!context.mounted) return; // Verify context mounted before usage

                    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
                    final userId = authViewModel.currentUser?.username ?? "unknown";

                    await viewModel.adjustStock(
                      product: product, 
                      quantityChange: qty, 
                      type: isStockIn ? MovementType.inward : MovementType.outward,
                      userId: userId,
                      reason: "Manual adjustment"
                    );

                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(languageViewModel.translate('stock_updated'))),
                    );
                  }
                },
                child: Text(isStockIn ? languageViewModel.translate('add_stock') : languageViewModel.translate('remove_stock'), style: const TextStyle(color: Colors.white)),
              ),
            ],
          );
        }
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, Product product, StockViewModel viewModel, LanguageViewModel languageViewModel) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(languageViewModel.translate('delete_product')),
        content: Text(languageViewModel.translate('confirm_delete_msg').replaceAll('{product}', product.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(languageViewModel.translate('cancel')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx); // Close dialog
              await viewModel.deleteProduct(product.id!);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(languageViewModel.translate('deleted'))),
                );
              }
            },
            child: Text(languageViewModel.translate('delete'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
