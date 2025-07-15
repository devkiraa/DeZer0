import 'package:flutter/material.dart';
import 'passcode_screen.dart';
import 'services/app_management_service.dart';

// Make the main function async to allow for initialization before the app runs
Future<void> main() async {
  // Ensure Flutter's widget binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  // Load the installed tools list from storage before running the app
  await AppManagementService().init();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Colors.orange;
    const backgroundColor = Color(0xFFF2F2F7);

    return MaterialApp(
      title: 'DeZer0 App',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: backgroundColor,
        primaryColor: primaryColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: backgroundColor,
          elevation: 0,
          scrolledUnderElevation: 1,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.black),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: primaryColor,
          unselectedItemColor: Colors.grey,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          clipBehavior: Clip.antiAlias,
        ),
      ),
      home: const PasscodeScreen(),
    );
  }
}