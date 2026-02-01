import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'screens/splash_screen.dart';

void main() {
  runApp(const SavingsTipCalendarApp());
}

class SavingsTipCalendarApp extends StatelessWidget {
  const SavingsTipCalendarApp({super.key});

  // Samsung A53 dimensions: 412 x 915 dp
  static const double phoneWidth = 412;
  static const double phoneHeight = 915;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Savings and Tip Note Calendar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        primaryColor: const Color(0xFF4CAF50),
        scaffoldBackgroundColor: const Color(0xFFF5F9F5),
        colorScheme: ColorScheme.light(
          primary: const Color(0xFF4CAF50),
          secondary: const Color(0xFF81C784),
          surface: Colors.white,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: const Color(0xFF2E7D32),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF66BB6A),
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF81C784)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF81C784)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
          ),
        ),
        useMaterial3: true,
      ),
      builder: (context, child) {
        if (kIsWeb) {
          return PhoneFrameWrapper(child: child!);
        }
        return child!;
      },
      home: const SplashScreen(),
    );
  }
}

class PhoneFrameWrapper extends StatelessWidget {
  final Widget child;
  
  const PhoneFrameWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    const double phoneWidth = SavingsTipCalendarApp.phoneWidth;
    const double phoneHeight = SavingsTipCalendarApp.phoneHeight;
    const double frameThickness = 12;
    const double borderRadius = 40;

    return Container(
      color: const Color(0xFF1a1a2e),
      child: Center(
        child: Container(
          width: phoneWidth + (frameThickness * 2),
          height: phoneHeight + (frameThickness * 2),
          decoration: BoxDecoration(
            color: const Color(0xFF2d2d44),
            borderRadius: BorderRadius.circular(borderRadius + frameThickness),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 30,
                spreadRadius: 5,
              ),
              BoxShadow(
                color: const Color(0xFF4CAF50).withOpacity(0.2),
                blurRadius: 60,
                spreadRadius: -10,
              ),
            ],
            border: Border.all(
              color: const Color(0xFF3d3d5c),
              width: 2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(frameThickness),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  size: const Size(phoneWidth, phoneHeight),
                ),
                child: SizedBox(
                  width: phoneWidth,
                  height: phoneHeight,
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
