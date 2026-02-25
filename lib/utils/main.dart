import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/auth_provider.dart';
import '../provider/wallet_provider.dart';
import '../screens/history_screen.dart';
import '../screens/shopping_screen.dart';
import '../screens/transaction_api_screen.dart';

import '../screens/wallet_screen_with_shopping.dart';





Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: "UPI Mock App",
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),

        // ✅ Wallet Screen as home
        home: const WalletScreen(),

        routes: {
          "/wallet": (context) => const WalletScreen(),
          "/history": (context) => const HistoryScreen(),
          "/transactionsApi": (context) => const TransactionApiScreen(),
          "/shopping": (context) => const ShoppingScreen(),
        },
      ),
    );
  }
}