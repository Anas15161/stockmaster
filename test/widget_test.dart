import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:stock_master/views/login_screen.dart';
import 'package:stock_master/viewmodels/auth_viewmodel.dart';
import 'package:stock_master/viewmodels/stock_viewmodel.dart';
import 'package:stock_master/viewmodels/theme_viewmodel.dart';

void main() {
  testWidgets('Login Screen UI Test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthViewModel()),
          ChangeNotifierProvider(create: (_) => StockViewModel()),
          ChangeNotifierProvider(create: (_) => ThemeViewModel()),
        ],
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    expect(find.text('StockMaster'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);

    expect(find.text('0'), findsNothing);
    expect(find.byIcon(Icons.add), findsNothing);
  });
}
