import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/login_screen.dart';
import 'screens/user/user_home_screen.dart';
import 'screens/technician/tech_home_screen.dart';
import 'screens/admin/admin_home_screen.dart';
import 'services/api.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyASXpbLwjfrt0Hu0nveTrCTbFhSV502m30",
      authDomain: "quickfixapp-3074a.firebaseapp.com",
      projectId: "quickfixapp-3074a",
      storageBucket: "quickfixapp-3074a.firebasestorage.app",
      messagingSenderId: "952324404929",
      appId: "1:952324404929:web:22b84aa47cc4c6f0140640",
    ),
  );

  runApp(const QuickFixApp());
}

class QuickFixApp extends StatefulWidget {
  const QuickFixApp({super.key});

  @override
  State<QuickFixApp> createState() => _QuickFixAppState();
}

class _QuickFixAppState extends State<QuickFixApp> {
  Widget _defaultScreen = const Scaffold(
    body: Center(child: CircularProgressIndicator()),
  );

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final saved = await Api.getSavedLogin();
    await Future.delayed(const Duration(seconds: 1)); // small delay for UX

    if (saved != null) {
      final role = saved['role'];
      setState(() {
        if (role == 'admin') {
          _defaultScreen = const AdminHomeScreen();
        } else if (role == 'technician') {
          _defaultScreen = const TechnicianHomeScreen();
        } else {
          _defaultScreen = const UserHomeScreen();
        }
      });
    } else {
      setState(() {
        _defaultScreen = const LoginScreen();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuickFix App',
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      home: _defaultScreen,
      routes: {
        '/login': (context) => const LoginScreen(),
        '/userHome': (context) => const UserHomeScreen(),
        '/technicianHome': (context) => const TechnicianHomeScreen(),
        '/adminHome': (context) => const AdminHomeScreen(),
      },
    );
  }
}
