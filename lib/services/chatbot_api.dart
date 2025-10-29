import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ChatbotApi {
  // Using the chatbot URL from environment
  static const baseUrl = "https://quickfix-chatbot.onrender.com/chat";
  static const analyticsUrl = "https://quickfix-chatbot.onrender.com/analytics";

  static Future<String> sendMessage(String message) async {
    try {
      // Get user ID from shared preferences (or use default)
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? 'default_user';

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': message,
          'user_id': userId
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['reply'] ?? "No reply from bot.";
      } else {
        return "Error: ${response.statusCode}";
      }
    } catch (e) {
      return "Error: $e";
    }
  }

  static Future<Map<String, dynamic>> sendMessageWithContext(String message) async {
    try {
      // Get user ID from shared preferences (or use default)
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? 'default_user';

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': message,
          'user_id': userId
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timed out. Please check your internet connection.');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'reply': data['reply'] ?? "No reply from bot.",
          'context': data['context'] ?? 'unknown',
          'timestamp': data['timestamp'] ?? DateTime.now().toIso8601String(),
        };
      } else if (response.statusCode == 404) {
        return {
          'reply': "Sorry, the chatbot service is currently unavailable. Please try again later.",
          'context': 'error',
          'timestamp': DateTime.now().toIso8601String(),
        };
      } else {
        return {
          'reply': "Sorry, I encountered an error (${response.statusCode}). Please try again.",
          'context': 'error',
          'timestamp': DateTime.now().toIso8601String(),
        };
      }
    } catch (e) {
      String errorMessage = "Sorry, I couldn't connect to the server. ";
      if (e.toString().contains('timeout')) {
        errorMessage += "The request timed out. Please check your internet connection.";
      } else if (e.toString().contains('SocketException')) {
        errorMessage += "Please check your internet connection.";
      } else {
        errorMessage += "Please try again later.";
      }
      
      return {
        'reply': errorMessage,
        'context': 'error',
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  static Future<Map<String, dynamic>> getAnalytics() async {
    try {
      final response = await http.get(
        Uri.parse(analyticsUrl),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'error': 'Failed to fetch analytics'};
      }
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
