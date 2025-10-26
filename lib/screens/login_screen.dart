import 'package:flutter/material.dart';
import '../services/api.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool loading = false;

  void login() async {
    setState(() => loading = true);
    final resp = await Api.login(_email.text.trim(), _password.text.trim());
    setState(() => loading = false);
    if (resp != null && resp['token'] != null) {
      // Save token simply in memory for demo
      Api.token = resp['token'];
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      showDialog(context: context, builder: (_) => AlertDialog(title: Text('Error'), content: Text('Login failed')));
    }
  }

  void registerAsUser() async {
    setState(() => loading = true);
    final resp = await Api.register(name: "Demo User", email: _email.text.trim(), password: _password.text.trim(), role: "user");
    setState(() => loading = false);
    if (resp != null && resp['token'] != null) {
      Api.token = resp['token'];
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      showDialog(context: context, builder: (_) => AlertDialog(title: Text('Error'), content: Text('Register failed')));
    }
  }

  @override Widget build(BuildContext ctx) {
    return Scaffold(
      appBar: AppBar(title: Text('QuickFix - Login')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(children: [
          TextField(controller: _email, decoration: InputDecoration(labelText: 'Email')),
          TextField(controller: _password, decoration: InputDecoration(labelText: 'Password'), obscureText: true),
          SizedBox(height: 12),
          loading ? CircularProgressIndicator() : Column(children: [
            ElevatedButton(onPressed: login, child: Text('Login')),
            ElevatedButton(onPressed: registerAsUser, child: Text('Register (demo)')),
          ])
        ]),
      ),
    );
  }
}
