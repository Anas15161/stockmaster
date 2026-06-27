import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/product.dart';
import '../models/user.dart';
import 'database_helper.dart';

class ImportService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<Map<String, dynamic>> importData() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'csv'],
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        // Get extension from path if result.files.single.extension is null
        String path = result.files.single.path!;
        String extension = p.extension(path).toLowerCase().replaceAll('.', '');

        if (extension == 'json') {
          return await _importJson(file);
        } else if (extension == 'csv') {
          return await _importCsv(file);
        } else {
          return {'success': false, 'message': 'Format non supporté: $extension. Utilisez .json ou .csv'};
        }
      }
      return {'success': false, 'message': 'Aucun fichier sélectionné'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur lors de l\'import: $e'};
    }
  }

  Future<Map<String, dynamic>> _importJson(File file) async {
    try {
      String content = await file.readAsString();
      Map<String, dynamic> data = jsonDecode(content);

      int productsAdded = 0;
      int categoriesAdded = 0;

      // Import Categories
      if (data.containsKey('categories')) {
        List<dynamic> categories = data['categories'];
        for (var cat in categories) {
          if (cat is String) {
            try {
              await _dbHelper.createCategory(cat);
              categoriesAdded++;
            } catch (e) {
              // Ignore duplicates
            }
          }
        }
      }

      // Import Products
      if (data.containsKey('products')) {
        List<dynamic> products = data['products'];
        for (var prod in products) {
          await _processProduct(prod);
          productsAdded++;
        }
      }

      return {
        'success': true,
        'message': 'Import réussi: $categoriesAdded catégories, $productsAdded produits ajoutés.'
      };
    } catch (e) {
      return {'success': false, 'message': 'Erreur de lecture JSON: $e'};
    }
  }

  Future<Map<String, dynamic>> _importCsv(File file) async {
    try {
      // Try to read as UTF-8, fallback to Latin-1 (common for Excel CSVs)
      String content;
      try {
        content = await file.readAsString(encoding: utf8);
      } catch (_) {
        content = await file.readAsString(encoding: latin1);
      }

      // 1. Normalize Newlines: Convert \r\n and \r to \n
      content = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

      // 2. Simple delimiter detection
      String delimiter = ',';
      // Now safe to split by \n since we normalized it
      final firstLine = content.split('\n').first;
      if (firstLine.contains(';') && !firstLine.contains(',')) {
        delimiter = ';';
      }

      final List<List<dynamic>> fields = const CsvToListConverter().convert(
        content,
        fieldDelimiter: delimiter,
        eol: '\n', // Explicitly set EOL
        shouldParseNumbers: true,
      );

      if (fields.isEmpty) return {'success': false, 'message': 'Fichier CSV vide'};

      // 3. Header Aliases
      Map<String, String> columnMapping = {
        'name': 'name', 'nom': 'name', 'produit': 'name', 'product': 'name', 'nom du produit': 'name',
        'sku': 'sku', 'code': 'sku', 'ref': 'sku', 'référence': 'sku', 'reference': 'sku', 'barcode': 'sku', 'code-barres': 'sku',
        'category': 'category', 'catégorie': 'category', 'famille': 'category',
        'quantity': 'quantity', 'quantité': 'quantity', 'qte': 'quantity', 'qty': 'quantity', 'stock': 'quantity',
        'costprice': 'costPrice', 'cout': 'costPrice', 'coût': 'costPrice', 'prix d\'achat': 'costPrice', 'achat': 'costPrice',
        'sellingprice': 'sellingPrice', 'prix': 'sellingPrice', 'prix de vente': 'sellingPrice', 'vente': 'sellingPrice',
        'supplier': 'supplier', 'fournisseur': 'supplier',
        'imageurl': 'imageurl', 'image': 'imageurl', 'photo': 'imageurl', 'url': 'imageurl'
      };

      // Normalize headers using mapping
      List<String> headers = fields[0].map((e) {
        String h = e.toString().trim().toLowerCase();
        // Remove BOM
        if (h.runes.isNotEmpty && h.runes.first == 65279) h = h.substring(1);
        return columnMapping[h] ?? h; // Map to standard key or keep original
      }).toList();
      
      int productsAdded = 0;
      int categoriesAdded = 0;
      List<String> skippedReasons = [];

      for (int i = 1; i < fields.length; i++) {
        var row = fields[i];
        if (row.isEmpty) continue;
        if (row.length == 1 && (row[0] == null || row[0] == '')) continue;

        Map<String, dynamic> productMap = {};
        
        for (int j = 0; j < headers.length; j++) {
           if (j < row.length) {
             productMap[headers[j]] = row[j];
           }
        }

        if (!productMap.containsKey('name') && !productMap.containsKey('sku')) {
          skippedReasons.add("Row $i: Missing name or sku. Found: ${productMap.keys.toList()}");
          continue;
        }

        // Auto-create category if missing
        String category = productMap['category']?.toString() ?? 'General';
        try {
          await _dbHelper.createCategory(category);
          categoriesAdded++; 
        } catch (_) {}

        // Normalize map for _processProduct
        if (productMap.containsKey('imageurl') && productMap['imageurl'] != null) {
           productMap['images'] = [productMap['imageurl']];
        } else {
           productMap['images'] = [];
        }

        // Ensure types
        productMap['quantity'] = int.tryParse(productMap['quantity'].toString()) ?? 0;
        productMap['costprice'] = double.tryParse(productMap['costPrice']?.toString() ?? productMap['costprice']?.toString() ?? '0') ?? 0.0;
        productMap['sellingprice'] = double.tryParse(productMap['sellingPrice']?.toString() ?? productMap['sellingprice']?.toString() ?? '0') ?? 0.0;
        
        // Map keys to Model expectation
        Map<String, dynamic> modelMap = {
          'name': productMap['name'] ?? 'Unknown',
          'sku': productMap['sku']?.toString() ?? 'SKU-${DateTime.now().millisecondsSinceEpoch}-$i',
          'category': category,
          'quantity': productMap['quantity'],
          'costPrice': productMap['costprice'],
          'sellingPrice': productMap['sellingprice'],
          'supplier': productMap['supplier'],
          'images': productMap['images']
        };

        await _processProduct(modelMap);
        productsAdded++;
      }

      if (productsAdded == 0) {
        String details = skippedReasons.take(3).join("; ");
        return {
          'success': false, 
          'message': '0 items added. Headers detected: $headers. Details: $details'
        };
      }

      return {
        'success': true,
        'message': 'Import successful: $productsAdded products added.'
      };

    } catch (e) {
      return {'success': false, 'message': 'CSV Parse Error: $e'};
    }
  }

  Future<void> _processProduct(Map<String, dynamic> data) async {
    // Handle Images
    List<String> finalImages = [];
    if (data['images'] != null && data['images'] is List) {
      for (var img in data['images']) {
        String? localPath = await _saveImage(img);
        if (localPath != null) {
          finalImages.add(localPath);
        }
      }
    }

    Product product = Product(
      name: data['name'],
      sku: data['sku'],
      category: data['category'],
      quantity: data['quantity'],
      costPrice: (data['costPrice'] as num).toDouble(),
      sellingPrice: (data['sellingPrice'] as num).toDouble(),
      supplier: data['supplier'],
      images: finalImages,
    );

    // Check if exists
    final existing = await _dbHelper.getProductBySku(product.sku);
    if (existing != null) {
      // Update existing (merge images if you want, but here we replace for simplicity)
      // Actually, to keep IDs consistent, we copy the ID
      Product updated = Product(
        id: existing.id,
        name: product.name,
        sku: product.sku,
        category: product.category,
        quantity: product.quantity, // Option: existing.quantity + product.quantity? No, import usually sets state.
        costPrice: product.costPrice,
        sellingPrice: product.sellingPrice,
        supplier: product.supplier,
        images: product.images.isNotEmpty ? product.images : existing.images,
      );
      await _dbHelper.updateProduct(updated);
    } else {
      await _dbHelper.createProduct(product);
    }
  }

  Future<String?> _saveImage(String source) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      // Sanitize filename from url
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${source.hashCode}.jpg';
      final localFile = File(p.join(appDir.path, fileName));

      if (source.startsWith('http')) {
        // Try Download
        try {
          final response = await http.get(Uri.parse(source)).timeout(const Duration(seconds: 5));
          if (response.statusCode == 200) {
            await localFile.writeAsBytes(response.bodyBytes);
            return localFile.path;
          }
        } catch (e) {
          // If download fails, return original URL so it can be loaded via NetworkImage later
          return source; 
        }
        return source; // Fallback for non-200 status
      } else if (source.length > 20 && !source.contains('/') && !source.contains('\\')) {
         // Assume Base64
         try {
           final bytes = base64Decode(source);
           await localFile.writeAsBytes(bytes);
           return localFile.path;
         } catch (_) {
           // Not base64
         }
      } 
      // If it's a local path or unknown, just return it? 
      // No, for import, usually only HTTP or Base64 is useful.
      // But returning null drops it.
    } catch (e) {
      // Log error
    }
    return null;
  }
}
