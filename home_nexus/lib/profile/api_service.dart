import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../api/api.dart';

class User {
  final int userId;
  final String name;
  final String email;
  final String phoneNo;
  final String userType;
  final String? profilePic;

  User({
    required this.userId,
    required this.name,
    required this.email,
    required this.phoneNo,
    required this.userType,
    this.profilePic,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id'],
      name: json['name'],
      email: json['email'],
      phoneNo: json['phone_no'],
      userType: json['user_type'],
      profilePic: json['profile_pic'],
    );
  }
}

class ApiService {

  static Future<User> getUserProfile(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/user/profile/$userId/'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      if (jsonData['profile_pic'] != null && !jsonData['profile_pic'].startsWith('http')) {
        jsonData['profile_pic'] = '$baseUrl${jsonData['profile_pic']}';
      }
      return User.fromJson(jsonData);
    } else {
      throw Exception('Failed to load profile: ${response.statusCode}');
    }
  }

  static Future<User> updateUserProfile(int userId, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/api/user/profile/$userId/update/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return User.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to update profile: ${response.body}');
      }
    } on TimeoutException {
      throw Exception('Request timed out');
    } on http.ClientException {
      throw Exception('Connection failed');
    }
  }
}