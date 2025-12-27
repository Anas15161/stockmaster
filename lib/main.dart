import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodels/stock_viewmodel.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/theme_viewmodel.dart';
import 'views/main_screen.dart';
import 'views/login_screen.dart';
import 'utils/app_colors.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const StockMasterApp());
}

class StockMasterApp extends StatelessWidget {
  const StockMasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => StockViewModel()..fetchProducts()),
        ChangeNotifierProvider(create: (_) => AuthViewModel()..checkLoginStatus()),
        ChangeNotifierProvider(create: (_) => ThemeViewModel()),
      ],
      child: Consumer<ThemeViewModel>(
        builder: (context, themeViewModel, child) {
          return MaterialApp(
            title: 'StockMaster',
            debugShowCheckedModeBanner: false,
            themeMode: themeViewModel.themeMode,
            theme: ThemeData(
              primaryColor: AppColors.bleuStock,
              scaffoldBackgroundColor: AppColors.grisClair,
              colorScheme: ColorScheme.fromSwatch().copyWith(
                primary: AppColors.bleuStock,
                secondary: AppColors.vertCroissance,
                error: AppColors.rougeErreur,
              ),
              appBarTheme: const AppBarTheme(
                elevation: 0,
                centerTitle: true,
              ),
            ),
            darkTheme: ThemeData.dark().copyWith(
              primaryColor: AppColors.bleuStock,
              colorScheme: const ColorScheme.dark().copyWith(
                 primary: AppColors.bleuStock,
                 secondary: AppColors.vertCroissance,
              ),
            ),
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);

    if (authViewModel.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (authViewModel.currentUser != null) {
      return const MainScreen();
    } else {
      return const LoginScreen();
    }
  }
}
