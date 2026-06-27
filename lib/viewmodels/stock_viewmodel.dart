import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/stock_movement.dart';
import '../services/database_helper.dart';

class StockViewModel extends ChangeNotifier {
  List<Product> _products = [];
  List<StockMovement> _movements = [];
  List<Map<String, dynamic>> _topSales = [];
  List<String> _categories = [];
  bool _isLoading = false;

  List<Product> get products => _products;
  List<StockMovement> get movements => _movements;
  List<Map<String, dynamic>> get topSales => _topSales;
  List<String> get categories => _categories;
  bool get isLoading => _isLoading;

  List<String> get suppliers {
    final Set<String> uniqueSuppliers = {};
    for (var product in _products) {
      if (product.supplier != null && product.supplier!.isNotEmpty) {
        uniqueSuppliers.add(product.supplier!);
      }
    }
    return uniqueSuppliers.toList()..sort();
  }

  // Calculs pour le Dashboard [cite: 136]
  double get totalStockValue {
    return _products.fold(0, (sum, item) => sum + (item.quantity * item.sellingPrice));
  }

  int get lowStockCount {
    // Seuil d'alerte arbitraire fixé à 5 unités
    return _products.where((item) => item.quantity < 5).length;
  }

  int get totalProducts => _products.length;

  Map<String, double> get categoryDistribution {
    final Map<String, double> distribution = {};
    for (var product in _products) {
      if (distribution.containsKey(product.category)) {
        distribution[product.category] = distribution[product.category]! + 1;
      } else {
        distribution[product.category] = 1;
      }
    }
    return distribution;
  }

  List<StockMovement> getRecentMovements(int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return _movements.where((m) => m.date.isAfter(cutoff)).toList();
  }

  Future<void> fetchProducts() async {
    _isLoading = true;
    notifyListeners();
    _products = await DatabaseHelper.instance.readAllProducts();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchMovements() async {
    _movements = await DatabaseHelper.instance.readAllMovements();
    notifyListeners();
  }

  Future<void> fetchTopSales() async {
    _topSales = await DatabaseHelper.instance.getTopSellingProducts();
    notifyListeners();
  }

  Future<void> fetchCategories() async {
    _categories = await DatabaseHelper.instance.readAllCategories();
    notifyListeners();
  }

  Future<void> addCategory(String name) async {
    await DatabaseHelper.instance.createCategory(name);
    await fetchCategories();
  }

  Future<void> deleteCategoryByName(String name) async {
    await DatabaseHelper.instance.deleteCategory(name);
    await fetchCategories();
  }

  Future<void> refreshAll() async {
    _isLoading = true;
    notifyListeners();
    await Future.wait([
      fetchProducts(),
      fetchMovements(),
      fetchTopSales(),
      fetchCategories(),
    ]);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addProduct(Product product) async {
    final id = await DatabaseHelper.instance.createProduct(product);
    
    // Log initial stock if > 0
    if (product.quantity > 0) {
      final movement = StockMovement(
        productId: id,
        productName: product.name,
        type: MovementType.inward,
        quantity: product.quantity,
        date: DateTime.now(),
        reason: 'Initial Stock',
        userId: 'admin', // Default user
      );
      await DatabaseHelper.instance.logMovement(movement);
    }

    await refreshAll();
  }

  Future<void> updateProduct(Product product) async {
    // Check for quantity change to log movement
    try {
      final oldProduct = _products.firstWhere((p) => p.id == product.id);
      
      if (oldProduct.quantity != product.quantity) {
        final diff = product.quantity - oldProduct.quantity;
        final type = diff > 0 ? MovementType.inward : MovementType.outward;
        
        final movement = StockMovement(
          productId: product.id!,
          productName: product.name,
          type: type,
          quantity: diff.abs(),
          date: DateTime.now(),
          reason: 'Manual Adjustment (Edit)',
          userId: 'admin', // Default user
        );
        await DatabaseHelper.instance.logMovement(movement);
      }
    } catch (e) {
      // Product might not be in the list yet or error finding it
      debugPrint("Error logging movement for update: $e");
    }

    await DatabaseHelper.instance.updateProduct(product);
    await refreshAll();
  }

  Future<void> deleteProduct(int id) async {
    await DatabaseHelper.instance.deleteProduct(id);
    await refreshAll();
  }

  Future<void> adjustStock({
    required Product product,
    required int quantityChange,
    required MovementType type,
    required String userId,
    String? reason,
  }) async {
    // 1. Log movement
    final movement = StockMovement(
      productId: product.id!,
      productName: product.name,
      type: type,
      quantity: quantityChange,
      date: DateTime.now(),
      reason: reason,
      userId: userId,
    );
    await DatabaseHelper.instance.logMovement(movement);

    // 2. Update Product Quantity
    int newQuantity = product.quantity;
    if (type == MovementType.inward) {
      newQuantity += quantityChange;
    } else {
      newQuantity -= quantityChange;
    }
    
    // Prevent negative stock
    if (newQuantity < 0) newQuantity = 0;

    final updatedProduct = Product(
      id: product.id,
      name: product.name,
      sku: product.sku,
      category: product.category,
      quantity: newQuantity,
      costPrice: product.costPrice,
      sellingPrice: product.sellingPrice,
      supplier: product.supplier,
      images: product.images,
    );

    await DatabaseHelper.instance.updateProduct(updatedProduct);
    await refreshAll();
  }

  Product? findProductBySku(String sku) {
    try {
      return _products.firstWhere((p) => p.sku == sku);
    } catch (e) {
      return null;
    }
  }
}
