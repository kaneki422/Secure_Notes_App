import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl =
      'https://secure-notes-backend-u6fz.onrender.com/api';
  static String? token;

  // Helper method to check if the device has an active internet connection
  static Future<void> _checkInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isEmpty || result[0].rawAddress.isEmpty) {
        throw Exception('You are offline.');
      }
    } on SocketException catch (_) {
      throw Exception('You are offline.');
    }
  }

  static Future<void> loadSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('auth_token');
  }

  // Helper method to safely decode JSON responses and check status codes
  static dynamic _parseResponse(
    http.Response response,
    int expectedStatus,
    String defaultError,
  ) {
    // Check if the server returned HTML (e.g., Render cold start, 404, or crash)
    final contentType = response.headers['content-type'] ?? '';
    final isJson = contentType.contains('application/json');

    if (!isJson) {
      throw Exception(
        'Server returned HTML or invalid response (Status ${response.statusCode}). Please try again shortly.',
      );
    }

    final data = jsonDecode(response.body);

    if (response.statusCode != expectedStatus) {
      throw Exception(data['message'] ?? defaultError);
    }

    return data;
  }

  // GET current user's profile
  static Future<Map<String, dynamic>> getProfile() async {
    await _checkInternet();
    if (token == null) await loadSavedToken();

    final response = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    // Handle invalid or expired session tokens
    if (response.statusCode == 401 || response.statusCode == 403) {
      await logout();
      throw Exception('Session expired. Please log in again.');
    }

    return _parseResponse(response, 200, 'Failed to load profile');
  }

  // DELETE current user's account
  static Future<void> deleteAccount() async {
    await _checkInternet();
    if (token == null) await loadSavedToken();

    final response = await http.delete(
      Uri.parse('$baseUrl/auth/me'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (response.statusCode == 401 || response.statusCode == 403) {
      await logout();
      throw Exception('Session expired. Please log in again.');
    }

    _parseResponse(response, 200, 'Failed to delete account');
    await logout();
  }

  static Future<void> logout() async {
    token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // Signup
  static Future<Map<String, dynamic>> signup(
    String email,
    String password,
  ) async {
    await _checkInternet();

    final response = await http.post(
      Uri.parse('$baseUrl/auth/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    return _parseResponse(response, 201, 'Signup failed');
  }

  // Login
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    await _checkInternet();

    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = _parseResponse(response, 200, 'Login failed');
    token = data['token'];

    if (token != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token!);
    }
    return data;
  }

  // Get all Notes
  static Future<List<dynamic>> getNotes() async {
    await _checkInternet();
    if (token == null) await loadSavedToken();

    final response = await http.get(
      Uri.parse('$baseUrl/notes'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (response.statusCode == 401 || response.statusCode == 403) {
      await logout();
      throw Exception('Session expired. Please log in again.');
    }

    return _parseResponse(response, 200, 'Failed to load notes');
  }

  // Create a Note
  static Future<Map<String, dynamic>> createNote(
    String title,
    String content,
  ) async {
    await _checkInternet();
    if (token == null) await loadSavedToken();

    final response = await http.post(
      Uri.parse('$baseUrl/notes'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'title': title, 'content': content}),
    );

    if (response.statusCode == 401 || response.statusCode == 403) {
      await logout();
      throw Exception('Session expired. Please log in again.');
    }

    return _parseResponse(response, 201, 'Failed to create note');
  }

  // Update a note
  static Future<Map<String, dynamic>> updateNote(
    String id,
    String title,
    String content,
  ) async {
    await _checkInternet();
    if (token == null) await loadSavedToken();

    final response = await http.put(
      Uri.parse('$baseUrl/notes/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'title': title, 'content': content}),
    );

    if (response.statusCode == 401 || response.statusCode == 403) {
      await logout();
      throw Exception('Session expired. Please log in again.');
    }

    return _parseResponse(response, 200, 'Failed to update note');
  }

  // Toggle a note's pinned status
  static Future<Map<String, dynamic>> togglePin(
    String id,
    bool isPinned,
  ) async {
    await _checkInternet();
    if (token == null) await loadSavedToken();

    final response = await http.put(
      Uri.parse('$baseUrl/notes/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'isPinned': isPinned}),
    );

    if (response.statusCode == 401 || response.statusCode == 403) {
      await logout();
      throw Exception('Session expired. Please log in again.');
    }

    return _parseResponse(response, 200, 'Failed to update pin status');
  }

  // Delete a note
  static Future<void> deleteNote(String id) async {
    await _checkInternet();
    if (token == null) await loadSavedToken();

    final response = await http.delete(
      Uri.parse('$baseUrl/notes/$id'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (response.statusCode == 401 || response.statusCode == 403) {
      await logout();
      throw Exception('Session expired. Please log in again.');
    }

    _parseResponse(response, 200, 'Failed to delete note');
  }
}
