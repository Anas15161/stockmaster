import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../viewmodels/stock_viewmodel.dart';
import '../viewmodels/theme_viewmodel.dart';
import '../viewmodels/language_viewmodel.dart';
import '../viewmodels/settings_viewmodel.dart';
import '../utils/app_colors.dart';
import '../models/stock_movement.dart';
import 'add_product_screen.dart';
import 'product_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedDays = 7; // Default filter: Last 7 days

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<StockViewModel>(context);
    final themeViewModel = Provider.of<ThemeViewModel>(context);
    final languageViewModel = Provider.of<LanguageViewModel>(context);
    final settingsViewModel = Provider.of<SettingsViewModel>(context);
    final isDark = themeViewModel.themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black87 : AppColors.grisClair,
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => viewModel.refreshAll(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header & Filter
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          languageViewModel.translate("overview"),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.grisFonce,
                          ),
                        ),
                        DropdownButton<int>(
                          value: _selectedDays,
                          dropdownColor: isDark ? Colors.grey[800] : Colors.white,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                          underline: Container(),
                          icon: const Icon(Icons.filter_list),
                          items: [
                            DropdownMenuItem(value: 7, child: Text(languageViewModel.translate("last_7_days"))),
                            DropdownMenuItem(value: 30, child: Text(languageViewModel.translate("last_30_days"))),
                            DropdownMenuItem(value: 90, child: Text(languageViewModel.translate("last_3_months"))),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedDays = val;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // KPIs Grid
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        // Responsive Grid: 2 columns on mobile, 4 on tablet/desktop
                        int crossAxisCount = width < 600 ? 2 : 4;
                        double childAspectRatio = width < 600 ? 1.4 : 1.8;

                        return GridView.count(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          childAspectRatio: childAspectRatio,
                          children: [
                            _buildStatCard(
                              languageViewModel.translate("total_value"),
                              settingsViewModel.formatPrice(viewModel.totalStockValue),
                              AppColors.bleuStock,
                              Icons.monetization_on,
                              isDark,
                            ),
                            _buildStatCard(
                              languageViewModel.translate("low_stock"),
                              viewModel.lowStockCount.toString(),
                              AppColors.orangeAlerte,
                              Icons.warning_amber_rounded,
                              isDark,
                            ),
                            _buildStatCard(
                              languageViewModel.translate("total_products"),
                              viewModel.totalProducts.toString(),
                              AppColors.vertCroissance,
                              Icons.inventory_2,
                              isDark,
                            ),
                            _buildStatCard(
                              languageViewModel.translate("movements"),
                              viewModel.getRecentMovements(_selectedDays).length.toString(),
                              Colors.purple,
                              Icons.sync_alt,
                              isDark,
                              subtitle: languageViewModel.translate('last_7_days').replaceAll('7', '$_selectedDays').replaceAll('derniers jours', 'jours'),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Charts Section (Now Stats Section)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth > 800) {
                          // Side by side on large screens
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 2, child: _buildMovementStatsSection(viewModel, languageViewModel, isDark)),
                              const SizedBox(width: 20),
                              Expanded(flex: 1, child: _buildPieChartSection(viewModel, isDark)),
                            ],
                          );
                        } else {
                          // Stacked on small screens
                          return Column(
                            children: [
                              _buildMovementStatsSection(viewModel, languageViewModel, isDark),
                              const SizedBox(height: 24),
                              _buildPieChartSection(viewModel, isDark),
                            ],
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    // Top Sales Section
                    if (viewModel.topSales.isNotEmpty) ...[
                      Text(
                        languageViewModel.translate("top_sales"),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 110,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: viewModel.topSales.length,
                          itemBuilder: (context, index) {
                            final item = viewModel.topSales[index];
                            return _buildTopSaleCard(item, isDark, languageViewModel);
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Recent Products Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          languageViewModel.translate("recent_products"),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // Since this is a dashboard, we navigate to the Products tab for "See All"
                        // But we can't easily switch tabs from here without a callback or ancestor access.
                        // We'll just leave it or add a simple button if needed.
                      ],
                    ),
                    const SizedBox(height: 10),

                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: viewModel.products.take(5).length,
                      itemBuilder: (context, index) {
                        final product = viewModel.products[index];
                        return Card(
                          color: isDark ? Colors.grey[900] : Colors.white,
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: Container(
                              width: 50, height: 50,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.grey[800] : Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
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
                                  ? Icon(Icons.image, color: isDark ? Colors.grey : Colors.grey)
                                  : null,
                            ),
                            title: Text(
                              product.name,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black
                              ),
                            ),
                            subtitle: Text(
                              "${languageViewModel.translate('qty')}: ${product.quantity}  •  ${product.category}",
                              style: TextStyle(
                                color: product.quantity < 5
                                    ? AppColors.rougeErreur
                                    : (isDark ? Colors.grey[400] : AppColors.grisMaster),
                              ),
                            ),
                            trailing: Text(
                              NumberFormat.currency(symbol: '\$').format(product.sellingPrice),
                              style: const TextStyle(
                                color: AppColors.vertCroissance,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProductDetailScreen(product: product),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 80), // Space for FAB
                  ],
                ),
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

  Widget _buildStatCard(String title, String value, Color color, IconData icon, bool isDark, {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 10, color: isDark ? Colors.grey[500] : Colors.grey),
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.grisFonce
                ),
              ),
              Text(
                title,
                style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : AppColors.grisMaster
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopSaleCard(Map<String, dynamic> item, bool isDark, LanguageViewModel languageViewModel) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            item['productName'] ?? 'Unknown',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "${item['totalSold']} ${languageViewModel.translate('sold')}",
            style: const TextStyle(
              color: AppColors.vertCroissance,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovementStatsSection(StockViewModel viewModel, LanguageViewModel languageViewModel, bool isDark) {
    final movements = viewModel.getRecentMovements(_selectedDays);
    
    // Calculate Summary Stats
    int totalIn = 0;
    int totalOut = 0;
    
    // Prepare Daily Stats for Chart
    Map<String, Map<String, int>> dailyStats = {};
    // Initialize with 0s
    for (int i = 0; i < _selectedDays; i++) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      dailyStats[dateStr] = {'IN': 0, 'OUT': 0};
    }

    for (var m in movements) {
      if (m.type == MovementType.inward) {
        totalIn += m.quantity;
      } else {
        totalOut += m.quantity;
      }

      final dateStr = DateFormat('yyyy-MM-dd').format(m.date);
      if (dailyStats.containsKey(dateStr)) {
        final typeKey = m.type == MovementType.inward ? 'IN' : 'OUT';
        dailyStats[dateStr]![typeKey] = (dailyStats[dateStr]![typeKey] ?? 0) + m.quantity;
      }
    }

    final sortedKeys = dailyStats.keys.toList()..sort(); // Oldest first
    
    // Determine MaxY and check for data existence
    double maxY = 0;
    bool hasData = false;
    List<BarChartGroupData> barGroups = [];

    for (int i = 0; i < sortedKeys.length; i++) {
      final key = sortedKeys[i];
      final inQty = dailyStats[key]!['IN']!.toDouble();
      final outQty = dailyStats[key]!['OUT']!.toDouble();
      
      if (inQty > 0 || outQty > 0) hasData = true;
      if (inQty > maxY) maxY = inQty;
      if (outQty > maxY) maxY = outQty;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: inQty,
              color: AppColors.vertCroissance,
              width: 8,
              borderRadius: BorderRadius.circular(2),
            ),
            BarChartRodData(
              toY: outQty,
              color: AppColors.rougeErreur,
              width: 8,
              borderRadius: BorderRadius.circular(2),
            ),
          ],
          barsSpace: 4, // Space between IN and OUT bars
        ),
      );
    }
    
    if (maxY == 0) maxY = 10;
    maxY *= 1.2;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${languageViewModel.translate('movement_stats')} (${languageViewModel.translate('last_7_days').replaceAll('7', '$_selectedDays').replaceAll('derniers jours', 'jours')})",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          
          // Summary Row
          Row(
            children: [
              Expanded(
                child: _buildSummaryBox(
                  languageViewModel.translate("total_in"),
                  "+$totalIn",
                  AppColors.vertCroissance,
                  Icons.arrow_downward,
                  isDark
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryBox(
                  languageViewModel.translate("total_out"),
                  "-$totalOut",
                  AppColors.rougeErreur,
                  Icons.arrow_upward,
                  isDark
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          Text(
            "Trend (IN vs OUT)",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 10),

          // Chart or Empty State
          SizedBox(
            height: 200,
            child: !hasData
                ? Center(
                    child: Text(
                      languageViewModel.translate("no_activity"),
                      style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey),
                    ),
                  )
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxY,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          tooltipBgColor: isDark ? Colors.grey[800]! : Colors.blueGrey,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                             final dateKey = sortedKeys[group.x.toInt()];
                             final val = rod.toY.toInt();
                             final type = rod.color == AppColors.vertCroissance ? "IN" : "OUT";
                             return BarTooltipItem(
                               "${DateFormat('dd/MM').format(DateTime.parse(dateKey))}\\n",
                               const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                               children: [
                                 TextSpan(
                                   text: "$type: $val",
                                   style: TextStyle(color: rod.color),
                                 ),
                               ]
                             );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              int index = value.toInt();
                              if (index < 0 || index >= sortedKeys.length) return const Text('');
                              
                              // Optimize labels based on count
                              if (sortedKeys.length > 14 && index % (sortedKeys.length ~/ 7) != 0) return const Text('');

                              final date = DateTime.parse(sortedKeys[index]);
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  DateFormat('dd/MM').format(date),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isDark ? Colors.grey : Colors.grey[600],
                                  ),
                                ),
                              );
                            },
                            reservedSize: 30,
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              if (value % (maxY ~/ 5 + 1) != 0) return Container();
                              return Text(
                                value.toInt().toString(),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isDark ? Colors.grey : Colors.grey[600],
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: isDark ? (Colors.grey[800] ?? Colors.grey) : (Colors.grey[200] ?? Colors.grey),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: barGroups,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBox(String title, String value, Color color, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChartSection(StockViewModel viewModel, bool isDark) {
    final distribution = viewModel.categoryDistribution;
    final total = distribution.values.fold(0.0, (sum, val) => sum + val);

    final List<Color> pieColors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.purple,
      Colors.teal,
    ];

    List<PieChartSectionData> sections = [];
    int index = 0;
    distribution.forEach((category, count) {
      final isLarge = count / total > 0.2;
      sections.add(
        PieChartSectionData(
          color: pieColors[index % pieColors.length],
          value: count,
          title: isLarge ? category : '', // Only show title if slice is big enough
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      index++;
    });

    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Categories",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sections: sections,
                      centerSpaceRadius: 40,
                      sectionsSpace: 2,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Legend
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: distribution.entries.map((e) {
                     int idx = distribution.keys.toList().indexOf(e.key);
                     return Padding(
                       padding: const EdgeInsets.symmetric(vertical: 2.0),
                       child: Row(
                         children: [
                           Container(
                             width: 12, height: 12,
                             color: pieColors[idx % pieColors.length],
                           ),
                           const SizedBox(width: 8),
                           Text(
                             "${e.key} (${e.value.toInt()})",
                             style: TextStyle(
                               fontSize: 12,
                               color: isDark ? Colors.grey[300] : Colors.grey[700],
                             ),
                           ),
                         ],
                       ),
                     );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
