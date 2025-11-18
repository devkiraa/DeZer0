import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'loading_screen.dart';
import 'services/app_management_service.dart';
import 'services/wifi_service.dart';
import 'services/hotspot_service.dart';
import 'theme/flipper_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set system UI overlay style for Flipper Zero theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: FlipperColors.surface,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  
  await AppManagementService.instance.init();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WifiService()),
        ChangeNotifierProvider(create: (_) => HotspotService()),
        Provider(create: (_) => AppManagementService.instance),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DeZer0',
      theme: FlipperTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: const LoadingScreen(),
    );
  }
}