import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:shared_preferences/shared_preferences.dart';

class Api {
  static String base = "https://quickfix-backend-6ztz.onrender.com";
  static String? token;
  static io.Socket? socket;

  
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
        await saveToken(token!, data['user']['role']);
        return data;
      } else {
        if (kDebugMode) print('Login failed: ${r.statusCode} ${r.body}');
      }
    } catch (e) {
      if (kDebugMode) print('Login error: $e');
    }
    return null;
  }

  static Future<Map?> register({
    required String name,
    required String email,
    required String password,
    String role = 'user',
    String? phone,
    String? address,
    double? lat,
    double? lng,
  }) async {
    try {
      final body = <String, dynamic>{
        'name': name,
        'email': email,
        'password': password,
        'role': role,
      };
      
      if (phone != null && phone.isNotEmpty) body['phone'] = phone;
      if (address != null && address.isNotEmpty) body['address'] = address;
      if (lat != null) body['lat'] = lat;
      if (lng != null) body['lng'] = lng;
      
      final r = await http.post(
        Uri.parse('$base/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        token = data['token'];
        await saveToken(token!, data['user']['role']);
        return data;
      } else {
        if (kDebugMode) print('Register failed: ${r.statusCode} ${r.body}');
      }
    } catch (e) {
      if (kDebugMode) print('Register error: $e');
    }
    return null;
  }

  static Future<Map?> registerTechnician({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? address,
    double? lat,
    double? lng,
    List<dynamic>? skills,
  }) async {
    try {
      final body = <String, dynamic>{
        'name': name,
        'email': email,
        'password': password,
        'role': 'technician',
      };
      
      if (phone != null && phone.isNotEmpty) body['phone'] = phone;
      if (address != null && address.isNotEmpty) body['address'] = address;
      if (lat != null) body['lat'] = lat;
      if (lng != null) body['lng'] = lng;
      if (skills != null && skills.isNotEmpty) body['skills'] = skills;
      
      final r = await http.post(
        Uri.parse('$base/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        token = data['token'];
        await saveToken(token!, data['user']['role']);
        return data;
      } else {
        if (kDebugMode) print('Register technician failed: ${r.statusCode} ${r.body}');
      }
    } catch (e) {
      if (kDebugMode) print('Register technician error: $e');
    }
    return null;
  }

  static Future<Map?> socialLogin({
    required String email,
    required String name,
    required String provider,
  }) async {
    try {
      final r = await http.post(
        Uri.parse('$base/api/auth/social-login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'name': name,
          'provider': provider,
        }),
      );

      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        token = data['token'];
        await saveToken(token!, data['user']['role']);
        return data;
      } else {
        if (kDebugMode) print('Social login failed: ${r.statusCode} ${r.body}');
      }
    } catch (e) {
      if (kDebugMode) print('Social login error: $e');
    }
    return null;
  }

  
  static Future<void> saveToken(String token, String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('role', role);
  }

  static Future<Map<String, String>?> getSavedLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final role = prefs.getString('role');
    if (token != null && role != null) {
      Api.token = token;
      return {'token': token, 'role': role};
    }
    return null;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    token = null;
    socket?.disconnect();
    socket = null;
  }

  
  static void initSocket() {
    if (socket != null && socket!.connected) return;
    socket = io.io(
      base,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .build(),
    );
    socket?.onConnect((_) => debugPrint('Socket connected to backend'));
    socket?.onDisconnect((_) => debugPrint('Socket disconnected'));
    socket?.onError((err) => debugPrint('Socket error: $err'));
  }

  
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
      if (r.statusCode == 200) return jsonDecode(r.body);
    } catch (e) {
      if (kDebugMode) print('Booking error: $e');
    }
    return null;
  }

  static Future<List<dynamic>?> getUserBookings() async {
    try {
      final r = await http.get(
        Uri.parse('$base/api/booking/user'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (r.statusCode == 200) return jsonDecode(r.body);
    } catch (e) {
      if (kDebugMode) print('Get bookings error: $e');
    }
    return null;
  }

  static Future<List<dynamic>?> getAllBookings() async {
    try {
      final r = await http.get(
        Uri.parse('$base/api/booking/all'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (r.statusCode == 200) return jsonDecode(r.body);
    } catch (e) {
      if (kDebugMode) print('Get all bookings error: $e');
    }
    return null;
  }

  static Future<Map?> acceptBooking(String bookingId) async {
    try {
      final r = await http.post(
        Uri.parse('$base/api/booking/$bookingId/accept'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (r.statusCode == 200) return jsonDecode(r.body);
    } catch (e) {
      if (kDebugMode) print('Accept booking error: $e');
    }
    return null;
  }

  static Future<Map?> updateBookingStatus(String bookingId, String status) async {
    try {
      final r = await http.patch(
        Uri.parse('$base/api/booking/$bookingId/status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'status': status}),
      );
      if (r.statusCode == 200) return jsonDecode(r.body);
    } catch (e) {
      if (kDebugMode) print('Update status error: $e');
    }
    return null;
  }

  
  static Future<Map?> getTechnicianProfile() async {
    try {
      final r = await http.get(
        Uri.parse('$base/api/technician/profile'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (r.statusCode == 200) return jsonDecode(r.body);
    } catch (e) {
      if (kDebugMode) print('Get tech profile error: $e');
    }
    return null;
  }

  static Future<Map?> updateTechnicianProfile({
    String? skills,
    bool? isAvailable,
    double? lat,
    double? lng,
    String? name,
    String? phone,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (skills != null) body['skills'] = skills;
      if (isAvailable != null) body['isAvailable'] = isAvailable;
      if (lat != null && lng != null) {
        body['lat'] = lat;
        body['lng'] = lng;
      }
      if (name != null) body['name'] = name;
      if (phone != null) body['phone'] = phone;

      final r = await http.put(
        Uri.parse('$base/api/technician/update-profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );
      if (r.statusCode == 200) return jsonDecode(r.body);
    } catch (e) {
      if (kDebugMode) print('Update tech profile error: $e');
    }
    return null;
  }

  // User Profile APIs
  static Future<Map?> getUserProfile() async {
    try {
      final r = await http.get(
        Uri.parse('$base/api/user/profile'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (r.statusCode == 200) return jsonDecode(r.body);
    } catch (e) {
      if (kDebugMode) print('Get user profile error: $e');
    }
    return null;
  }

  static Future<Map?> updateUserProfile({
    String? name,
    String? phone,
    String? address,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (phone != null) body['phone'] = phone;
      if (address != null) body['address'] = address;

      final r = await http.put(
        Uri.parse('$base/api/user/update-profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );
      if (r.statusCode == 200) return jsonDecode(r.body);
    } catch (e) {
      if (kDebugMode) print('Update user profile error: $e');
    }
    return null;
  }

  // Admin Profile APIs
  static Future<Map?> getAdminProfile() async {
    try {
      final r = await http.get(
        Uri.parse('$base/api/admin/profile'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (r.statusCode == 200) return jsonDecode(r.body);
    } catch (e) {
      if (kDebugMode) print('Get admin profile error: $e');
    }
    return null;
  }

  static Future<Map?> updateAdminProfile({
    String? name,
    String? phone,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (phone != null) body['phone'] = phone;

      final r = await http.put(
        Uri.parse('$base/api/admin/update-profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );
      if (r.statusCode == 200) return jsonDecode(r.body);
    } catch (e) {
      if (kDebugMode) print('Update admin profile error: $e');
    }
    return null;
  }

  
  static Future<List<dynamic>?> getAllUsers() async {
    try {
      final r = await http.get(
        Uri.parse('$base/api/admin/users'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (r.statusCode == 200) return jsonDecode(r.body);
    } catch (e) {
      if (kDebugMode) print('Get users error: $e');
    }
    return null;
  }

  static Future<Map?> updateUserStatus(String userId, String status) async {
    try {
      final r = await http.patch(
        Uri.parse('$base/api/admin/users/$userId/status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'status': status}),
      );
      if (r.statusCode == 200) return jsonDecode(r.body);
    } catch (e) {
      if (kDebugMode) print('Update user status error: $e');
    }
    return null;
  }

  static Future<Map?> deleteUser(String userId) async {
    try {
      final r = await http.delete(
        Uri.parse('$base/api/admin/users/$userId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (r.statusCode == 200) return jsonDecode(r.body);
    } catch (e) {
      if (kDebugMode) print('Delete user error: $e');
    }
    return null;
  }

  static Future<Map?> getSystemStats() async {
    try {
      final r = await http.get(
        Uri.parse('$base/api/admin/stats'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (r.statusCode == 200) return jsonDecode(r.body);
    } catch (e) {
      if (kDebugMode) print('Get stats error: $e');
    }
    return null;
  }

  // Get available technicians for a service
  static Future<List<dynamic>?> getAvailableTechnicians({
    required String serviceType,
    required double lat,
    required double lng,
    double radiusKm = 50,
  }) async {
    try {
      final url = '$base/api/technician/available?skill=$serviceType&lat=$lat&lng=$lng&radiusKm=$radiusKm';
      if (kDebugMode) print('Fetching technicians from: $url');
      
      final r = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (kDebugMode) {
        print('Response status: ${r.statusCode}');
        print('Response body: ${r.body}');
      }
      
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        if (kDebugMode) print('Technicians found: ${data.length}');
        return data;
      } else {
        if (kDebugMode) print('Failed to get technicians: ${r.statusCode} - ${r.body}');
      }
    } catch (e) {
      if (kDebugMode) print('Get available technicians error: $e');
    }
    return null;
  }

  // Create booking with specific technician
  static Future<Map?> createBooking({
    required String serviceType,
    required double lat,
    required double lng,
    required String address,
    required String technicianId,
  }) async {
    try {
      final r = await http.post(
        Uri.parse('$base/api/booking/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'serviceType': serviceType,
          'lat': lat,
          'lng': lng,
          'address': address,
          'technicianId': technicianId,
        }),
      );
      if (r.statusCode == 200) return jsonDecode(r.body);
    } catch (e) {
      if (kDebugMode) print('Create booking error: $e');
    }
    return null;
  }

  // Get technician jobs
  static Future<List<dynamic>?> getTechnicianJobs({String? status}) async {
    try {
      String url = '$base/api/booking/technician/jobs';
      if (status != null) {
        url += '?status=$status';
      }
      final r = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (r.statusCode == 200) return jsonDecode(r.body);
    } catch (e) {
      if (kDebugMode) print('Get technician jobs error: $e');
    }
    return null;
  }

  // Rate a booking
  static Future<Map?> rateBooking({
    required String bookingId,
    required int score,
    String? review,
  }) async {
    try {
      final r = await http.post(
        Uri.parse('$base/api/booking/$bookingId/rate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'score': score,
          'review': review,
        }),
      );
      if (r.statusCode == 200) return jsonDecode(r.body);
    } catch (e) {
      if (kDebugMode) print('Rate booking error: $e');
    }
    return null;
  }

  // Get messages for a booking
  static Future<List<dynamic>?> getMessages(String bookingId) async {
    try {
      final r = await http.get(
        Uri.parse('$base/api/message/booking/$bookingId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (r.statusCode == 200) return jsonDecode(r.body);
    } catch (e) {
      if (kDebugMode) print('Get messages error: $e');
    }
    return null;
  }

  // Send a message
  static Future<Map?> sendMessage({
    required String bookingId,
    required String message,
  }) async {
    try {
      final r = await http.post(
        Uri.parse('$base/api/message/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'bookingId': bookingId,
          'message': message,
        }),
      );
      if (r.statusCode == 200) return jsonDecode(r.body);
    } catch (e) {
      if (kDebugMode) print('Send message error: $e');
    }
    return null;
  }

  // Mark messages as read
  static Future<Map?> markMessagesRead(String bookingId) async {
    try {
      final r = await http.patch(
        Uri.parse('$base/api/message/read/$bookingId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (r.statusCode == 200) return jsonDecode(r.body);
    } catch (e) {
      if (kDebugMode) print('Mark messages read error: $e');
    }
    return null;
  }
}
