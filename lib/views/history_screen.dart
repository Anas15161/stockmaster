import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../viewmodels/stock_viewmodel.dart';
import '../viewmodels/theme_viewmodel.dart';
import '../viewmodels/language_viewmodel.dart';
import '../models/stock_movement.dart';
import '../utils/app_colors.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String _filterType = "All"; // All, IN, OUT
  String _sortOrder = "Newest"; // Newest, Oldest

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
    final dateFormat = DateFormat('HH:mm');

    // Filter and Sort Logic
    List<StockMovement> filteredList = viewModel.movements.where((m) {
      // Search
      final query = _searchQuery.toLowerCase();
      final matchesSearch = m.productName.toLowerCase().contains(query) ||
                            (m.reason?.toLowerCase().contains(query) ?? false) ||
                            m.userId.toLowerCase().contains(query);
      
      // Filter Type
      bool matchesType = true;
      if (_filterType == "IN") {
        matchesType = m.type == MovementType.inward;
      }
      if (_filterType == "OUT") {
        matchesType = m.type == MovementType.outward;
      }

      return matchesSearch && matchesType;
    }).toList();

    // Sort
    filteredList.sort((a, b) {
      if (_sortOrder == "Newest") {
        return b.date.compareTo(a.date);
      } else {
        return a.date.compareTo(b.date);
      }
    });

    // Group by Date
    Map<String, List<StockMovement>> groupedMovements = {};
    for (var m in filteredList) {
      final dateKey = DateFormat('yyyy-MM-dd').format(m.date);
      if (!groupedMovements.containsKey(dateKey)) {
        groupedMovements[dateKey] = [];
      }
      groupedMovements[dateKey]!.add(m);
    }

    final sortedGroupKeys = groupedMovements.keys.toList();
    if (_sortOrder == "Newest") {
      // Keys are strings yyyy-MM-dd so default sort is oldest first, reverse for newest
      sortedGroupKeys.sort((a, b) => b.compareTo(a)); 
    } else {
      sortedGroupKeys.sort();
    }

    return Scaffold(
      backgroundColor: isDark ? Colors.black87 : const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Controls Section
          Container(
            color: isDark ? Colors.grey[900] : Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: languageViewModel.translate('search_history'),
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  ),
                ),
                const SizedBox(height: 12),
                // Filters Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Filter Type Chip
                      _buildFilterChip(
                        label: "${languageViewModel.translate('type')}: ${_filterType == 'All' ? languageViewModel.translate('all') : _filterType}",
                        icon: Icons.filter_alt,
                        onTap: () {
                          // Cycle filters: All -> IN -> OUT -> All
                          setState(() {
                            if (_filterType == "All") {
                              _filterType = "IN";
                            } else if (_filterType == "IN") {
                              _filterType = "OUT";
                            } else {
                              _filterType = "All";
                            }
                          });
                        },
                        isSelected: _filterType != "All",
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      // Sort Order Chip
                      _buildFilterChip(
                        label: "${languageViewModel.translate('date')}: ${_sortOrder == 'Newest' ? languageViewModel.translate('newest') : languageViewModel.translate('oldest')}",
                        icon: Icons.sort,
                        onTap: () {
                          setState(() {
                            _sortOrder = _sortOrder == "Newest" ? "Oldest" : "Newest";
                          });
                        },
                        isSelected: false, // Always active
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: filteredList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 64, color: isDark ? Colors.grey[700] : Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          languageViewModel.translate('no_history'),
                          style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => viewModel.fetchMovements(),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: sortedGroupKeys.length,
                      itemBuilder: (context, index) {
                        final dateKey = sortedGroupKeys[index];
                        final movementsForDate = groupedMovements[dateKey]!;
                        final date = DateTime.parse(dateKey);
                        
                        String headerDate;
                        final now = DateTime.now();
                        final today = DateTime(now.year, now.month, now.day);
                        final yesterday = today.subtract(const Duration(days: 1));
                        final checkDate = DateTime(date.year, date.month, date.day);

                        if (checkDate == today) {
                          headerDate = "Today"; // Translate? 'today' key missing, assuming english or format
                          // Since I don't have 'today' key, I'll use standard format or just DateFormat
                          // Actually, DateFormat.yMMMd() is good.
                          headerDate = DateFormat.yMMMd().format(date); // Fallback
                        } else if (checkDate == yesterday) {
                          headerDate = DateFormat.yMMMd().format(date);
                        } else {
                          headerDate = DateFormat.yMMMd().format(date);
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4),
                              child: Text(
                                headerDate,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            ...movementsForDate.map((movement) {
                              final isIn = movement.type == MovementType.inward;
                              return Card(
                                elevation: 1,
                                margin: const EdgeInsets.only(bottom: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                color: isDark ? Colors.grey[900] : Colors.white,
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: isIn 
                                        ? AppColors.vertCroissance.withValues(alpha: 0.1) 
                                        : AppColors.rougeErreur.withValues(alpha: 0.1),
                                    child: Icon(
                                      isIn ? Icons.arrow_downward : Icons.arrow_upward,
                                      color: isIn ? AppColors.vertCroissance : AppColors.rougeErreur,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    movement.productName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white : Colors.black87,
                                      fontSize: 15,
                                    ),
                                  ),
                                  subtitle: Row(
                                    children: [
                                      Text(
                                        dateFormat.format(movement.date),
                                        style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[500] : Colors.grey[500]),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          movement.reason ?? (isIn ? languageViewModel.translate('restock') : languageViewModel.translate('sale_use')),
                                          style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        "${isIn ? '+' : '-'}${movement.quantity}",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: isIn ? AppColors.vertCroissance : AppColors.rougeErreur,
                                        ),
                                      ),
                                      Text(
                                        movement.userId,
                                        style: TextStyle(fontSize: 10, color: isDark ? Colors.grey[600] : Colors.grey[400]),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required bool isSelected,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.bleuStock.withValues(alpha: 0.1) 
              : (isDark ? Colors.grey[800] : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? AppColors.bleuStock 
                : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? AppColors.bleuStock : (isDark ? Colors.grey[400] : Colors.grey[600])),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.bleuStock : (isDark ? Colors.grey[300] : Colors.grey[700]),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
