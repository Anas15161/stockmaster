import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barcode_widget/barcode_widget.dart';
import '../models/product.dart';
import '../utils/app_colors.dart';
import '../viewmodels/stock_viewmodel.dart';
import '../viewmodels/language_viewmodel.dart';
import '../viewmodels/settings_viewmodel.dart';
import 'add_product_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Re-fetch product from provider to get updates if it was edited
    final viewModel = Provider.of<StockViewModel>(context);
    final languageViewModel = Provider.of<LanguageViewModel>(context);
    final settingsViewModel = Provider.of<SettingsViewModel>(context);
    final product = viewModel.products.firstWhere(
      (p) => p.id == widget.product.id,
      orElse: () => widget.product,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        backgroundColor: AppColors.bleuStock,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: languageViewModel.translate('edit_product'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddProductScreen(product: product),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Gallery
            SizedBox(
              height: 300,
              child: product.images.isEmpty
                  ? Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.image_not_supported, size: 100, color: Colors.grey),
                      ),
                    )
                  : Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        PageView.builder(
                          itemCount: product.images.length,
                          onPageChanged: (index) {
                            setState(() {
                              _currentImageIndex = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            final imagePath = product.images[index];
                            if (imagePath.startsWith('http')) {
                              return Image.network(
                                imagePath,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => const Center(
                                  child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                ),
                              );
                            }
                            return Image.file(
                              File(imagePath),
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => const Center(
                                child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                              ),
                            );
                          },
                        ),
                        if (product.images.length > 1)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                product.images.length,
                                (index) => Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _currentImageIndex == index
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.category,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 20),

                  // Barcode Display
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4),
                        ],
                      ),
                      child: Column(
                        children: [
                          BarcodeWidget(
                            barcode: Barcode.code128(), // Code 128 is standard for products
                            data: product.sku,
                            width: 200,
                            height: 80,
                            drawText: true,
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(languageViewModel.translate('scan_code_hint'), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  
                  _buildDetailRow("SKU", product.sku),
                  _buildDetailRow(languageViewModel.translate('price'), settingsViewModel.formatPrice(product.sellingPrice)),
                  _buildDetailRow(languageViewModel.translate('cost'), settingsViewModel.formatPrice(product.costPrice)),
                  _buildDetailRow(languageViewModel.translate('quantity'), product.quantity.toString()),
                  if (product.supplier != null && product.supplier!.isNotEmpty)
                    _buildDetailRow(languageViewModel.translate('supplier'), product.supplier!),

                  const SizedBox(height: 30),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add_box),
                      label: Text(languageViewModel.translate('add_stock')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.vertCroissance,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        _showAddStockDialog(context, product, viewModel, languageViewModel);
                      },
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showAddStockDialog(BuildContext context, Product product, StockViewModel viewModel, LanguageViewModel languageViewModel) {
    final qtyController = TextEditingController(text: "10");
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("${languageViewModel.translate('add_stock')}: ${product.name}"),
        content: TextField(
          controller: qtyController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: languageViewModel.translate('quantity_to_add'),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(languageViewModel.translate('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.vertCroissance),
            onPressed: () {
              final int? addQty = int.tryParse(qtyController.text);
              if (addQty != null && addQty > 0) {
                final updatedProduct = Product(
                  id: product.id,
                  name: product.name,
                  sku: product.sku,
                  category: product.category,
                  quantity: product.quantity + addQty,
                  costPrice: product.costPrice,
                  sellingPrice: product.sellingPrice,
                  supplier: product.supplier,
                  images: product.images,
                );
                viewModel.updateProduct(updatedProduct);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("${languageViewModel.translate('added_to')} $addQty ${languageViewModel.translate('to')} ${product.name}")),
                );
              }
            },
            child: Text(languageViewModel.translate('add'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}