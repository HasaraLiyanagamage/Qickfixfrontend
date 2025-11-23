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

      if (r.statusCode == 200 || r.statusCode == 201) {
        final data = jsonDecode(r.body);
        token = data['token'];
        await saveToken(token!, data['user']['role']);
        return {'success': true, 'data': data};
      } else {
        // Parse error message from backend
        final errorData = jsonDecode(r.body);
        final errorMessage = errorData['message'] ?? 'Registration failed';
        final errors = errorData['errors'] as List?;
        
        if (kDebugMode) print('Register failed: ${r.statusCode} ${r.body}');
        
        return {
          'success': false,
          'error': errorMessage,
          'errors': errors,
        };
      }
    } catch (e) {
      if (kDebugMode) print('Register error: $e');
      return {
        'success': false,
        'error': 'Network error. Please check your connection.',
      };
    }
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

      if (r.statusCode == 200 || r.statusCode == 201) {
        final data = jsonDecode(r.body);
        token = data['token'];
        await saveToken(token!, data['user']['role']);
        return {'success': true, 'data': data};
      } else {
        // Parse error message from backend
        final errorData = jsonDecode(r.body);
        final errorMessage = errorData['message'] ?? 'Registration failed';
        final errors = errorData['errors'] as List?;
        
        if (kDebugMode) print('Register technician failed: ${r.statusCode} ${r.body}');
        
        return {
          'success': false,
          'error': errorMessage,
          'errors': errors,
        };
      }
    } catch (e) {
      if (kDebugMode) print('Register technician error: $e');
      return {
        'success': false,
        'error': 'Network error. Please check your connection.',
      };
    }
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

  // Get technician feedbacks/ratings
  static Future<List?> getTechnicianFeedbacks() async {
    try {
      final r = await http.get(
        Uri.parse('$base/api/technician/feedbacks'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (kDebugMode) print('Feedbacks API response status: ${r.statusCode}');
      if (kDebugMode) print('Feedbacks API response body: ${r.body}');
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        if (kDebugMode) print('Feedbacks API decoded data: $data');
        return data['feedbacks'] ?? data;
      }
    } catch (e) {
      if (kDebugMode) print('Get technician feedbacks error: $e');
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
      // For emergency, don't filter by skill - get ALL available technicians
      String url;
      if (serviceType.toLowerCase() == 'emergency') {
        url = '$base/api/technician/available?lat=$lat&lng=$lng&radiusKm=$radiusKm';
        if (kDebugMode) print('Emergency service: Fetching ALL available technicians');
      } else {
        url = '$base/api/technician/available?skill=$serviceType&lat=$lat&lng=$lng&radiusKm=$radiusKm';
      }
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

  // ========== NOTIFICATION METHODS ==========
  
  // Get user notifications
  static Future<List?> getUserNotifications() async {
    try {
      final r = await http.get(
        Uri.parse('$base/api/notifications'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        return data['notifications'] ?? [];
      }
    } catch (e) {
      if (kDebugMode) print('Get notifications error: $e');
    }
    return null;
  }

  // Get technician notifications
  static Future<List?> getTechnicianNotifications() async {
    try {
      if (kDebugMode) print('Fetching technician notifications from: $base/api/notifications/technician');
      final r = await http.get(
        Uri.parse('$base/api/notifications/technician'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (kDebugMode) print('Technician notifications response status: ${r.statusCode}');
      if (kDebugMode) print('Technician notifications response body: ${r.body}');
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        if (kDebugMode) print('Technician notifications data: $data');
        return data['notifications'] ?? [];
      }
    } catch (e) {
      if (kDebugMode) print('Get technician notifications error: $e');
    }
    return null;
  }

  // Mark notification as read
  static Future<Map?> markNotificationAsRead(String notificationId) async {
    try {
      final r = await http.patch(
        Uri.parse('$base/api/notifications/$notificationId/read'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (r.statusCode == 200) return jsonDecode(r.body);
    } catch (e) {
      if (kDebugMode) print('Mark notification as read error: $e');
    }
    return null;
  }

  // Mark all notifications as read
  static Future<Map?> markAllNotificationsAsRead() async {
    try {
      final r = await http.patch(
        Uri.parse('$base/api/notifications/read-all'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (r.statusCode == 200) return jsonDecode(r.body);
    } catch (e) {
      if (kDebugMode) print('Mark all notifications as read error: $e');
    }
    return null;
  }

  // Delete notification
  static Future<Map?> deleteNotification(String notificationId) async {
    try {
      final r = await http.delete(
        Uri.parse('$base/api/notifications/$notificationId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (r.statusCode == 200) return jsonDecode(r.body);
    } catch (e) {
      if (kDebugMode) print('Delete notification error: $e');
    }
    return null;
  }

  // Get unread notification count
  static Future<int> getUnreadNotificationCount() async {
    try {
      final r = await http.get(
        Uri.parse('$base/api/notifications/unread/count'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        return data['count'] ?? 0;
      }
    } catch (e) {
      if (kDebugMode) print('Get unread count error: $e');
    }
    return 0;
  }

  // ========== ACCOUNT MANAGEMENT METHODS ==========

  // Change password
  static Future<Map?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final r = await http.patch(
        Uri.parse('$base/api/auth/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );
      if (r.statusCode == 200) return jsonDecode(r.body);
      if (r.statusCode == 400 || r.statusCode == 401) {
        final error = jsonDecode(r.body);
        throw Exception(error['message'] ?? 'Invalid current password');
      }
    } catch (e) {
      if (kDebugMode) print('Change password error: $e');
      rethrow;
    }
    return null;
  }

  // Delete account
  static Future<Map?> deleteAccount(String password) async {
    try {
      final r = await http.delete(
        Uri.parse('$base/api/auth/delete-account'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'password': password,
        }),
      );
      if (r.statusCode == 200) {
        // Clear token after successful deletion
        token = null;
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        return jsonDecode(r.body);
      }
      if (r.statusCode == 400 || r.statusCode == 401) {
        final error = jsonDecode(r.body);
        throw Exception(error['message'] ?? 'Invalid password');
      }
    } catch (e) {
      if (kDebugMode) print('Delete account error: $e');
      rethrow;
    }
    return null;
  }

 

  // Estimate fare before booking
  static Future<Map?> estimateFare({
    required String serviceType,
    required double lat,
    required double lng,
    String urgency = 'normal',
    String? promoCode,
  }) async {
    try {
      final body = {
        'serviceType': serviceType,
        'lat': lat,
        'lng': lng,
        'urgency': urgency,
      };
      if (promoCode != null && promoCode.isNotEmpty) {
        body['promoCode'] = promoCode;
      }

      final r = await http.post(
        Uri.parse('$base/api/booking/estimate-fare'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );
      
      if (kDebugMode) print('Estimate fare response: ${r.statusCode} ${r.body}');
      
      if (r.statusCode == 200) {
        return jsonDecode(r.body);
      } else if (r.statusCode == 400) {
        final error = jsonDecode(r.body);
        throw Exception(error['message'] ?? 'Invalid promo code');
      }
    } catch (e) {
      if (kDebugMode) print('Estimate fare error: $e');
      rethrow;
    }
    return null;
  }

  // Update technician location during booking
  static Future<Map?> updateBookingLocation(String bookingId, double lat, double lng) async {
    try {
      final r = await http.post(
        Uri.parse('$base/api/booking/$bookingId/update-location'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'lat': lat, 'lng': lng}),
      );
      if (r.statusCode == 200) return jsonDecode(r.body);
    } catch (e) {
      if (kDebugMode) print('Update location error: $e');
    }
    return null;
  }

  // Get live tracking data
  static Future<Map?> getBookingTracking(String bookingId) async {
    try {
      final r = await http.get(
        Uri.parse('$base/api/booking/$bookingId/tracking'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (r.statusCode == 200) return jsonDecode(r.body);
    } catch (e) {
      if (kDebugMode) print('Get tracking error: $e');
    }
    return null;
  }

  // ============ WALLET APIs ============

  // Get wallet balance and summary
  static Future<Map?> getWallet() async {
    try {
      final r = await http.get(
        Uri.parse('$base/api/wallet'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (r.statusCode == 200) return jsonDecode(r.body);
    } catch (e) {
      if (kDebugMode) print('Get wallet error: $e');
    }
    return null;
  }

  // Add money to wallet
  static Future<Map?> addMoneyToWallet(double amount, {String paymentMethod = 'card', String? transactionId}) async {
    try {
      final r = await http.post(
        Uri.parse('$base/api/wallet/add-money'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'amount': amount,
          'paymentMethod': paymentMethod,
          'transactionId': transactionId,
        }),
      );
      if (r.statusCode == 200) return jsonDecode(r.body);
    } catch (e) {
      if (kDebugMode) print('Add money error: $e');
    }
    return null;
  }

  // Get wallet transactions
  static Future<List?> getWalletTransactions({int limit = 50, int skip = 0, String? category}) async {
    try {
      var url = '$base/api/wallet/transactions?limit=$limit&skip=$skip';
      if (category != null) url += '&category=$category';
      
      final r = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        return data['transactions'];
      }
    } catch (e) {
      if (kDebugMode) print('Get transactions error: $e');
    }
    return null;
  }

  // Pay for booking with wallet
  static Future<Map?> payWithWallet(String bookingId, double amount) async {
    try {
      final r = await http.post(
        Uri.parse('$base/api/wallet/pay'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'bookingId': bookingId,
          'amount': amount,
        }),
      );
      if (r.statusCode == 200) return jsonDecode(r.body);
      if (r.statusCode == 400) {
        final error = jsonDecode(r.body);
        throw Exception(error['message'] ?? 'Payment failed');
      }
    } catch (e) {
      if (kDebugMode) print('Pay with wallet error: $e');
      rethrow;
    }
    return null;
  }

  // Check sufficient balance
  static Future<Map?> checkBalance(double amount) async {
    try {
      final r = await http.get(
        Uri.parse('$base/api/wallet/check-balance/$amount'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (r.statusCode == 200) return jsonDecode(r.body);
    } catch (e) {
      if (kDebugMode) print('Check balance error: $e');
    }
    return null;
  }

  // ============ PROMO CODE APIs ============

  // Get active promo codes
  static Future<List?> getActivePromoCodes() async {
    try {
      final r = await http.get(
        Uri.parse('$base/api/promo/active'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        return data['promoCodes'];
      }
    } catch (e) {
      if (kDebugMode) print('Get promo codes error: $e');
    }
    return null;
  }

  // Validate promo code
  static Future<Map?> validatePromoCode(String code, String serviceType, double bookingAmount) async {
    try {
      final r = await http.post(
        Uri.parse('$base/api/promo/validate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'code': code,
          'serviceType': serviceType,
          'bookingAmount': bookingAmount,
        }),
      );
      if (r.statusCode == 200) return jsonDecode(r.body);
      if (r.statusCode == 400 || r.statusCode == 404) {
        final error = jsonDecode(r.body);
        throw Exception(error['message'] ?? 'Invalid promo code');
      }
    } catch (e) {
      if (kDebugMode) print('Validate promo error: $e');
      rethrow;
    }
    return null;
  }

  // ============ REFERRAL APIs ============

  // Get my referral code and stats
  static Future<Map?> getReferralCode() async {
    try {
      final r = await http.get(
        Uri.parse('$base/api/referral/code'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (r.statusCode == 200) return jsonDecode(r.body);
    } catch (e) {
      if (kDebugMode) print('Get referral code error: $e');
    }
    return null;
  }

  // Apply referral code
  static Future<Map?> applyReferralCode(String code) async {
    try {
      final r = await http.post(
        Uri.parse('$base/api/referral/apply'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'code': code}),
      );
      if (r.statusCode == 200) return jsonDecode(r.body);
      if (r.statusCode == 400) {
        final error = jsonDecode(r.body);
        throw Exception(error['message'] ?? 'Invalid referral code');
      }
    } catch (e) {
      if (kDebugMode) print('Apply referral error: $e');
      rethrow;
    }
    return null;
  }

  // Get referral rewards
  static Future<List?> getReferralRewards() async {
    try {
      final r = await http.get(
        Uri.parse('$base/api/referral/rewards'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        return data['rewards'];
      }
    } catch (e) {
      if (kDebugMode) print('Get referral rewards error: $e');
    }
    return null;
  }

  // Get referral leaderboard
  static Future<List?> getReferralLeaderboard({int limit = 10}) async {
    try {
      final r = await http.get(
        Uri.parse('$base/api/referral/leaderboard?limit=$limit'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        return data['leaderboard'];
      }
    } catch (e) {
      if (kDebugMode) print('Get leaderboard error: $e');
    }
    return null;
  }

  // ============ EMERGENCY BOOKING APIs ============

  // Create emergency booking
  static Future<Map?> createEmergencyBooking({
    required String serviceType,
    required double lat,
    required double lng,
    required String address,
    String urgency = 'emergency',
    String? description,
  }) async {
    try {
      final r = await http.post(
        Uri.parse('$base/api/booking/emergency'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'serviceType': serviceType,
          'lat': lat,
          'lng': lng,
          'address': address,
          'urgency': urgency,
          'description': description,
        }),
      );
      
      if (kDebugMode) print('Emergency booking response: ${r.statusCode} ${r.body}');
      
      if (r.statusCode == 200) {
        return jsonDecode(r.body);
      } else {
        final error = jsonDecode(r.body);
        throw Exception(error['message'] ?? 'Failed to create emergency booking');
      }
    } catch (e) {
      if (kDebugMode) print('Emergency booking error: $e');
      rethrow;
    }
  }

  // ============ CHATBOT APIs ============

  // Send message to chatbot
  static Future<Map?> sendChatMessage(String message) async {
    try {
      final r = await http.post(
        Uri.parse('$base/api/chatbot/chat'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'message': message}),
      );
      if (r.statusCode == 200) return jsonDecode(r.body);
    } catch (e) {
      if (kDebugMode) print('Chat error: $e');
    }
    return null;
  }

  // Get chatbot health status
  static Future<Map?> getChatbotHealth() async {
    try {
      final r = await http.get(
        Uri.parse('$base/api/chatbot/health'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (r.statusCode == 200) return jsonDecode(r.body);
    } catch (e) {
      if (kDebugMode) print('Chatbot health error: $e');
    }
    return null;
  }

  // Get FAQ
  static Future<Map?> getFAQ() async {
    try {
      final r = await http.get(
        Uri.parse('$base/api/chatbot/faq'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (r.statusCode == 200) return jsonDecode(r.body);
    } catch (e) {
      if (kDebugMode) print('Get FAQ error: $e');
    }
    return null;
  }

  // ============ VERIFICATION APIs ============

  // Submit verification documents (Technician)
  static Future<Map?> submitVerification(Map<String, dynamic> documents) async {
    try {
      final r = await http.post(
        Uri.parse('$base/api/verification/submit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'documents': documents}),
      );
      if (r.statusCode == 200) return jsonDecode(r.body);
      if (r.statusCode == 400 || r.statusCode == 403) {
        final error = jsonDecode(r.body);
        throw Exception(error['message'] ?? 'Failed to submit verification');
      }
    } catch (e) {
      if (kDebugMode) print('Submit verification error: $e');
      rethrow;
    }
    return null;
  }

  // Get verification status (Technician)
  static Future<Map?> getVerificationStatus() async {
    try {
      final r = await http.get(
        Uri.parse('$base/api/verification/status'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (r.statusCode == 200) return jsonDecode(r.body);
    } catch (e) {
      if (kDebugMode) print('Get verification status error: $e');
    }
    return null;
  }

  // Get pending verifications (Admin)
  static Future<Map?> getPendingVerifications() async {
    try {
      final r = await http.get(
        Uri.parse('$base/api/verification/pending'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (r.statusCode == 200) return jsonDecode(r.body);
    } catch (e) {
      if (kDebugMode) print('Get pending verifications error: $e');
    }
    return null;
  }

  // Get verification details (Admin)
  static Future<Map?> getVerificationDetails(String verificationId) async {
    try {
      final r = await http.get(
        Uri.parse('$base/api/verification/$verificationId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (r.statusCode == 200) return jsonDecode(r.body);
    } catch (e) {
      if (kDebugMode) print('Get verification details error: $e');
    }
    return null;
  }

  // Verify document (Admin)
  static Future<Map?> verifyDocument(
    String verificationId,
    String documentType,
    bool verified, {
    int? documentIndex,
    String? notes,
  }) async {
    try {
      final r = await http.post(
        Uri.parse('$base/api/verification/$verificationId/verify-document'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'documentType': documentType,
          'documentIndex': documentIndex,
          'verified': verified,
          'notes': notes,
        }),
      );
      if (r.statusCode == 200) return jsonDecode(r.body);
    } catch (e) {
      if (kDebugMode) print('Verify document error: $e');
    }
    return null;
  }

  // Approve verification (Admin)
  static Future<Map?> approveVerification(String verificationId, {String? notes}) async {
    try {
      final r = await http.post(
        Uri.parse('$base/api/verification/$verificationId/approve'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'notes': notes}),
      );
      if (r.statusCode == 200) return jsonDecode(r.body);
    } catch (e) {
      if (kDebugMode) print('Approve verification error: $e');
    }
    return null;
  }

  // Reject verification (Admin)
  static Future<Map?> rejectVerification(
    String verificationId,
    String reason, {
    String? details,
    bool canResubmit = true,
  }) async {
    try {
      final r = await http.post(
        Uri.parse('$base/api/verification/$verificationId/reject'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'reason': reason,
          'details': details,
          'canResubmit': canResubmit,
        }),
      );
      if (r.statusCode == 200) return jsonDecode(r.body);
    } catch (e) {
      if (kDebugMode) print('Reject verification error: $e');
    }
    return null;
  }

  // Get verification statistics (Admin)
  static Future<Map?> getVerificationStats() async {
    try {
      final r = await http.get(
        Uri.parse('$base/api/verification/admin/stats'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (r.statusCode == 200) return jsonDecode(r.body);
    } catch (e) {
      if (kDebugMode) print('Get verification stats error: $e');
    }
    return null;
  }

  // ============ ANALYTICS APIs ============

  // Get dashboard metrics (Admin)
  static Future<Map?> getDashboardMetrics({String timeRange = 'today'}) async {
    try {
      final url = '$base/api/analytics/dashboard?timeRange=$timeRange';
      if (kDebugMode) print('Fetching dashboard metrics from: $url');
      
      final r = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (kDebugMode) {
        print('Dashboard metrics response status: ${r.statusCode}');
        print('Dashboard metrics response body: ${r.body}');
      }
      
      if (r.statusCode == 200) return jsonDecode(r.body);
      if (kDebugMode) print('Dashboard metrics failed with status: ${r.statusCode}');
    } catch (e) {
      if (kDebugMode) print('Get dashboard metrics error: $e');
    }
    return null;
  }

  // Get revenue analytics (Admin)
  static Future<Map?> getRevenueAnalytics({String timeRange = 'month'}) async {
    try {
      final r = await http.get(
        Uri.parse('$base/api/analytics/revenue?timeRange=$timeRange'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (r.statusCode == 200) return jsonDecode(r.body);
    } catch (e) {
      if (kDebugMode) print('Get revenue analytics error: $e');
    }
    return null;
  }

  // Get performance analytics (Admin)
  static Future<Map?> getPerformanceAnalytics({String timeRange = 'month'}) async {
    try {
      final r = await http.get(
        Uri.parse('$base/api/analytics/performance?timeRange=$timeRange'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (r.statusCode == 200) return jsonDecode(r.body);
    } catch (e) {
      if (kDebugMode) print('Get performance analytics error: $e');
    }
    return null;
  }

  // Get user statistics (Admin)
  static Future<Map?> getUserStatistics({String timeRange = 'month'}) async {
    try {
      final r = await http.get(
        Uri.parse('$base/api/analytics/users?timeRange=$timeRange'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (r.statusCode == 200) return jsonDecode(r.body);
    } catch (e) {
      if (kDebugMode) print('Get user statistics error: $e');
    }
    return null;
  }

  // Get service analytics (Admin)
  static Future<Map?> getServiceAnalytics({String timeRange = 'month'}) async {
    try {
      final r = await http.get(
        Uri.parse('$base/api/analytics/services?timeRange=$timeRange'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (r.statusCode == 200) return jsonDecode(r.body);
    } catch (e) {
      if (kDebugMode) print('Get service analytics error: $e');
    }
    return null;
  }

  // Get service type analytics (Admin) - alias for getServiceAnalytics
  static Future<Map?> getServiceTypeAnalytics({String timeRange = 'month'}) async {
    return getServiceAnalytics(timeRange: timeRange);
  }

  // Get comprehensive analytics report (Admin)
  static Future<Map?> getAnalyticsReport({String timeRange = 'month'}) async {
    try {
      final r = await http.get(
        Uri.parse('$base/api/analytics/report?timeRange=$timeRange'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (r.statusCode == 200) return jsonDecode(r.body);
    } catch (e) {
      if (kDebugMode) print('Get analytics report error: $e');
    }
    return null;
  }

  // Export analytics data (Admin)
  static Future<Map?> exportAnalytics({
    String type = 'revenue',
    String timeRange = 'month',
  }) async {
    try {
      final r = await http.get(
        Uri.parse('$base/api/analytics/export?type=$type&timeRange=$timeRange'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (r.statusCode == 200) return jsonDecode(r.body);
    } catch (e) {
      if (kDebugMode) print('Export analytics error: $e');
    }
    return null;
  }

  // Get all verifications (Admin)
  static Future<List?> getAllVerifications() async {
    try {
      final r = await http.get(
        Uri.parse('$base/api/verification/all'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        return data['verifications'] as List?;
      }
    } catch (e) {
      if (kDebugMode) print('Get all verifications error: $e');
    }
    return null;
  }

  // ========== FAVORITES ==========
  static Future<List?> getFavorites() async {
    try {
      final r = await http.get(
        Uri.parse('$base/api/user/favorites'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        return data['favorites'] as List?;
      }
    } catch (e) {
      if (kDebugMode) print('Get favorites error: $e');
    }
    return null;
  }

  static Future<bool> addFavorite(String technicianId) async {
    try {
      final r = await http.post(
        Uri.parse('$base/api/user/favorites'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'technicianId': technicianId}),
      );
      return r.statusCode == 200;
    } catch (e) {
      if (kDebugMode) print('Add favorite error: $e');
      return false;
    }
  }

  static Future<bool> removeFavorite(String technicianId) async {
    try {
      final r = await http.delete(
        Uri.parse('$base/api/user/favorites/$technicianId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return r.statusCode == 200;
    } catch (e) {
      if (kDebugMode) print('Remove favorite error: $e');
      return false;
    }
  }

  // ========== SERVICE PACKAGES ==========
  static Future<List?> getServicePackages() async {
    try {
      final r = await http.get(
        Uri.parse('$base/api/packages'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        return data['packages'] as List?;
      }
    } catch (e) {
      if (kDebugMode) print('Get packages error: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> bookServicePackage(
    String packageId, {
    Map<String, dynamic>? location,
    String? technicianId,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (location != null) body['location'] = location;
      if (technicianId != null) body['technicianId'] = technicianId;
      
      final r = await http.post(
        Uri.parse('$base/api/packages/$packageId/book'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );
      
      if (r.statusCode == 200) {
        return jsonDecode(r.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('Book package error: $e');
      return null;
    }
  }

  // ========== TECHNICIAN SCHEDULE ==========
  static Future<List?> getTechnicianSchedule() async {
    try {
      final r = await http.get(
        Uri.parse('$base/api/technician/schedule'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        return data['schedule'] as List?;
      }
    } catch (e) {
      if (kDebugMode) print('Get schedule error: $e');
    }
    return null;
  }

  static Future<bool> blockTimeSlot(Map<String, dynamic> slotData) async {
    try {
      final r = await http.post(
        Uri.parse('$base/api/technician/block-time'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(slotData),
      );
      return r.statusCode == 200;
    } catch (e) {
      if (kDebugMode) print('Block time error: $e');
      return false;
    }
  }

  // ========== SERVICE HISTORY ==========
  static Future<List?> getServiceHistory({DateTime? startDate, DateTime? endDate}) async {
    try {
      String url = '$base/api/user/service-history';
      if (startDate != null && endDate != null) {
        url += '?startDate=${startDate.toIso8601String()}&endDate=${endDate.toIso8601String()}';
      }
      final r = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        return data['history'] as List?;
      }
    } catch (e) {
      if (kDebugMode) print('Get service history error: $e');
    }
    return null;
  }

  // ========== CHAT ==========
  static Future<List?> getChatMessages(String chatId) async {
    try {
      final r = await http.get(
        Uri.parse('$base/api/messages/$chatId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        return data['messages'] as List?;
      }
    } catch (e) {
      if (kDebugMode) print('Get messages error: $e');
    }
    return null;
  }

  static Future<Map?> sendDirectMessage({
    required String chatId,
    required String receiverId,
    required String message,
    String? imageUrl,
  }) async {
    try {
      final r = await http.post(
        Uri.parse('$base/api/messages'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'chatId': chatId,
          'receiverId': receiverId,
          'message': message,
          if (imageUrl != null) 'imageUrl': imageUrl,
        }),
      );
      if (r.statusCode == 200) return jsonDecode(r.body);
    } catch (e) {
      if (kDebugMode) print('Send direct message error: $e');
    }
    return null;
  }

  static Future<String?> uploadChatImage(String imagePath) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$base/api/messages/upload-image'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('image', imagePath));
      
      final response = await request.send();
      if (response.statusCode == 200) {
        final data = jsonDecode(await response.stream.bytesToString());
        return data['imageUrl'];
      }
    } catch (e) {
      if (kDebugMode) print('Upload image error: $e');
    }
    return null;
  }

  // ========== PAYMENT ==========
  static Future<Map?> createPaymentIntent({
    required String bookingId,
    required double amount,
  }) async {
    try {
      final r = await http.post(
        Uri.parse('$base/api/payment/create-intent'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'bookingId': bookingId,
          'amount': (amount * 100).toInt(), // Convert to cents
        }),
      );
      if (r.statusCode == 200) return jsonDecode(r.body);
    } catch (e) {
      if (kDebugMode) print('Create payment intent error: $e');
    }
    return null;
  }

  static Future<bool> confirmPayment({
    required String bookingId,
    required String paymentIntentId,
  }) async {
    try {
      final r = await http.post(
        Uri.parse('$base/api/payment/confirm'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'bookingId': bookingId,
          'paymentIntentId': paymentIntentId,
        }),
      );
      return r.statusCode == 200;
    } catch (e) {
      if (kDebugMode) print('Confirm payment error: $e');
      return false;
    }
  }

  static Future<bool> confirmCashPayment({required String bookingId}) async {
    try {
      final r = await http.post(
        Uri.parse('$base/api/payment/cash'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'bookingId': bookingId}),
      );
      return r.statusCode == 200;
    } catch (e) {
      if (kDebugMode) print('Confirm cash payment error: $e');
      return false;
    }
  }

  static Future<bool> confirmCardPayment({required String bookingId}) async {
    try {
      final r = await http.post(
        Uri.parse('$base/api/payment/card'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'bookingId': bookingId}),
      );
      return r.statusCode == 200;
    } catch (e) {
      if (kDebugMode) print('Confirm card payment error: $e');
      return false;
    }
  }

  // Technician confirms payment received
  static Future<bool> confirmPaymentReceived({required String bookingId}) async {
    try {
      final r = await http.post(
        Uri.parse('$base/api/payment/confirm-received'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'bookingId': bookingId}),
      );
      return r.statusCode == 200;
    } catch (e) {
      if (kDebugMode) print('Confirm payment received error: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getPaymentHistory() async {
    try {
      final r = await http.get(
        Uri.parse('$base/api/payment/history'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        return List<Map<String, dynamic>>.from(data['payments'] ?? []);
      }
    } catch (e) {
      if (kDebugMode) print('Get payment history error: $e');
    }
    return [];
  }

  // ========== QUOTATION METHODS ==========
  
  static Future<bool> approveQuotation(String bookingId) async {
    try {
      final r = await http.post(
        Uri.parse('$base/api/booking/$bookingId/approve'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      return r.statusCode == 200;
    } catch (e) {
      if (kDebugMode) print('Approve quotation error: $e');
      rethrow;
    }
  }

  static Future<bool> rejectQuotation(String bookingId, String reason) async {
    try {
      final r = await http.post(
        Uri.parse('$base/api/booking/$bookingId/reject'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'reason': reason}),
      );
      return r.statusCode == 200;
    } catch (e) {
      if (kDebugMode) print('Reject quotation error: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getBookingById(String bookingId) async {
    try {
      final r = await http.get(
        Uri.parse('$base/api/booking/$bookingId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        return data['booking'] as Map<String, dynamic>?;
      }
    } catch (e) {
      if (kDebugMode) print('Get booking by ID error: $e');
    }
    return null;
  }

  static Future<bool> provideQuotation({
    required String bookingId,
    required double laborCost,
    required double materialsCost,
    required List<Map<String, dynamic>> additionalCosts,
    required String notes,
  }) async {
    try {
      final r = await http.post(
        Uri.parse('$base/api/booking/$bookingId/provide'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'laborCost': laborCost,
          'materialsCost': materialsCost,
          'additionalCosts': additionalCosts,
          'notes': notes,
        }),
      );
      return r.statusCode == 200;
    } catch (e) {
      if (kDebugMode) print('Provide quotation error: $e');
      rethrow;
    }
  }

  // ========== TWO-FACTOR AUTHENTICATION ==========
  
  // Enable 2FA
  static Future<Map?> enable2FA() async {
    try {
      final r = await http.post(
        Uri.parse('$base/api/two-factor/enable'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (r.statusCode == 200) {
        return jsonDecode(r.body);
      } else {
        if (kDebugMode) print('Enable 2FA failed: ${r.statusCode} ${r.body}');
        final errorData = jsonDecode(r.body);
        return {'success': false, 'error': errorData['error'] ?? 'Failed to enable 2FA'};
      }
    } catch (e) {
      if (kDebugMode) print('Enable 2FA error: $e');
      return {'success': false, 'error': 'Network error'};
    }
  }

  // Disable 2FA
  static Future<Map?> disable2FA() async {
    try {
      final r = await http.post(
        Uri.parse('$base/api/two-factor/disable'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (r.statusCode == 200) {
        return jsonDecode(r.body);
      } else {
        if (kDebugMode) print('Disable 2FA failed: ${r.statusCode} ${r.body}');
        final errorData = jsonDecode(r.body);
        return {'success': false, 'error': errorData['error'] ?? 'Failed to disable 2FA'};
      }
    } catch (e) {
      if (kDebugMode) print('Disable 2FA error: $e');
      return {'success': false, 'error': 'Network error'};
    }
  }

  // Send 2FA code
  static Future<Map?> send2FACode(String method) async {
    try {
      final r = await http.post(
        Uri.parse('$base/api/two-factor/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'method': method}), // 'sms' or 'email'
      );

      if (r.statusCode == 200) {
        return jsonDecode(r.body);
      } else {
        if (kDebugMode) print('Send 2FA code failed: ${r.statusCode} ${r.body}');
        final errorData = jsonDecode(r.body);
        return {'success': false, 'error': errorData['error'] ?? 'Failed to send code'};
      }
    } catch (e) {
      if (kDebugMode) print('Send 2FA code error: $e');
      return {'success': false, 'error': 'Network error'};
    }
  }

  // Verify 2FA code
  static Future<Map?> verify2FACode(String code) async {
    try {
      final r = await http.post(
        Uri.parse('$base/api/two-factor/verify'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'code': code}),
      );

      if (r.statusCode == 200) {
        return jsonDecode(r.body);
      } else {
        if (kDebugMode) print('Verify 2FA code failed: ${r.statusCode} ${r.body}');
        final errorData = jsonDecode(r.body);
        return {'success': false, 'error': errorData['error'] ?? 'Invalid code'};
      }
    } catch (e) {
      if (kDebugMode) print('Verify 2FA code error: $e');
      return {'success': false, 'error': 'Network error'};
    }
  }

  // Get 2FA status
  static Future<Map?> get2FAStatus() async {
    try {
      final r = await http.get(
        Uri.parse('$base/api/two-factor/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (r.statusCode == 200) {
        return jsonDecode(r.body);
      } else {
        if (kDebugMode) print('Get 2FA status failed: ${r.statusCode} ${r.body}');
        return {'enabled': false};
      }
    } catch (e) {
      if (kDebugMode) print('Get 2FA status error: $e');
      return {'enabled': false};
    }
  }

  // ========== HELPER METHODS ==========
  static String get baseUrl => base;
}
