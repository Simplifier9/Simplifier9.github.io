import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../api/api.dart';
import '../login/login.dart';


class Signup extends StatefulWidget {
  @override
  _SignupState createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final _formKey = GlobalKey<FormState>();

  final passwordController = TextEditingController();
  final usernameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();

  bool agreeToTerms = false;
  String? selectedUserType;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 45),
              Text(
                "Let's create your account",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              buildTextField("Full Name", Icons.person, usernameController),
              SizedBox(height: 16),
              buildTextField("Phone Number", Icons.phone, phoneController, isPhone: true),
              SizedBox(height: 16),
              buildTextField("Email", Icons.email, emailController, isEmail: true),
              SizedBox(height: 16),
              buildTextField("Password", Icons.lock, passwordController, isPassword: true),
              SizedBox(height: 16),
              Text("Select User Type:", style: TextStyle(fontWeight: FontWeight.bold)),
              Column(
                children: [
                  buildRadioTile("Home Seeker", "Seeker"),
                  buildRadioTile("Home Seller", "Seller"),
                  buildRadioTile("Contractor", "Contractor"),
                  buildRadioTile("Labor", "Labor"),
                ],
              ),
              Row(
                children: [
                  Checkbox(
                    value: agreeToTerms,
                    onChanged: (value) => setState(() => agreeToTerms = value!),
                  ),
                  Text('I agree to '),
                  buildPrivacyLink("Privacy Policy"),
                  Text(' and '),
                  buildPrivacyLink("Terms of Use"),
                ],
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: registerUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  minimumSize: Size(double.infinity, 50),
                  textStyle: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
                child: Text('Create Account', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTextField(String label, IconData icon, TextEditingController controller,
      {bool isPassword = false, bool isPhone = false, bool isEmail = false}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: isPhone ? TextInputType.phone : isEmail ? TextInputType.emailAddress : TextInputType.text,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return "$label is required";
        }
        if (isPhone && (value.length != 10 || !RegExp(r'^\d{10}$').hasMatch(value))) {
          return "Enter a valid 10-digit phone number";
        }
        if (isEmail && !RegExp(r'^[\w-]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return "Enter a valid email address";
        }
        if (isPassword && !RegExp(r'^(?=.*[!@#$%^&*(),.?":{}|<>])').hasMatch(value)) {
          return "Password must contain at least one special character";
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget buildRadioTile(String title, String value) {
    return RadioListTile<String>(
      title: Text(title),
      value: value,
      groupValue: selectedUserType,
      onChanged: (val) => setState(() => selectedUserType = val),
    );
  }

  Widget buildPrivacyLink(String text) {
    return GestureDetector(
      onTap: () {},
      child: Text(text, style: TextStyle(decoration: TextDecoration.underline)),
    );
  }

  void registerUser() async {
    if (!_formKey.currentState!.validate()) return;
    if (!agreeToTerms) {
      showSnackBar("You must agree to the terms to continue.");
      return;
    }
    if (selectedUserType == null) {
      showSnackBar("Please select a user type.");
      return;
    }

    Map<String, String> requestBody = {
      "name": usernameController.text.trim(),
      "email": emailController.text.trim(),
      "phone_no": phoneController.text.trim(),
      "password": passwordController.text,
      "user_type": selectedUserType!,
    };


    try {
      var url = Uri.parse("$baseUrl/api/register/");
      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );
      print("Response Code: ${response.statusCode}");
      print("Response Body: ${response.body}");
      // Decode safely and check response
      if (response.statusCode == 200 || response.statusCode == 201) {
        var responseBody = jsonDecode(response.body);
        String message = responseBody["message"] ?? "Registration successful!";
        showSnackBar(message, success: true);

        // Navigate to Login screen after successful signup
        Future.delayed(Duration(seconds: 2), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => Login()),
          );
        });
      } else {
        var responseBody = jsonDecode(response.body);
        String errorMessage = responseBody["message"] ?? "An error occurred.";
        showSnackBar(errorMessage);
      }
    } catch (e) {
      showSnackBar("Error: Something went wrong. Please try again.");
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
}