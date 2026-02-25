import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Services - Voice Agent Added
import '../provider/address_provider.dart';
import '../provider/auth_provider.dart';
import '../provider/cart_provider.dart';
import '../provider/notification_provider.dart';
import '../provider/order_provider.dart';
import '../provider/profile_provider.dart';
import '../provider/return_refund_provider.dart';
import '../provider/search_provider.dart';
import '../provider/smart_cart_optimizer_provider.dart';
import '../provider/support_agent_provider.dart';
import '../provider/voice_agent_provider.dart'; // Voice Agent
import '../provider/wallet_provider.dart';
import '../provider/wishlist_provider.dart';
import '../screens/address_management_screen.dart';
import '../screens/ai_support_screen.dart';
import '../screens/auth_screen.dart';
import '../screens/cart_screen.dart';
import '../screens/checkout_screen.dart';
import '../screens/enhanced_order_detail_screen.dart';
import '../screens/history_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/order_success_screen.dart';
import '../screens/past_order_screen.dart';
import '../screens/product_detail_screen.dart';
import '../screens/product_search_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/return_request_screen.dart';
import '../screens/return_status_screen.dart';
import '../screens/smart_cart_optimizer_screen.dart';
import '../screens/transaction_api_screen.dart';
import '../screens/voice_agent_screen.dart'; // Voice Agent Screen
import '../screens/wallet_screen_with_shopping.dart';
import '../screens/wishlist_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notification provider for in-app notifications
  final notificationProvider = NotificationProvider();
  await notificationProvider.initialize();

  runApp(
    MultiProvider(
      providers: [
        // Notification Provider (pre-initialized)
        ChangeNotifierProvider<NotificationProvider>.value(
          value: notificationProvider,
        ),

        // Core Providers
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => AddressProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(create: (_) => ReturnRefundProvider()),

        // AI-Powered Providers
        ChangeNotifierProvider(create: (_) => SupportAgentProvider()),
        ChangeNotifierProvider(create: (_) => SmartCartOptimizerProvider()),
        ChangeNotifierProvider(create: (_) => VoiceAgentProvider()), // Voice Agent
      ],
      child: const MyApp(),
    ),
  );

  // Welcome notification after 2 seconds
  Future.delayed(const Duration(seconds: 2), () {
    notificationProvider.showNotification(
      title: '🎉 Welcome to Meesho Mock!',
      body: 'Sign in to start your shopping journey with AI-powered features.',
      type: NotificationType.generalUpdate,
      data: {'route': '/login'},
    );
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Meesho Mock App",
      theme: ThemeData(
        useMaterial3: true,
        // Meesho's distinctive Purple theme
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF9C27B0),
          primary: const Color(0xFF9C27B0),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF9C27B0), width: 2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF9C27B0),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle:
            const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF9C27B0),
          foregroundColor: Colors.white,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: Colors.purple.shade50,
          labelStyle: const TextStyle(
            color: Color(0xFF9C27B0),
            fontWeight: FontWeight.w600,
          ),
          side: BorderSide(color: Colors.purple.shade200),
        ),
      ),

      // App starts at Auth/Login Screen
      home: const AuthScreen(),

      routes: {
        // ==================
        // Authentication
        // ==================
        "/login": (context) => const AuthScreen(),

        // ==================
        // Shopping & Search
        // ==================
        "/shopping": (context) => const ProductSearchScreen(),
        "/search": (context) => const ProductSearchScreen(),
        "/cart": (context) => const CartScreen(),
        "/checkout": (context) => const CheckoutScreen(),

        // ==================
        // Wallet & Money
        // ==================
        "/wallet": (context) => const WalletScreen(),
        "/history": (context) => const HistoryScreen(),
        "/transactionsApi": (context) => const TransactionApiScreen(),

        // ==================
        // User Profile
        // ==================
        "/profile": (context) => const ProfileScreen(),
        "/addresses": (context) => const AddressManagementScreen(),
        "/wishlist": (context) => const WishlistScreen(),
        "/notifications": (context) => const NotificationsScreen(),

        // ==================
        // Orders
        // ==================
        "/pastOrders": (context) => const PastOrdersScreen(),

        // ==================
        // AI Features
        // ==================
        "/support": (context) => const AISupportScreen(),
        "/cartOptimizer": (context) => const SmartCartOptimizerScreen(),
        "/voiceAgent": (context) => const VoiceAgentScreen(), // Voice Agent Route
      },

      onUnknownRoute: (settings) => MaterialPageRoute(
        builder: (context) => const AuthScreen(),
      ),

      onGenerateRoute: (settings) {
        // ==================
        // Product Detail
        // ==================
        if (settings.name == '/productDetail') {
          return MaterialPageRoute(
            builder: (context) =>
                ProductDetailScreen(product: settings.arguments as dynamic),
          );
        }

        // ==================
        // Order Success
        // ==================
        if (settings.name == '/orderSuccess') {
          return MaterialPageRoute(
            builder: (context) =>
                OrderSuccessScreen(orderId: settings.arguments as String),
          );
        }

        // ==================
        // Order Detail
        // ==================
        if (settings.name == '/orderDetail') {
          return MaterialPageRoute(
            builder: (context) =>
                EnhancedOrderDetailScreen(order: settings.arguments as dynamic),
          );
        }

        // ==================
        // Return Request
        // ==================
        if (settings.name == '/returnRequest') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => ReturnRequestScreen(
              orderId: args['orderId'],
              orderItemId: args['orderItemId'],
              productId: args['productId'],
              productName: args['productName'],
              productImage: args['productImage'],
              price: args['price'],
              quantity: args['quantity'],
            ),
          );
        }

        // ==================
        // Return Status
        // ==================
        if (settings.name == '/returnStatus') {
          return MaterialPageRoute(
            builder: (context) =>
                ReturnStatusScreen(returnId: settings.arguments as String),
          );
        }

        return null;
      },
    );
  }
}