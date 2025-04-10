import 'dart:async'; // Import Timer
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../api/api.dart';
import 'ContractorLaborPage.dart';
import 'VerificationRejectedPage.dart';

class VerificationInProgressPage extends StatefulWidget {
  @override
  _VerificationInProgressPageState createState() => _VerificationInProgressPageState();
}

class _VerificationInProgressPageState extends State<VerificationInProgressPage> {
  bool isChecking = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    checkVerificationStatus();
    _startAutoCheck();
  }

  void _startAutoCheck() {
    _timer = Timer.periodic(Duration(seconds: 10), (timer) {
      checkVerificationStatus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Stop the timer when leaving the page
    super.dispose();
  }

  Future<void> checkVerificationStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? userId = prefs.getInt('user_id');

    if (userId == null) return;

    try {
      var response = await http.get(
        Uri.parse("$baseUrl/api/check_verification/$userId/"),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        String status = data['status'];

        if (status == 'accepted') {
          print("✅ Verification Approved! Redirecting...");
          _timer?.cancel(); // Stop checking
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ContractorLaborPage()),
          );
        } else if (status == 'rejected') {
          print("❌ Verification Rejected! Redirecting...");
          _timer?.cancel(); // Stop checking
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => VerificationRejectedPage()),
          );
        }
      } else {
        print("❌ Error fetching verification status: ${response.body}");
      }
    } catch (e) {
      print("❌ Exception: $e");
    } finally {
      setState(() {
        isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Verification In Progress")),
      body: Center(
        child: isChecking
            ? CircularProgressIndicator()
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.access_time, size: 100, color: Colors.orange),
            SizedBox(height: 20),
            Text(
              "Your verification is in progress.\nPlease wait until it gets accepted.",
              textAlign: TextAlign.center,
            ),
            Text(
              "Verification takes 2-3 days.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: checkVerificationStatus,
              child: Text("Refresh Status"),
            ),
          ],
        ),
      ),
    );
  }
}
