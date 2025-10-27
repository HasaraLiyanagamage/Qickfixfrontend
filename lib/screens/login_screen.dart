import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/api.dart';
import 'register_screen.dart';
import 'admin/admin_home_screen.dart';
import 'technician/tech_home_screen.dart';
import 'user/user_home_screen.dart';
import '../utils/logger.dart';

class LoginScreen extends StatefulWidget {
const LoginScreen({super.key});

@override
State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
final TextEditingController emailController = TextEditingController();
final TextEditingController passwordController = TextEditingController();
bool _isLoading = false;

@override
void initState() {
super.initState();
getLogger('LoginScreen').info('LoginScreen initialized');
}

// Email-password login using backend
Future<void> _login() async {
final email = emailController.text.trim();
final password = passwordController.text.trim();

if (email.isEmpty || password.isEmpty) {
  _showSnackBar("Please enter both email and password");
  return;
}

setState(() => _isLoading = true);
final result = await Api.login(email, password);
setState(() => _isLoading = false);

if (result != null && result['token'] != null) {
  Api.token = result['token'];
  final user = result['user'];
  final role = user['role']; // admin / technician / user

  _showSnackBar("Welcome back, ${user['name']}!");
  _navigateToHome(role: role);
} else {
  _showSnackBar("Invalid credentials. Please try again.");
}


}

// Google Sign-In
Future<void> _loginWithGoogle() async {
try {
GoogleAuthProvider googleProvider = GoogleAuthProvider();
googleProvider.addScope('email');
googleProvider.addScope('profile');

  UserCredential userCredential =
      await FirebaseAuth.instance.signInWithProvider(googleProvider);
  User? user = userCredential.user;

  if (user != null && mounted) {
    _showSnackBar("Welcome, ${user.displayName ?? 'User'}!");
    _navigateToHome(role: 'user'); // default for Google users
  }
} catch (e) {
  _showSnackBar("Google sign-in failed: $e");
}


}

// Facebook Sign-In
Future<void> _loginWithFacebook() async {
try {
FacebookAuthProvider facebookProvider = FacebookAuthProvider();
facebookProvider.addScope('email');
facebookProvider.addScope('public_profile');

  UserCredential userCredential =
      await FirebaseAuth.instance.signInWithProvider(facebookProvider);
  User? user = userCredential.user;

  if (user != null && mounted) {
    _showSnackBar("Facebook login successful!");
    _navigateToHome(role: 'user'); // default for Facebook users
  }
} catch (e) {
  _showSnackBar("Facebook login failed: $e");
}


}

// Apple Sign-In
Future<void> _loginWithApple() async {
try {
OAuthProvider appleProvider = OAuthProvider('apple.com');
appleProvider.addScope('email');
appleProvider.addScope('name');

  UserCredential userCredential =
      await FirebaseAuth.instance.signInWithProvider(appleProvider);
  User? user = userCredential.user;

  if (user != null && mounted) {
    _showSnackBar("Apple login successful!");
    _navigateToHome(role: 'user'); // default for Apple users
  }
} catch (e) {
  _showSnackBar("Apple login failed: $e");
}


}

// Role-based navigation
void _navigateToHome({String role = 'user'}) {
Widget screen;
switch (role) {
case 'admin':
screen = const AdminHomeScreen();
break;
case 'technician':
screen = const TechnicianHomeScreen();
break;
default:
screen = const UserHomeScreen();
}

Navigator.pushReplacement(
  context,
  MaterialPageRoute(builder: (_) => screen),
);


}

void _showSnackBar(String msg) {
ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}

@override
Widget build(BuildContext context) {
getLogger('LoginScreen').fine('LoginScreen building...');
return Scaffold(
backgroundColor: Colors.blue[50],
body: Center(
child: SingleChildScrollView(
padding: const EdgeInsets.all(24),
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
const Icon(Icons.build_circle, size: 80, color: Colors.blueAccent),
const SizedBox(height: 20),
const Text(
"QuickFix Login",
style: TextStyle(
fontSize: 26,
fontWeight: FontWeight.bold,
color: Colors.blueAccent),
),
const SizedBox(height: 30),

          // Email + Password Fields
          TextField(
            controller: emailController,
            decoration: const InputDecoration(
                labelText: "Email", border: OutlineInputBorder()),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(
                labelText: "Password", border: OutlineInputBorder()),
          ),
          const SizedBox(height: 20),

          _isLoading
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 60, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10))),
                  child: const Text("Login",
                      style:
                          TextStyle(fontSize: 16, color: Colors.white)),
                ),
          const SizedBox(height: 15),

          // Divider
          Row(children: const [
            Expanded(child: Divider(thickness: 1)),
            Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text("or continue with",
                    style: TextStyle(color: Colors.grey))),
            Expanded(child: Divider(thickness: 1)),
          ]),
          const SizedBox(height: 15),

          // Social Logins
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _socialButton(Icons.account_circle, Colors.blue, _loginWithGoogle),
              const SizedBox(width: 15),
              _socialButton(Icons.facebook, Colors.blue.shade800, _loginWithFacebook),
              const SizedBox(width: 15),
              _socialButton(Icons.apple, Colors.black, _loginWithApple),
            ],
          ),

          const SizedBox(height: 25),
          TextButton(
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const RegisterScreen()));
            },
            child: const Text("Don't have an account? Register"),
          ),
        ],
      ),
    ),
  ),
);


}

Widget _socialButton(IconData icon, Color color, Function() onTap) {
return InkWell(
onTap: onTap,
child: CircleAvatar(
radius: 25,
backgroundColor: color,
child: Icon(icon, size: 30, color: Colors.white),
),
);
}
}