import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl =
      'https://secure-notes-backend-u6fz.onrender.com';
  static String? token;

  static Future<void> loadSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('auth_token');
  }

  // Helper method to safely decode JSON responses
  static dynamic _parseResponse(
    http.Response response,
    int expectedStatus,
    String defaultError,
  ) {
    // Check if response is HTML (Render waking up, 404, or server crash)
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
    if (token == null) await loadSavedToken();

    final response = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );
    return _parseResponse(response, 200, 'Failed to load profile');
  }

  // DELETE current user's account
  static Future<void> deleteAccount() async {
    if (token == null) await loadSavedToken();

    final response = await http.delete(
      Uri.parse('$baseUrl/auth/me'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete account');
    }
    token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
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
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = _parseResponse(response, 200, 'Login failed');
    token = data['token'];
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString('auth_token', token!);
    }
    return data;
  }

  // Get all Notes
  static Future<List<dynamic>> getNotes() async {
    if (token == null) await loadSavedToken();

    final response = await http.get(
      Uri.parse('$baseUrl/notes'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );
    return _parseResponse(response, 200, 'Failed to load notes');
  }

  // Create a Note
  static Future<Map<String, dynamic>> createNote(
    String title,
    String content,
  ) async {
    if (token == null) await loadSavedToken();

    final response = await http.post(
      Uri.parse('$baseUrl/notes'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'title': title, 'content': content}),
    );
    return _parseResponse(response, 201, 'Failed to create note');
  }

  // Update a note
  static Future<Map<String, dynamic>> updateNote(
    String id,
    String title,
    String content,
  ) async {
    if (token == null) await loadSavedToken();

    final response = await http.put(
      Uri.parse('$baseUrl/notes/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'title': title, 'content': content}),
    );
    return _parseResponse(response, 200, 'Failed to update note');
  }

  // Toggle a note's pinned status
  static Future<Map<String, dynamic>> togglePin(
    String id,
    bool isPinned,
  ) async {
    if (token == null) await loadSavedToken();

    final response = await http.put(
      Uri.parse('$baseUrl/notes/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'isPinned': isPinned}),
    );
    return _parseResponse(response, 200, 'Failed to update pin status');
  }

  // Delete a note
  static Future<void> deleteNote(String id) async {
    if (token == null) await loadSavedToken();

    final response = await http.delete(
      Uri.parse('$baseUrl/notes/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete note');
    }
  }
}
