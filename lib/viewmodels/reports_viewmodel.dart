import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart';
import 'package:open_file/open_file.dart';
import '../models/product.dart';
import '../models/stock_movement.dart';
import '../services/database_helper.dart';

class ReportsViewModel extends ChangeNotifier {
  List<Product> _products = [];
  List<StockMovement> _movements = [];
  
  // Filters
  DateTimeRange? _dateRange;
  String? _selectedCategory;
  
  // Data for Reports
  List<Product> _filteredStockStatus = [];
  List<Map<String, dynamic>> _topSales = [];
  List<StockMovement> _losses = [];

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  DateTimeRange? get dateRange => _dateRange;
  String? get selectedCategory => _selectedCategory;
  List<Product> get stockStatus => _filteredStockStatus;
  List<Map<String, dynamic>> get topSales => _topSales;
  List<StockMovement> get losses => _losses;

  ReportsViewModel() {
    refreshData();
  }

  void setDateRange(DateTimeRange? range) {
    _dateRange = range;
    _applyFilters();
  }

  void setCategory(String? category) {
    _selectedCategory = category;
    _applyFilters();
  }

  Future<void> refreshData() async {
    _isLoading = true;
    notifyListeners();

    _products = await DatabaseHelper.instance.readAllProducts();
    _movements = await DatabaseHelper.instance.readAllMovements();
    
    _applyFilters();
    
    _isLoading = false;
    notifyListeners();
  }

  void _applyFilters() {
    // 1. Stock Status (Product Snapshot)
    // Stock is current state, so date filter doesn't apply to quantity directly unless we calculate historical stock.
    // We will just filter by category.
    if (_selectedCategory != null && _selectedCategory != 'All') {
      _filteredStockStatus = _products.where((p) => p.category == _selectedCategory).toList();
    } else {
      _filteredStockStatus = List.from(_products);
    }

    // 2. Filter Movements for Top Sales & Losses
    List<StockMovement> filteredMovements = _movements;
    if (_dateRange != null) {
      filteredMovements = filteredMovements.where((m) => 
        m.date.isAfter(_dateRange!.start) && m.date.isBefore(_dateRange!.end.add(const Duration(days: 1)))
      ).toList();
    }
    
    // 3. Top Sales (Out movements)
    // Group by productId
    Map<int, int> salesMap = {};
    for (var m in filteredMovements) {
      if (m.type == MovementType.outward) {
        // Exclude "Loss" reasons if possible? Assuming OUT without "Loss" reason is sale.
        bool isLoss = m.reason != null && (m.reason!.toLowerCase().contains('loss') || m.reason!.toLowerCase().contains('damage'));
        if (!isLoss) {
          salesMap[m.productId] = (salesMap[m.productId] ?? 0) + m.quantity;
        }
      }
    }
    
    _topSales = [];
    salesMap.forEach((pid, qty) {
      final product = _products.firstWhere((p) => p.id == pid, orElse: () => Product(name: 'Unknown', sku: '', category: '', quantity: 0, costPrice: 0, sellingPrice: 0, supplier: '', images: []));
      _topSales.add({
        'name': product.name,
        'sku': product.sku,
        'quantity': qty,
        'value': qty * product.sellingPrice,
      });
    });
    _topSales.sort((a, b) => (b['quantity'] as int).compareTo(a['quantity'] as int));

    // 4. Losses
    _losses = filteredMovements.where((m) {
      bool isOut = m.type == MovementType.outward;
      bool isLossReason = m.reason != null && (
        m.reason!.toLowerCase().contains('loss') || 
        m.reason!.toLowerCase().contains('damage') ||
        m.reason!.toLowerCase().contains('perte') || // FR
        m.reason!.toLowerCase().contains('cassé') // FR
      );
      return isOut && isLossReason;
    }).toList();

    notifyListeners();
  }

  // --- Export Logic ---

  Future<void> exportPdf(String reportType) async {
    final pdf = pw.Document();
    final title = reportType.toUpperCase();
    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(level: 0, child: pw.Text("StockMaster Report - $title", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold))),
            pw.Paragraph(text: "Generated on: $dateStr"),
            if (_dateRange != null) pw.Paragraph(text: "Period: ${DateFormat('yyyy-MM-dd').format(_dateRange!.start)} - ${DateFormat('yyyy-MM-dd').format(_dateRange!.end)}"),
            pw.SizedBox(height: 20),
            _buildPdfTable(reportType),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'StockMaster_${reportType}_$dateStr',
    );
  }

  pw.Widget _buildPdfTable(String reportType) {
    if (reportType == 'Stock Status') {
      return pw.TableHelper.fromTextArray(
        headers: ['Product', 'SKU', 'Category', 'Qty', 'Value'],
        data: _filteredStockStatus.map((p) => [p.name, p.sku, p.category, p.quantity.toString(), (p.quantity * p.sellingPrice).toStringAsFixed(2)]).toList(),
      );
    } else if (reportType == 'Top Sales') {
      return pw.TableHelper.fromTextArray(
        headers: ['Product', 'SKU', 'Qty Sold', 'Revenue'],
        data: _topSales.map((s) => [s['name'], s['sku'], s['quantity'].toString(), (s['value'] as double).toStringAsFixed(2)]).toList(),
      );
    } else if (reportType == 'Losses') {
      return pw.TableHelper.fromTextArray(
        headers: ['Date', 'Product', 'Qty', 'Reason', 'User'],
        data: _losses.map((m) => [DateFormat('yyyy-MM-dd').format(m.date), m.productName, m.quantity.toString(), m.reason ?? '', m.userId]).toList(),
      );
    }
    return pw.Text("No Data");
  }

  Future<void> exportExcel(String reportType) async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Sheet1'];
    
    // Headers
    List<String> headers = [];
    if (reportType == 'Stock Status') {
      headers = ['Product', 'SKU', 'Category', 'Qty', 'Value'];
    } else if (reportType == 'Top Sales') {
      headers = ['Product', 'SKU', 'Qty Sold', 'Revenue'];
    } else if (reportType == 'Losses') {
      headers = ['Date', 'Product', 'Qty', 'Reason', 'User'];
    }
    
    sheetObject.appendRow(headers.map((h) => TextCellValue(h)).toList());

    // Data
    if (reportType == 'Stock Status') {
      for (var p in _filteredStockStatus) {
        sheetObject.appendRow([
          TextCellValue(p.name),
          TextCellValue(p.sku),
          TextCellValue(p.category),
          IntCellValue(p.quantity),
          DoubleCellValue(p.quantity * p.sellingPrice)
        ]);
      }
    } else if (reportType == 'Top Sales') {
      for (var s in _topSales) {
        sheetObject.appendRow([
          TextCellValue(s['name']),
          TextCellValue(s['sku']),
          IntCellValue(s['quantity']),
          DoubleCellValue(s['value'])
        ]);
      }
    } else if (reportType == 'Losses') {
      for (var m in _losses) {
        sheetObject.appendRow([
          TextCellValue(DateFormat('yyyy-MM-dd').format(m.date)),
          TextCellValue(m.productName),
          IntCellValue(m.quantity),
          TextCellValue(m.reason ?? ''),
          TextCellValue(m.userId)
        ]);
      }
    }

    final fileBytes = excel.save();
    if (fileBytes != null) {
      final directory = await getApplicationDocumentsDirectory();
      final path = "${directory.path}/StockMaster_${reportType.replaceAll(' ', '_')}.xlsx";
      File(path)
        ..createSync(recursive: true)
        ..writeAsBytesSync(fileBytes);
      
      await OpenFile.open(path);
    }
  }
}