import 'package:eye_health/pages/splash_screen/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nb_utils/nb_utils.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initialize();
  _configureToasts();
  // await SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const MyApp());
}

void _configureToasts() {
  defaultToastBackgroundColor = Colors.black;
  defaultToastTextColor = Colors.white;
  defaultToastGravityGlobal = ToastGravity.CENTER;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const String appTitle = 'Eye Health';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appTitle,
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: const SplashScreen(),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.green[900],
        foregroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    );
  }
}
