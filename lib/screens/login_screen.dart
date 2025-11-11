import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/api.dart';
import '../utils/app_theme.dart';
import '../widgets/modern_card.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [AppTheme.darkBackground, AppTheme.darkSurface]
                : [AppTheme.primaryBlue.withValues(alpha: 0.05), AppTheme.lightBackground],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingLarge),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo and Title
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.build_circle,
                        size: 64,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingLarge),
                    Text(
                      "Welcome Back!",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Sign in to continue to QuickFix",
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.getSecondaryTextColor(context),
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXLarge),
                    
                    // Login Form Card
                    ModernCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: "Email Address",
                              hintText: "Enter your email",
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                color: AppTheme.primaryBlue,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                borderSide: const BorderSide(
                                  color: AppTheme.primaryBlue,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingMedium),
                          TextField(
                            controller: passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: "Password",
                              hintText: "Enter your password",
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                color: AppTheme.primaryBlue,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                borderSide: const BorderSide(
                                  color: AppTheme.primaryBlue,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingLarge),
                          
                          // Login Button
                          _isLoading
                              ? const Center(
                                  child: CircularProgressIndicator(),
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.primaryGradient,
                                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                      ),
                                    ),
                                    child: const Text(
                                      "Sign In",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: AppTheme.spacingLarge),
                    
                    // Divider
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            thickness: 1,
                            color: AppTheme.getSecondaryTextColor(context).withValues(alpha: 0.3),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMedium),
                          child: Text(
                            "or continue with",
                            style: TextStyle(
                              color: AppTheme.getSecondaryTextColor(context),
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            thickness: 1,
                            color: AppTheme.getSecondaryTextColor(context).withValues(alpha: 0.3),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: AppTheme.spacingLarge),
                    
                    // Social Login Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _socialButton(
                          Icons.g_mobiledata,
                          Colors.red,
                          _loginWithGoogle,
                          "Google",
                        ),
                        const SizedBox(width: AppTheme.spacingMedium),
                        _socialButton(
                          Icons.facebook,
                          const Color(0xFF1877F2),
                          _loginWithFacebook,
                          "Facebook",
                        ),
                        const SizedBox(width: AppTheme.spacingMedium),
                        _socialButton(
                          Icons.apple,
                          Colors.black,
                          _loginWithApple,
                          "Apple",
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: AppTheme.spacingXLarge),
                    
                    // Register Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: TextStyle(
                            color: AppTheme.getSecondaryTextColor(context),
                            fontSize: 14,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegisterScreen(),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            "Register",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _socialButton(IconData icon, Color color, Function() onTap, String label) {
    return Tooltip(
      message: 'Sign in with $label',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(
                color: color.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Icon(
              icon,
              size: 28,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
