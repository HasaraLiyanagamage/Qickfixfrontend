import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geocoding/geocoding.dart';
import '../services/api.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
const RegisterScreen({super.key});

@override
State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
final TextEditingController nameController = TextEditingController();
final TextEditingController emailController = TextEditingController();
final TextEditingController passwordController = TextEditingController();
final TextEditingController phoneController = TextEditingController();
final TextEditingController addressController = TextEditingController();
final TextEditingController skillsController = TextEditingController();

bool _isLoading = false;
String _selectedRole = 'user';
double? _lat;
double? _lng;

// --- Backend Email Registration ---
Future<void> _register() async {
final name = nameController.text.trim();
final email = emailController.text.trim();
final password = passwordController.text.trim();
final phone = phoneController.text.trim();
final address = addressController.text.trim();

if (name.isEmpty || email.isEmpty || password.isEmpty) {
  _showSnackBar("Please fill in all fields");
  return;
}

if (address.isEmpty) {
  _showSnackBar("Please enter your address");
  return;
}

setState(() => _isLoading = true);

// Try to geocode address to get coordinates (optional)
if (_lat == null || _lng == null) {
  try {
    // Try geocoding with the original address
    List<Location> locations = [];
    try {
      locations = await locationFromAddress(address);
    } catch (e) {
      // If original address fails, try with "Sri Lanka" appended
      if (!address.toLowerCase().contains('sri lanka')) {
        locations = await locationFromAddress('$address, Sri Lanka');
      }
    }
    
    if (locations.isNotEmpty) {
      _lat = locations.first.latitude;
      _lng = locations.first.longitude;
    } else {
      // If geocoding returns empty, use Sri Lanka center coordinates
      // User can update location later or use manual entry during booking
      _lat = 7.8731;  // Sri Lanka center latitude
      _lng = 80.7718; // Sri Lanka center longitude
    }
  } catch (e) {
    // If geocoding fails completely, use Sri Lanka center coordinates
    // This allows registration to continue even if geocoding service is unavailable
    _lat = 7.8731;  // Sri Lanka center latitude
    _lng = 80.7718; // Sri Lanka center longitude
  }
}

final result = _selectedRole == 'technician'
  ? await Api.registerTechnician(
      name: name,
      email: email,
      password: password,
      phone: phone,
      address: address,
      lat: _lat,
      lng: _lng,
      skills: skillsController.text.trim().isNotEmpty
          ? skillsController.text.split(',').map((s) => s.trim()).toList()
          : [],
    )
  : await Api.register(
  name: name,
  email: email,
  password: password,
  role: _selectedRole,
  phone: phone,
  address: address,
  lat: _lat,
  lng: _lng,
);

setState(() => _isLoading = false);

if (result != null && result['token'] != null) {
  _showSnackBar("Registration successful! Please log in.");
  if (mounted) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }
} else {
  _showSnackBar("Registration failed. Try again.");
}

}

// --- Google Sign-Up ---
Future<void> _registerWithGoogle() async {
  try {
    GoogleAuthProvider googleProvider = GoogleAuthProvider();
    googleProvider.addScope('email');
    googleProvider.addScope('profile');

    UserCredential cred;
    if (kIsWeb) {
      cred = await FirebaseAuth.instance.signInWithPopup(googleProvider);
    } else {
      cred = await FirebaseAuth.instance.signInWithProvider(googleProvider);
    }
    User? user = cred.user;

    if (user != null) {
      await Api.register(
        name: user.displayName ?? "Google User",
        email: user.email ?? "",
        password: "firebase_${user.uid}", // dummy password for backend
        role: 'user',
      );
      _showSnackBar("Google registration successful! Please log in.");
      if (mounted) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
    }
  } catch (e) {
    _showSnackBar("Google sign-up failed: $e");
  }
}

// --- Facebook Sign-Up ---
Future<void> _registerWithFacebook() async {
  try {
    FacebookAuthProvider facebookProvider = FacebookAuthProvider();
    facebookProvider.addScope('email');
    facebookProvider.addScope('public_profile');

    UserCredential cred;
    if (kIsWeb) {
      cred = await FirebaseAuth.instance.signInWithPopup(facebookProvider);
    } else {
      cred = await FirebaseAuth.instance.signInWithProvider(facebookProvider);
    }
    User? user = cred.user;

    if (user != null) {
      await Api.register(
        name: user.displayName ?? "Facebook User",
        email: user.email ?? "",
        password: "firebase_${user.uid}",
        role: 'user',
      );
      _showSnackBar("Facebook registration successful! Please log in.");
      if (mounted) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
    }
  } catch (e) {
    _showSnackBar("Facebook sign-up failed: $e");
  }
}

// --- Apple Sign-Up ---
Future<void> _registerWithApple() async {
  try {
    OAuthProvider appleProvider = OAuthProvider('apple.com');
    appleProvider.addScope('email');
    appleProvider.addScope('name');

    UserCredential cred;
    if (kIsWeb) {
      cred = await FirebaseAuth.instance.signInWithPopup(appleProvider);
    } else {
      cred = await FirebaseAuth.instance.signInWithProvider(appleProvider);
    }
    User? user = cred.user;

    if (user != null) {
      await Api.register(
        name: user.displayName ?? "Apple User",
        email: user.email ?? "",
        password: "firebase_${user.uid}",
        role: 'user',
      );
      _showSnackBar("Apple registration successful! Please log in.");
      if (mounted) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
    }
  } catch (e) {
  _showSnackBar("Apple sign-up failed: $e");
}


}

void _showSnackBar(String msg) {
ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
const Icon(Icons.app_registration,
size: 80, color: Colors.blueAccent),
const SizedBox(height: 20),
const Text(
"Create QuickFix Account",
style: TextStyle(
fontSize: 24,
fontWeight: FontWeight.bold,
color: Colors.blueAccent),
),
const SizedBox(height: 30),

          // Full Name
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: "Full Name",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 15),

          // Email
          TextField(
            controller: emailController,
            decoration: const InputDecoration(
              labelText: "Email",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 15),

          // Password
          TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: "Password",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 15),

          // Phone
          TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: "Phone Number (Optional)",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone),
            ),
          ),
          const SizedBox(height: 15),

          // Address
          TextField(
            controller: addressController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: "Address *",
              hintText: "e.g., 23 Siyane St, Gampaha, Sri Lanka",
              helperText: "Enter street, city, and district",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_on),
            ),
          ),
          const SizedBox(height: 20),

          // Role dropdown
          DropdownButtonFormField<String>(
            initialValue: _selectedRole,
            decoration: const InputDecoration(
              labelText: "Select Role",
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'user', child: Text('User')),
              DropdownMenuItem(value: 'technician', child: Text('Technician')),
              DropdownMenuItem(value: 'admin', child: Text('Admin')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedRole = value!;
              });
            },
          ),
          const SizedBox(height: 15),

          // Skills (Technician only)
          if (_selectedRole == 'technician') ...[
            TextField(
              controller: skillsController,
              decoration: const InputDecoration(
                labelText: "Skills (comma separated)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
          ],

          _isLoading
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 60, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text("Register",
                      style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
          const SizedBox(height: 20),

          // Divider
          Row(children: const [
            Expanded(child: Divider(thickness: 1)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text("or sign up with",
                  style: TextStyle(color: Colors.grey)),
            ),
            Expanded(child: Divider(thickness: 1)),
          ]),
          const SizedBox(height: 15),

          // Social signups
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _socialButton(Icons.account_circle, Colors.blue, _registerWithGoogle),
              const SizedBox(width: 15),
              _socialButton(Icons.facebook, Colors.blue.shade800, _registerWithFacebook),
              const SizedBox(width: 15),
              _socialButton(Icons.apple, Colors.black, _registerWithApple),
            ],
          ),
          const SizedBox(height: 25),

          TextButton(
            onPressed: () {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
            child: const Text("Already have an account? Login"),
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