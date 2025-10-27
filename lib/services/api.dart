import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as io;

class Api {
  // ✅ Hosted backend base URL
  static String base = "https://quickfix-backend-6ztz.onrender.com";
  static String? token;
  static io.Socket? socket;

  // --- AUTH: LOGIN ---
  static Future<Map?> login(String email, String pwd) async {
    try {
      final r = await http.post(
        Uri.parse('$base/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': pwd}),
      );

      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        token = data['token'];
        return data;
      } else {
        if (kDebugMode) print('Login failed: ${r.statusCode} ${r.body}');
      }
    } catch (e) {
      if (kDebugMode) print('Login error: $e');
    }
    return null;
  }

  // --- AUTH: REGISTER ---
  static Future<Map?> register({
    required String name,
    required String email,
    required String password,
    String role = 'user',
  }) async {
    try {
      final r = await http.post(
        Uri.parse('$base/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'role': role,
        }),
      );

      if (r.statusCode == 200) {
        return jsonDecode(r.body);
      } else {
        if (kDebugMode) print('Register failed: ${r.statusCode} ${r.body}');
      }
    } catch (e) {
      if (kDebugMode) print('Register error: $e');
    }
    return null;
  }

  // --- AUTH: SOCIAL LOGIN (Firebase: Google, Facebook, Apple) ---
  static Future<Map?> socialLogin(String idToken) async {
    try {
      final r = await http.post(
        Uri.parse('$base/api/auth/social-login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken}),
      );

      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        token = data['token'];
        return data;
      } else {
        if (kDebugMode) print('Social login failed: ${r.statusCode} ${r.body}');
      }
    } catch (e) {
      if (kDebugMode) print('Social login error: $e');
    }
    return null;
  }

  // --- BOOKINGS ---
  static Future<Map?> requestService({
    required String serviceType,
    required double lat,
    required double lng,
    required String address,
  }) async {
    try {
      final r = await http.post(
        Uri.parse('$base/api/booking/request'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'serviceType': serviceType,
          'lat': lat,
          'lng': lng,
          'address': address,
        }),
      );

      if (r.statusCode == 200) {
        return jsonDecode(r.body);
      } else {
        if (kDebugMode) print('Booking failed: ${r.statusCode} ${r.body}');
      }
    } catch (e) {
      if (kDebugMode) print('Booking error: $e');
    }
    return null;
  }

  // --- SOCKET.IO CONNECTION ---
  static void initSocket() {
    if (socket != null && socket!.connected) return;

    socket = io.io(
      base,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .build(),
    );

    socket?.onConnect((_) => debugPrint('✅ Socket connected to backend'));
    socket?.onDisconnect((_) => debugPrint('⚠️ Socket disconnected'));
    socket?.onError((err) => debugPrint('Socket error: $err'));
  }

  // --- GET USER BOOKINGS ---
  static Future<List<dynamic>?> getUserBookings() async {
    try {
      final r = await http.get(
        Uri.parse('$base/api/booking/user'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (r.statusCode == 200) {
        return jsonDecode(r.body);
      } else {
        if (kDebugMode) print('Get bookings failed: ${r.statusCode} ${r.body}');
      }
    } catch (e) {
      if (kDebugMode) print('Get bookings error: $e');
    }
    return null;
  }

  // --- GET ALL BOOKINGS (ADMIN) ---
  static Future<List<dynamic>?> getAllBookings() async {
    try {
      final r = await http.get(
        Uri.parse('$base/api/booking/all'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (r.statusCode == 200) {
        return jsonDecode(r.body);
      } else {
        if (kDebugMode) print('Get all bookings failed: ${r.statusCode} ${r.body}');
      }
    } catch (e) {
      if (kDebugMode) print('Get all bookings error: $e');
    }
    return null;
  }

  // --- ACCEPT BOOKING (TECHNICIAN) ---
  static Future<Map?> acceptBooking(String bookingId) async {
    try {
      final r = await http.post(
        Uri.parse('$base/api/booking/$bookingId/accept'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (r.statusCode == 200) {
        return jsonDecode(r.body);
      } else {
        if (kDebugMode) print('Accept booking failed: ${r.statusCode} ${r.body}');
      }
    } catch (e) {
      if (kDebugMode) print('Accept booking error: $e');
    }
    return null;
  }

  // --- UPDATE BOOKING STATUS ---
  static Future<Map?> updateBookingStatus(String bookingId, String status) async {
    try {
      final r = await http.patch(
        Uri.parse('$base/api/booking/$bookingId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'status': status}),
      );

      if (r.statusCode == 200) {
        return jsonDecode(r.body);
      } else {
        if (kDebugMode) print('Update status failed: ${r.statusCode} ${r.body}');
      }
    } catch (e) {
      if (kDebugMode) print('Update status error: $e');
    }
    return null;
  }

  // --- GET TECHNICIAN PROFILE ---
  static Future<Map?> getTechnicianProfile() async {
    try {
      final r = await http.get(
        Uri.parse('$base/api/technician/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (r.statusCode == 200) {
        return jsonDecode(r.body);
      } else {
        if (kDebugMode) print('Get profile failed: ${r.statusCode} ${r.body}');
      }
    } catch (e) {
      if (kDebugMode) print('Get profile error: $e');
    }
    return null;
  }

  // --- UPDATE TECHNICIAN PROFILE ---
  static Future<Map?> updateTechnicianProfile({
    String? skills,
    bool? isAvailable,
    double? lat,
    double? lng,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (skills != null) body['skills'] = skills;
      if (isAvailable != null) body['isAvailable'] = isAvailable;
      if (lat != null && lng != null) {
        body['lat'] = lat;
        body['lng'] = lng;
      }

      final r = await http.post(
        Uri.parse('$base/api/technician/update-profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (r.statusCode == 200) {
        return jsonDecode(r.body);
      } else {
        if (kDebugMode) print('Update profile failed: ${r.statusCode} ${r.body}');
      }
    } catch (e) {
      if (kDebugMode) print('Update profile error: $e');
    }
    return null;
  }

  // --- GET ALL USERS (ADMIN) ---
  static Future<List<dynamic>?> getAllUsers() async {
    try {
      final r = await http.get(
        Uri.parse('$base/api/admin/users'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (r.statusCode == 200) {
        return jsonDecode(r.body);
      } else {
        if (kDebugMode) print('Get users failed: ${r.statusCode} ${r.body}');
      }
    } catch (e) {
      if (kDebugMode) print('Get users error: $e');
    }
    return null;
  }

  // --- GET AVAILABLE TECHNICIANS ---
  static Future<List<dynamic>?> getAvailableTechnicians({double? lat, double? lng, String? skill}) async {
    try {
      final queryParams = <String, String>{};
      if (lat != null) queryParams['lat'] = lat.toString();
      if (lng != null) queryParams['lng'] = lng.toString();
      if (skill != null) queryParams['skill'] = skill;

      final uri = Uri.parse('$base/api/technician/available').replace(queryParameters: queryParams);
      final r = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (r.statusCode == 200) {
        return jsonDecode(r.body);
      } else {
        if (kDebugMode) print('Get technicians failed: ${r.statusCode} ${r.body}');
      }
    } catch (e) {
      if (kDebugMode) print('Get technicians error: $e');
    }
    return null;
  }

  // --- LOGOUT ---
  static void logout() {
    token = null;
    socket?.disconnect();
    socket = null;
  }

  // --- GET USER PROFILE ---
  static Future<Map?> getUserProfile() async {
    try {
      final r = await http.get(
        Uri.parse('$base/api/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (r.statusCode == 200) {
        return jsonDecode(r.body);
      } else {
        if (kDebugMode) print('Get profile failed: ${r.statusCode} ${r.body}');
      }
    } catch (e) {
      if (kDebugMode) print('Get profile error: $e');
    }
    return null;
  }

  // --- UPDATE USER PROFILE ---
  static Future<Map?> updateUserProfile({String? name, String? phone}) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (phone != null) body['phone'] = phone;

      final r = await http.patch(
        Uri.parse('$base/api/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (r.statusCode == 200) {
        return jsonDecode(r.body);
      } else {
        if (kDebugMode) print('Update profile failed: ${r.statusCode} ${r.body}');
      }
    } catch (e) {
      if (kDebugMode) print('Update profile error: $e');
    }
    return null;
  }

  // --- REGISTER TECHNICIAN ---
  static Future<Map?> registerTechnician({
    required String name,
    required String email,
    required String password,
    required String phone,
    required List<String> skills,
  }) async {
    try {
      final r = await http.post(
        Uri.parse('$base/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'phone': phone,
          'role': 'technician',
          'skills': skills,
        }),
      );

      if (r.statusCode == 200) {
        return jsonDecode(r.body);
      } else {
        if (kDebugMode) print('Register technician failed: ${r.statusCode} ${r.body}');
      }
    } catch (e) {
      if (kDebugMode) print('Register technician error: $e');
    }
    return null;
  }

  // --- GET BOOKING BY ID ---
  static Future<Map?> getBooking(String bookingId) async {
    try {
      final r = await http.get(
        Uri.parse('$base/api/booking/$bookingId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (r.statusCode == 200) {
        return jsonDecode(r.body);
      } else {
        if (kDebugMode) print('Get booking failed: ${r.statusCode} ${r.body}');
      }
    } catch (e) {
      if (kDebugMode) print('Get booking error: $e');
    }
    return null;
  }

  // --- UPDATE TECHNICIAN LOCATION ---
  static Future<Map?> updateTechnicianLocation(double lat, double lng, {bool? isAvailable}) async {
    try {
      final body = <String, dynamic>{
        'lat': lat,
        'lng': lng,
      };
      if (isAvailable != null) body['isAvailable'] = isAvailable;

      final r = await http.post(
        Uri.parse('$base/api/technician/update-location'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (r.statusCode == 200) {
        return jsonDecode(r.body);
      } else {
        if (kDebugMode) print('Update location failed: ${r.statusCode} ${r.body}');
      }
    } catch (e) {
      if (kDebugMode) print('Update location error: $e');
    }
    return null;
  }

  // --- ADMIN: UPDATE USER STATUS ---
  static Future<Map?> updateUserStatus(String userId, String status) async {
    try {
      final r = await http.patch(
        Uri.parse('$base/api/admin/users/$userId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'status': status}),
      );

      if (r.statusCode == 200) {
        return jsonDecode(r.body);
      } else {
        if (kDebugMode) print('Update user status failed: ${r.statusCode} ${r.body}');
      }
    } catch (e) {
      if (kDebugMode) print('Update user status error: $e');
    }
    return null;
  }

  // --- ADMIN: GET SYSTEM STATS ---
  static Future<Map?> getSystemStats() async {
    try {
      final r = await http.get(
        Uri.parse('$base/api/admin/stats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (r.statusCode == 200) {
        return jsonDecode(r.body);
      } else {
        if (kDebugMode) print('Get stats failed: ${r.statusCode} ${r.body}');
      }
    } catch (e) {
      if (kDebugMode) print('Get stats error: $e');
    }
    return null;
  }
}
