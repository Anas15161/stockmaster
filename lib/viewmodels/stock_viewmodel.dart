import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/database_helper.dart';

class StockViewModel extends ChangeNotifier {
  List<Product> _products = [];
  bool _isLoading = false;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;

  // Calculs pour le Dashboard [cite: 136]
  double get totalStockValue {
    return _products.fold(0, (sum, item) => sum + (item.quantity * item.sellingPrice));
  }

  int get lowStockCount {
    // Seuil d'alerte arbitraire fixé à 5 unités
    return _products.where((item) => item.quantity < 5).length;
  }

  Future<void> fetchProducts() async {
    _isLoading = true;
    notifyListeners();
    _products = await DatabaseHelper.instance.readAllProducts();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addProduct(Product product) async {
    await DatabaseHelper.instance.createProduct(product);
    await fetchProducts(); // Rafraîchir la liste après ajout
  }

  Future<void> updateProduct(Product product) async {
    await DatabaseHelper.instance.updateProduct(product);
    await fetchProducts();
  }

  Future<void> deleteProduct(int id) async {
    await DatabaseHelper.instance.deleteProduct(id);
    await fetchProducts();
  }

  Product? findProductBySku(String sku) {
    try {
      return _products.firstWhere((p) => p.sku == sku);
    } catch (e) {
      return null;
    }
  }
}