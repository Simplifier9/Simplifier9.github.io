import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../ContractorLabor/ContractorLaborPage.dart';
import '../ContractorLabor/VerificationInProgressPage.dart';
import '../ContractorLabor/VerificationRejectedPage.dart';
import '../api/api.dart';
import '../forget/forget.dart';
import '../sale/sale.dart';
import '../sign up/signup.dart';

class Login extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  var emailController = TextEditingController();
  var passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> loginUser(String email, String password) async {
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/login/'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      final responseData = jsonDecode(response.body);
      print("Response Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        final userData = responseData['user'];

        // Store user data
        await prefs.setInt('user_id', userData['user_id']);
        await prefs.setString('user_type', userData['user_type']);
        await prefs.setString('phone', userData['phone_no'] ?? '');
        await prefs.setString('user_id_str', userData['user_id'].toString());
        await prefs.setString('email', userData['email']);
        // Handle verification status
        final verificationStatus = responseData['verification_status'] ?? 'not_required';
        await prefs.setString('verification_status', verificationStatus);

        // Handle navigation
        _handleUserNavigation(
          userData['user_type'],
          verificationStatus,
        );
      } else {
        showSnackBar(responseData["error"] ?? "Login failed");
      }
    } catch (e) {
      print("Exception: $e");
      showSnackBar("Error: Something went wrong.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleUserNavigation(String userType, String verificationStatus) {
    final status = verificationStatus.toLowerCase();

    if (userType == "Contractor" || userType == "Labor") {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => ContractorLaborPage()));
    } else {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => sale()));
    }
  }

  void showSnackBar(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 100),
            Text('Welcome back',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                decoration: InputDecoration(
                    labelText: 'Email Id', border: OutlineInputBorder()),
                controller: emailController,
              ),
            ),
            SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                controller: passwordController,
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextButton(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => ForgetPasswordScreen())),
                  child: Text('  Forget Password?'),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: _isLoading ? null : () => _handleLogin(),
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('Login', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: TextStyle(fontSize: 18),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                minimumSize: Size(340, 0),
              ),
            ),
            SizedBox(height: 15),
            ElevatedButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => Signup())),
              child: Text('Create Account',
                  style: TextStyle(color: Colors.black)),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: TextStyle(fontSize: 18),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                minimumSize: Size(340, 0),
                side: BorderSide(width: 2, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleLogin() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showSnackBar("Please enter your email and password.");
      return;
    }

    await loginUser(email, password);
  }
}