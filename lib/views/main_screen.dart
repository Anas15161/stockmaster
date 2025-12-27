import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import 'dashboard_screen.dart';
import 'products_screen.dart';
import 'placeholder_views.dart';
import 'scan_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // List of views corresponding to menu items
  // Note: We wrap DashboardScreen in a specific way if it has its own Scaffold.
  // Since DashboardScreen has a Scaffold, it's fine, but the MainScreen Scaffold
  // should ideally just hold the Body and BottomNav, while children provide their own AppBars if needed.
  // Or we remove AppBars from children and have a global one.
  // For now, simple switching is best.
  final List<Widget> _views = [
    const DashboardScreen(),
    const ProductsScreen(),
    const ScanScreen(),
    const OrdersScreen(),
    const MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _views,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: Colors.white,
        indicatorColor: AppColors.bleuStock.withOpacity(0.2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: AppColors.bleuStock),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2, color: AppColors.bleuStock),
            label: 'Products',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner),
            selectedIcon: Icon(Icons.qr_code_scanner, color: AppColors.bleuStock),
            label: 'Scan',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined),
            selectedIcon: Icon(Icons.shopping_cart, color: AppColors.bleuStock),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu),
            selectedIcon: Icon(Icons.menu_open, color: AppColors.bleuStock),
            label: 'More',
          ),
        ],
      ),
    );
  }
}
