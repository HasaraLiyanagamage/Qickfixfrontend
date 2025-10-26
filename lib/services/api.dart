import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as io;

class Api {
  static String base = "http://10.0.2.2:5000"; // Android emulator -> host machine
  static String? token;
  static io.Socket? socket;

  static Future<Map?> login(String email, String pwd) async {
    final r = await http.post(Uri.parse('$base/api/auth/login'),
      headers: {'Content-Type':'application/json'},
      body: jsonEncode({'email': email, 'password': pwd})
    );
    if (r.statusCode==200) return jsonDecode(r.body);
    return null;
  }

  static Future<Map?> register({required String name, required String email, required String password, String role='user'}) async {
    final r = await http.post(Uri.parse('$base/api/auth/register'),
        headers: {'Content-Type':'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'password': password, 'role': role})
    );
    if (r.statusCode==200) return jsonDecode(r.body);
    return null;
  }

  static Future<Map?> requestService({required String serviceType, required double lat, required double lng, required String address}) async {
    final r = await http.post(Uri.parse('$base/api/booking/request'),
        headers: {'Content-Type':'application/json', 'Authorization': 'Bearer ${Api.token}'},
        body: jsonEncode({'serviceType': serviceType, 'lat': lat, 'lng': lng, 'address': address})
    );
    if (r.statusCode==200) return jsonDecode(r.body);
    return null;
  }

  static void initSocket() {
    if (socket != null) return;
    socket = io.io(base, io.OptionBuilder().setTransports(['websocket']).build());
    socket?.onConnect((_) => debugPrint('socket connected'));
  }

  static void emitTechLocation(String techId, double lat, double lng) {
    initSocket();
    socket?.emit('tech:location', {'techId': techId, 'lat': lat, 'lng': lng});
  }
}
