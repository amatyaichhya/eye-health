import 'package:eye_health/pages/splash_screen/splash_screen.dart';
import 'package:eye_health/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:nb_utils/nb_utils.dart';

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  // Keep native splash up until Flutter SplashScreen removes it.
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await initialize();
  _configureToasts();
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
      theme: AppTheme.light(),
      home: const SplashScreen(),
    );
  }
}
