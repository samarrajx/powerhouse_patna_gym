import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://powerhousepatnagym.vercel.app/api'; 
  // static const String baseUrl = 'http://10.0.2.2:3000/api'; // Android Emulator
  // static const String baseUrl = 'http://192.168.1.XX:3000/api'; // Physical Device (Replace XX)

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.body.isEmpty) {
      return {'success': false, 'message': 'Empty response from server', 'status_code': response.statusCode};
    }
    
    try {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        return data;
      }
      return {'success': false, 'message': 'Invalid response format', 'data': data};
    } catch (e) {
      return {
        'success': false, 
        'message': 'Server error (${response.statusCode})', 
        'raw_body': response.body,
        'status_code': response.statusCode
      };
    }
  }

  static Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse('$baseUrl$path'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));
      return _handleResponse(response);
    } on TimeoutException {
      return {'success': false, 'message': 'Connection timed out. Check your IP/Network.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body) async {
    try {
      final token = await getToken();
      final response = await http.put(
        Uri.parse('$baseUrl$path'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));
      return _handleResponse(response);
    } on TimeoutException {
      return {'success': false, 'message': 'Connection timed out.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> get(String path) async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl$path'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));
      return _handleResponse(response);
    } on TimeoutException {
      return {'success': false, 'message': 'Connection timed out.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> delete(String path) async {
    try {
      final token = await getToken();
      final response = await http.delete(
        Uri.parse('$baseUrl$path'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));
      return _handleResponse(response);
    } on TimeoutException {
      return {'success': false, 'message': 'Connection timed out.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }
}
