import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text("Orders Management (Coming Soon)", style: TextStyle(fontSize: 18, color: AppColors.grisMaster))),
    );
  }
}

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: const [
          ListTile(leading: Icon(Icons.settings), title: Text("Settings")),
          ListTile(leading: Icon(Icons.help), title: Text("Help & Support")),
          ListTile(leading: Icon(Icons.info), title: Text("About")),
        ],
      ),
    );
  }
}
