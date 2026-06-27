import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/reports_viewmodel.dart';
import '../../viewmodels/stock_viewmodel.dart';
import '../../viewmodels/theme_viewmodel.dart';
import '../../viewmodels/language_viewmodel.dart';
import '../../utils/app_colors.dart';

class ReportsSettingsScreen extends StatefulWidget {
  const ReportsSettingsScreen({super.key});

  @override
  State<ReportsSettingsScreen> createState() => _ReportsSettingsScreenState();
}

class _ReportsSettingsScreenState extends State<ReportsSettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ReportsViewModel>(context, listen: false).refreshData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeViewModel = Provider.of<ThemeViewModel>(context);
    final languageViewModel = Provider.of<LanguageViewModel>(context);
    final reportsViewModel = Provider.of<ReportsViewModel>(context);
    final stockViewModel = Provider.of<StockViewModel>(context);
    final isDark = themeViewModel.themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(languageViewModel.translate('reports_stats')),
        backgroundColor: AppColors.bleuStock,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: languageViewModel.translate('stock_status')),
            Tab(text: languageViewModel.translate('top_sales')),
            Tab(text: languageViewModel.translate('losses')),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => _export(context, reportsViewModel, 'pdf'),
          ),
          IconButton(
            icon: const Icon(Icons.table_view),
            onPressed: () => _export(context, reportsViewModel, 'excel'),
          ),
        ],
      ),
      backgroundColor: isDark ? Colors.black87 : const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Filters
          Container(
            padding: const EdgeInsets.all(8),
            color: isDark ? Colors.grey[900] : Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.date_range),
                    label: Text(reportsViewModel.dateRange == null 
                      ? "Select Date Range" 
                      : "${DateFormat('MM/dd').format(reportsViewModel.dateRange!.start)} - ${DateFormat('MM/dd').format(reportsViewModel.dateRange!.end)}"
                    ),
                    onPressed: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) reportsViewModel.setDateRange(picked);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    key: ValueKey(reportsViewModel.selectedCategory),
                    initialValue: reportsViewModel.selectedCategory,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                      border: OutlineInputBorder(),
                      labelText: "Category",
                    ),
                    items: ['All', ...stockViewModel.categories].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) => reportsViewModel.setCategory(val == 'All' ? null : val),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: reportsViewModel.isLoading 
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildStockStatusTab(reportsViewModel, isDark),
                    _buildTopSalesTab(reportsViewModel, isDark),
                    _buildLossesTab(reportsViewModel, isDark),
                  ],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockStatusTab(ReportsViewModel vm, bool isDark) {
    if (vm.stockStatus.isEmpty) return const Center(child: Text("No Data"));
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text("Product")),
            DataColumn(label: Text("Category")),
            DataColumn(label: Text("Qty"), numeric: true),
            DataColumn(label: Text("Value"), numeric: true),
          ],
          rows: vm.stockStatus.map((p) => DataRow(cells: [
            DataCell(Text(p.name)),
            DataCell(Text(p.category)),
            DataCell(Text(p.quantity.toString())),
            DataCell(Text((p.quantity * p.sellingPrice).toStringAsFixed(2))),
          ])).toList(),
        ),
      ),
    );
  }

  Widget _buildTopSalesTab(ReportsViewModel vm, bool isDark) {
    if (vm.topSales.isEmpty) return const Center(child: Text("No Sales Data"));
    return ListView.builder(
      itemCount: vm.topSales.length,
      itemBuilder: (context, index) {
        final item = vm.topSales[index];
        return ListTile(
          title: Text(item['name']),
          subtitle: Text("SKU: ${item['sku']}"),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("${item['quantity']} Sold", style: const TextStyle(fontWeight: FontWeight.bold)),
              Text("Rev: ${(item['value'] as double).toStringAsFixed(2)}", style: const TextStyle(fontSize: 12, color: Colors.green)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLossesTab(ReportsViewModel vm, bool isDark) {
    if (vm.losses.isEmpty) return const Center(child: Text("No Losses Recorded"));
    return ListView.builder(
      itemCount: vm.losses.length,
      itemBuilder: (context, index) {
        final item = vm.losses[index];
        return ListTile(
          title: Text(item.productName),
          subtitle: Text("${DateFormat('yyyy-MM-dd').format(item.date)} - ${item.reason ?? 'Unknown'}"),
          trailing: Text("-${item.quantity}", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        );
      },
    );
  }

  void _export(BuildContext context, ReportsViewModel vm, String type) {
    String reportName = ['Stock Status', 'Top Sales', 'Losses'][_tabController.index];
    if (type == 'pdf') {
      vm.exportPdf(reportName);
    } else {
      vm.exportExcel(reportName);
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Exporting $reportName to $type...")));
  }
}
