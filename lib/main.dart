import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/canvas_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Fully transparent status bar + nav bar (matches HTML prototype)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Lock to portrait on phones; landscape allowed on tablets
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const BotFlowApp());
}

class BotFlowApp extends StatelessWidget {
  const BotFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BotFlow Builder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF8774E1),
          surface: Color(0xFF14151c),
          onSurface: Color(0xFFf2f2f4),
        ),
        fontFamily: 'SF Pro Display',
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFFf2f2f4)),
        ),
      ),
      home: const CanvasScreen(),
    );
  }
}
