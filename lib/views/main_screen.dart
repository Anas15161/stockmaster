import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/stock_viewmodel.dart';
import '../viewmodels/language_viewmodel.dart';
import '../utils/app_colors.dart';
import 'dashboard_screen.dart';
import 'products_screen.dart';
import 'scan_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Load initial data (Products, History, Stats)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StockViewModel>(context, listen: false).refreshAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Defines if we are on the Scan screen to handle AppBar visibility
    final isScanScreen = _currentIndex == 2;
    final languageViewModel = Provider.of<LanguageViewModel>(context);

    // List of views corresponding to menu items
    final List<Widget> views = [
      const DashboardScreen(),
      const ProductsScreen(),
      ScanScreen(isVisible: isScanScreen),
      const HistoryScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      appBar: isScanScreen
          ? null // Scan screen handles its own AppBar or overlay
          : AppBar(
              backgroundColor: AppColors.bleuStock,
              title: RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: "Stock",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    TextSpan(
                      text: "Master",
                      style: TextStyle(
                        color: AppColors.vertCroissance,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications, color: Colors.white),
                  onPressed: () {
                    // TODO: Implement Notifications
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.person, color: Colors.white),
                  onPressed: () {
                    // Navigate to Settings/Profile (Index 4)
                    setState(() {
                      _currentIndex = 4;
                    });
                  },
                ),
              ],
            ),
      body: IndexedStack(
        index: _currentIndex,
        children: views,
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(color: Colors.white),
          ),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: AppColors.bleuStock);
            }
            return const IconThemeData(color: Colors.white);
          }),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: AppColors.bleuStock,
          indicatorColor: Colors.white,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.dashboard_outlined),
              selectedIcon: const Icon(Icons.dashboard),
              label: languageViewModel.translate('dashboard'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.inventory_2_outlined),
              selectedIcon: const Icon(Icons.inventory_2),
              label: languageViewModel.translate('products'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.qr_code_scanner),
              selectedIcon: const Icon(Icons.qr_code_scanner),
              label: languageViewModel.translate('scan'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.history_outlined),
              selectedIcon: const Icon(Icons.history),
              label: languageViewModel.translate('history'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings),
              label: languageViewModel.translate('settings'),
            ),
          ],
        ),
      ),
    );
  }
}