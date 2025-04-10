import 'dart:async'; // ✅ Import for periodic check
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../api/api.dart';
import '../chat/alllistchat.dart';
import 'OrderScreen.dart';
import 'VerificationInProgressPage.dart';
import 'VerificationRejectedPage.dart';
import 'review_screen.dart';
import 'verification_form.dart';
import '../profile/profile.dart';
import '../sidebar/NavBar.dart';

class ContractorLaborPage extends StatefulWidget {
  @override
  _ContractorLaborPageState createState() => _ContractorLaborPageState();
}

class _ContractorLaborPageState extends State<ContractorLaborPage> {
  bool isLoading = true;
  bool isVerified = false;
  int _currentIndex = 0; // ✅ Default to Reviews page
  Timer? _timer; // ✅ Timer for periodic verification check

  static List<Widget> _pages = <Widget>[
    ReviewScreen(),
    OrderScreen(),
    Profile(),
  ];

  @override
  void initState() {
    super.initState();
    checkVerification();

    // ✅ Set up a periodic verification check (every 60 seconds)
    _timer = Timer.periodic(Duration(seconds: 60), (timer) {
      checkVerification();
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // ✅ Stop the timer when widget is removed
    super.dispose();
  }

  Future<void> checkVerification() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? userId = prefs.getInt('user_id');

    if (userId == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      var response = await http.get(
        Uri.parse("$baseUrl/api/check_verification/$userId/"),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        String status = data['status'];
        String? currentPhoto = data['current_photo']; // ✅ Fetch current photo

        bool hasCurrentPhoto = currentPhoto != null && currentPhoto.isNotEmpty; // ✅ Check if current photo exists

        if (status == 'pending' && hasCurrentPhoto) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => VerificationInProgressPage()));
        } else if (status == 'pending' && !hasCurrentPhoto) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => VerificationFormPage()));
        } else if (status == 'rejected') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => VerificationRejectedPage()));
        } else {
          print("✅ Verified user");
        }
      } else {
        print("🔴 Error fetching verification status: ${response.body}");
      }
    } catch (e) {
      print("🔴 Exception: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }


  void showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        toolbarHeight: 80,
        title: Row(
          children: [
            Expanded(
              child: Container(
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Search',
                    suffixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.location_on, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.send, color: Colors.black),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => ChatList()));
            },
          ),
        ],
      ),
      body: _pages[_currentIndex], // ✅ Show page without reloading Scaffold
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.reviews), label: 'Reviews'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index; // ✅ Switch page dynamically
          });
        },
        backgroundColor: Colors.blue,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.black,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontSize: 18),
        unselectedLabelStyle: TextStyle(fontSize: 16),
      ),
    );
  }
}
