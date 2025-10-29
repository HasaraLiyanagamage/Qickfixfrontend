import 'package:flutter/material.dart';
import 'request_service_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override Widget build(BuildContext ctx) {
    return Scaffold(
      appBar: AppBar(title: Text('QuickFix')),
      body: Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(onPressed: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => RequestServiceScreen())), child: Text('Request Service')),
        ],
      )),
    );
  }
}


