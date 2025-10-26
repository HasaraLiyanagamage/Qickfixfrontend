import 'package:flutter/material.dart';
import '../services/api.dart';

class RequestServiceScreen extends StatefulWidget {
  const RequestServiceScreen({super.key});

  @override State<RequestServiceScreen> createState() => _RequestServiceScreenState();
}

class _RequestServiceScreenState extends State<RequestServiceScreen> {
  final _address = TextEditingController();
  String _serviceType = 'plumbing';
  bool loading = false;

  void sendRequest() async {
    setState(() => loading = true);
    // demo lat/lng
    final resp = await Api.requestService(serviceType: _serviceType, lat: 6.9271, lng: 79.8612, address: _address.text);
    setState(() => loading = false);
    if (resp != null) {
      final booking = resp['booking'];
      showDialog(context: context, builder: (_) => AlertDialog(title: Text('Requested'), content: Text('Booking id: ${booking['_id'] ?? booking['id'] ?? ''}')));
    } else {
      showDialog(context: context, builder: (_) => AlertDialog(title: Text('Error'), content: Text('Request failed')));
    }
  }

  @override Widget build(BuildContext ctx) {
    return Scaffold(
      appBar: AppBar(title: Text('Request Service')),
      body: Padding(
        padding: EdgeInsets.all(16), child: Column(children: [
          TextField(controller: _address, decoration: InputDecoration(labelText: 'Address/Notes')),
          DropdownButton<String>(
            value: _serviceType,
            items: ['plumbing','electrical','handyman'].map((s) => DropdownMenuItem(value: s,child: Text(s))).toList(),
            onChanged: (v)=> setState(()=> _serviceType=v!)
          ),
          SizedBox(height:12),
          loading ? CircularProgressIndicator() : ElevatedButton(onPressed: sendRequest, child: Text('Request Now'))
        ]),
      ),
    );
  }
}
