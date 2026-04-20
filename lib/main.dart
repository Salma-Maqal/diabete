import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/health_info_screen.dart';
import 'screens/companion_info_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/add_companion_screen.dart';
import 'screens/verify_screen.dart';
import 'screens/forgot_password_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  runApp(const CalmSugarApp());
}

class CalmSugarApp extends StatelessWidget {
  const CalmSugarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CalmSugar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFE7F5DC),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF728156),
        ),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/':                 (_) => const SplashScreen(),
        '/welcome':          (_) => const WelcomeScreen(),
        '/login':            (_) => const LoginScreen(),
        '/signup':           (_) => const SignUpScreen(),
        '/health-info':      (_) => const HealthInfoScreen(),
        '/companion-info':   (_) => const CompanionInfoScreen(),
        '/dashboard':        (_) => const DashboardScreen(),
        '/add-companion':    (_) => const AddCompanionScreen(),
        '/verify':           (_) => const VerifyScreen(),
        '/forgot-password':  (_) => const ForgotPasswordScreen(), // ✅ جديد
      },
    );
  }
}