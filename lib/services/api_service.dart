import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static String baseUrl = "your API URL here";

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  static Future<String?> _refreshToken() async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        "param": "generateToken",
        "username": "arief",
        "password": "ferdian",
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final token = data['access_token'];
      await saveToken(token);
      return token;
    } else {
      return null;
    }
  }

  static Future<Object?> useApi(String token, Object body, String path) async {
    // Ambil token jika kosong
    if (token.isEmpty) {
      token = await getToken() ?? '';
    }

    final response = await http.post(
      Uri.parse('$baseUrl/$path'),
      headers: {'x-access-token': token, 'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data'];
    } else if (response.statusCode == 201) {
      final data = json.decode(response.body);
      return data['insertedId'];
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      final newToken = await _refreshToken();
      print("New token: $newToken");
      if (newToken != null) {
        return await useApi(newToken, body, path);
      } else {
        print("❌ Gagal refresh token.");
        return null;
      }
    } else {
      print("❌ Error: ${response.statusCode} - ${response.body}");
      return null;
    }
  }
}
