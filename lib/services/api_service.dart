import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:5000/api';
  // static const String baseUrl = 'http://192.168.1.8:5000/api';
  // static const String baseUrl = 'http://192.168.1.11:5000/api';
  static String? token;

  static Future<void> loadSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('auth_token');
  }

  // GET current user's profile
  static Future<Map<String, dynamic>> getProfile() async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final data = jsonDecode(response.body);
    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to load profile');
    }
    return data;
  }

  // DELETE current user's account
  static Future<void> deleteAccount() async {
    final response = await http.delete(
      Uri.parse('$baseUrl/auth/me'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to delete account');
    }
    token = null; // clear the stored session token
  }

  static Future<void> logout() async {
    token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  //Signup
  static Future<Map<String, dynamic>> signup(
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode != 201) {
      throw Exception(data['message'] ?? 'Signup failed');
    }
    return data;
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
    final data = jsonDecode(response.body);
    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Login failed');
    }
    token = data['token'];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'auth_token',
      token!,
    ); //here it will save the token for future requests.
    return data;
  }

  //Get all Notes
  static Future<List<dynamic>> getNotes() async {
    final response = await http.get(
      Uri.parse('$baseUrl/notes'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load Notes');
    }
    return jsonDecode(response.body);
  }

  //Create a Note
  static Future<Map<String, dynamic>> createNote(
    String title,
    String content,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/notes'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'title': title, 'content': content}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode != 201) {
      throw Exception(data['message'] ?? 'Failed to create notes');
    }
    return data;
  }

  //Update a note
  static Future<Map<String, dynamic>> updateNote(
    String id,
    String title,
    String content,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/notes/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'title': title, 'content': content}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to update note');
    }
    return data;
  }

  // Toggle a note's pinned status
  static Future<Map<String, dynamic>> togglePin(
    String id,
    bool isPinned,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/notes/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'isPinned': isPinned}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to update pin status');
    }
    return data;
  }

  //Delete a note
  static Future<void> deleteNote(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/notes/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete note');
    }
  }
}
