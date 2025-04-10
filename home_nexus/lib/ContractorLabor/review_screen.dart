import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../api/api.dart';
import '../chat/alllistchat.dart';
import '../profile/profile.dart';
import 'OrderScreen.dart';

class ReviewScreen extends StatefulWidget {
  @override
  _ReviewScreenState createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  List<dynamic> reviews = [];
  bool isLoading = true;
  Timer? _timer;
  int _currentIndex = 0; // ✅ Default to Reviews page

  static List<Widget> _pages = <Widget>[
    ReviewScreen(), // ✅ Set Reviews as the first page
    OrderScreen(), // Orders Page
    Profile(), // Profile Page
  ];

  @override
  void initState() {
    super.initState();
    fetchReviews();
    startFetchingReviews();
  }

  @override
  void dispose() {
    _timer?.cancel(); // Stop the timer when screen is disposed
    super.dispose();
  }

  void startFetchingReviews() {
    fetchReviews(); // Fetch initially
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      fetchReviews();
    });
  }

  Future<void> fetchReviews() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? userId = prefs.getInt('user_id');

    if (userId == null) {
      print("🔴 No user ID found in SharedPreferences");
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      var response = await http.get(Uri.parse("$baseUrl/api/get_reviews/$userId/"));

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        print("✅ Reviews Fetched: $data");

        setState(() {
          reviews = data;
          isLoading = false;
        });
      } else {
        print("🔴 Error fetching reviews: ${response.body}");
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("🔴 Exception: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget buildReviewCard(Map<String, dynamic> review) {
    int rating = review['rating'] ?? 0; // Get rating, default to 0 if null
    String reviewerName = review['reviewer_name'] ?? "Anonymous";

    return Card(
      elevation: 5, // Elevation for shadow effect
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Rounded corners
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ⭐ Rating Row
            Row(
              children: [
                // Generate stars based on rating
                ...List.generate(
                  rating,
                      (index) => Icon(Icons.star, color: Colors.orange, size: 24),
                ),
                ...List.generate(
                  5 - rating, // Empty stars
                      (index) => Icon(Icons.star_border, color: Colors.grey, size: 24),
                ),
                SizedBox(width: 8), // Spacing
                Text(
                  "$rating/5", // Show rating number
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),

            SizedBox(height: 8), // Spacing

            // 🧑‍💼 Reviewer Name
            Text(
              "Reviewed by: $reviewerName",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey),
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? Center(child: CircularProgressIndicator()) // Show loading spinner
          : reviews.isEmpty
          ? Center(child: Text("No reviews found!")) // No reviews case
          : ListView.builder(
        itemCount: reviews.length,
        itemBuilder: (context, index) {
          return buildReviewCard(reviews[index]);
        },
      ),
    );
  }
}
