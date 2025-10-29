import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/api.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isLoading = false;

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
      _showSnackBar("Welcome back!");
      _navigateByRole(result['user']['role']);
    } else {
      _showSnackBar("Invalid credentials. Please try again.");
    }
  }

  Future<void> _loginWithGoogle() async {
    try {
      UserCredential userCredential;

      if (kIsWeb) {
        GoogleAuthProvider provider = GoogleAuthProvider();
        provider.addScope('email');
        provider.addScope('profile');
        userCredential = await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) return;
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);
      }

      final user = userCredential.user;
      if (user != null) {
        final result = await Api.socialLogin(
          email: user.email ?? '',
          name: user.displayName ?? 'User',
          provider: 'google',
        );
        if (result != null && result['token'] != null) {
          Api.token = result['token'];
          _showSnackBar("Welcome, ${user.displayName ?? 'User'}!");
          _navigateByRole(result['user']['role']);
        } else {
          _showSnackBar("Google sign-in failed. Please try again.");
        }
      }
    } catch (e) {
      _showSnackBar("Google sign-in failed: $e");
    }
  }

  
  Future<void> _loginWithFacebook() async {
    try {
      if (kIsWeb) {
        final facebookProvider = FacebookAuthProvider();
        facebookProvider.addScope('email');
        final userCredential =
            await FirebaseAuth.instance.signInWithPopup(facebookProvider);
        final user = userCredential.user;
        if (user != null) {
          final result = await Api.socialLogin(
            email: user.email ?? '',
            name: user.displayName ?? 'Facebook User',
            provider: 'facebook',
          );
          if (result != null && result['token'] != null) {
            Api.token = result['token'];
            _showSnackBar("Welcome, ${user.displayName ?? 'Facebook User'}!");
            _navigateByRole(result['user']['role']);
          } else {
            _showSnackBar("Facebook login failed. Please try again.");
          }
        }
      } else {
        final facebookProvider = FacebookAuthProvider();
        final userCredential =
            await FirebaseAuth.instance.signInWithProvider(facebookProvider);
        final user = userCredential.user;
        if (user != null) {
          final result = await Api.socialLogin(
            email: user.email ?? '',
            name: user.displayName ?? 'Facebook User',
            provider: 'facebook',
          );
          if (result != null && result['token'] != null) {
            Api.token = result['token'];
            _showSnackBar("Welcome, ${user.displayName ?? 'Facebook User'}!");
            _navigateByRole(result['user']['role']);
          } else {
            _showSnackBar("Facebook login failed. Please try again.");
          }
        }
      }
    } catch (e) {
      _showSnackBar("Facebook login failed: $e");
    }
  }

  Future<void> _loginWithApple() async {
    try {
      if (kIsWeb) {
        final appleProvider = OAuthProvider('apple.com');
        final userCredential =
            await FirebaseAuth.instance.signInWithPopup(appleProvider);
        final user = userCredential.user;
        if (user != null) {
          final result = await Api.socialLogin(
            email: user.email ?? '',
            name: user.displayName ?? 'Apple User',
            provider: 'apple',
          );
          if (result != null && result['token'] != null) {
            Api.token = result['token'];
            _showSnackBar("Welcome, ${user.displayName ?? 'Apple User'}!");
            _navigateByRole(result['user']['role']);
          } else {
            _showSnackBar("Apple login failed. Please try again.");
          }
        }
      } else {
        final appleProvider = OAuthProvider('apple.com');
        final userCredential =
            await FirebaseAuth.instance.signInWithProvider(appleProvider);
        final user = userCredential.user;
        if (user != null) {
          final result = await Api.socialLogin(
            email: user.email ?? '',
            name: user.displayName ?? 'Apple User',
            provider: 'apple',
          );
          if (result != null && result['token'] != null) {
            Api.token = result['token'];
            _showSnackBar("Welcome, ${user.displayName ?? 'Apple User'}!");
            _navigateByRole(result['user']['role']);
          } else {
            _showSnackBar("Apple login failed. Please try again.");
          }
        }
      }
    } catch (e) {
      _showSnackBar("Apple login failed: $e");
    }
  }

  
  void _navigateByRole(String role) {
    if (role == 'admin') {
      Navigator.pushReplacementNamed(context, '/adminHome');
    } else if (role == 'technician') {
      Navigator.pushReplacementNamed(context, '/technicianHome');
    } else {
      Navigator.pushReplacementNamed(context, '/userHome');
    }
  }


  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.build_circle,
                  size: 80, color: Colors.blueAccent),
              const SizedBox(height: 20),
              const Text(
                "QuickFix Login",
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent),
              ),
              const SizedBox(height: 30),
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
                          style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
              const SizedBox(height: 15),
              Row(children: const [
                Expanded(child: Divider(thickness: 1)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text("or continue with",
                      style: TextStyle(color: Colors.grey)),
                ),
                Expanded(child: Divider(thickness: 1)),
              ]),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _socialButton(Icons.account_circle, Colors.red, _loginWithGoogle),
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
