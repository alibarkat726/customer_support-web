import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'utils/app_routes.dart';
import 'screens/home_screen.dart';
import 'screens/customer_chat_screen.dart';
import 'screens/owner_dashboard_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Customer Service Bot',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6C63FF)),
        useMaterial3: true,
      ),
      initialRoute: AppRoutes.home,
      getPages: [
        GetPage(name: AppRoutes.home, page: () => const HomeScreen()),
        GetPage(name: AppRoutes.customerChat, page: () => const CustomerChatScreen()),
        GetPage(name: AppRoutes.ownerDashboard, page: () => OwnerDashboardScreen()),
      ],
    );
  }
}
