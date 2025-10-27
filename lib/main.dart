import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/home_screen.dart';
import 'screens/chatbot_screen.dart';
import 'screens/bookings_screen.dart';
import 'screens/login_screen.dart';
import 'utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logging
  initLogging();

  // Initialize Firebase with platform-specific options
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyASXpbLwjfrt0Hu0nveTrCTbFhSV502m30",
      authDomain: "quickfixapp-3074a.firebaseapp.com",
      projectId: "quickfixapp-3074a",
      storageBucket: "quickfixapp-3074a.firebasestorage.app",
      messagingSenderId: "952324404929",
      appId: "1:952324404929:web:22b84aa47cc4c6f0140640"
    ),
  );

  getLogger('Main').info('Firebase initialized successfully');

  runApp(const QuickFixApp());
}

class QuickFixApp extends StatelessWidget {
  const QuickFixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuickFix App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LoginScreen(), 
      debugShowCheckedModeBanner: false,
    );
  }
}


class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const BookingsScreen(),
    const ChatbotScreen(), 
  ];

  final List<String> _titles = [
    'Home',
    'Bookings',
    'Chatbot 🤖',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        backgroundColor: Colors.blueAccent,
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work_outline),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chatbot',
          ),
        ],
      ),
    );
  }
}
