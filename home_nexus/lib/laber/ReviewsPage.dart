import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api.dart';

class ReviewsPage extends StatefulWidget {
  final Map<String, dynamic> worker;

  ReviewsPage({required this.worker});

  @override
  _ReviewsPageState createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  List<dynamic> reviews = [];
  bool isLoading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    fetchReviews();
    startFetchingReviews();
  }

  @override
  void dispose() {
    _timer?.cancel(); // Stop auto-fetching when leaving the page
    super.dispose();
  }

  void startFetchingReviews() {
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      fetchReviews();
    });
  }

  Future<void> fetchReviews() async {
    int userId = widget.worker['user_id']; // Get worker ID
    print("🔵 Fetching reviews for Worker ID: $userId");

    try {
      var response = await http.get(Uri.parse("$baseUrl/api/get_reviews/$userId/"));
      print("🔵 Response Status Code: ${response.statusCode}");
      print("🔵 Response Body: ${response.body}");

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

  Future<void> submitReview(int rating) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? loggedUserId = prefs.getInt('user_id'); // Fetch logged-in user ID

    if (loggedUserId == null) {
      print("🔴 User not logged in!");
      return;
    }

    int workerId = widget.worker['user_id'];

    var requestBody = jsonEncode({
      'user': workerId,
      'reviewer': loggedUserId,
      'rating': rating, // 🟢 No comment field
    });

    print("📤 Sending Review: $requestBody");

    try {
      var response = await http.post(
        Uri.parse("$baseUrl/api/add_review/"),
        headers: {"Content-Type": "application/json"},
        body: requestBody,
      );

      print("🔵 Response Status Code: ${response.statusCode}");
      print("🔵 Response Body: ${response.body}");

      if (response.statusCode == 201) {
        print("✅ Review Added!");
        fetchReviews(); // Refresh the reviews list
      } else {
        print("🔴 Failed to add review: ${response.body}");
      }
    } catch (e) {
      print("🔴 Exception: $e");
    }
  }

  void showReviewDialog() {
    int selectedRating = 5;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Add Review"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Select Rating:"),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      5,
                          (index) => IconButton(
                        icon: Icon(
                          index < selectedRating ? Icons.star : Icons.star_border,
                          color: Colors.orange,
                        ),
                        onPressed: () {
                          setState(() { // 🟢 Ensures stars update correctly
                            selectedRating = index + 1;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                  },
                  child: Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    submitReview(selectedRating);
                    Navigator.pop(context); // Close dialog
                  },
                  child: Text("Submit"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget buildReviewCard(Map<String, dynamic> review) {
    int rating = review['rating'] ?? 0;
    String reviewerName = review['reviewer_name'] ?? "Anonymous";

    return Card(
      elevation: 5,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ...List.generate(
                  rating,
                      (index) => Icon(Icons.star, color: Colors.orange, size: 24),
                ),
                ...List.generate(
                  5 - rating,
                      (index) => Icon(Icons.star_border, color: Colors.grey, size: 24),
                ),
                SizedBox(width: 8),
                Text(
                  "$rating/5",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            SizedBox(height: 8),
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
      appBar: AppBar(title: Text("Reviews for ${widget.worker['name']}")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : reviews.isEmpty
          ? Center(child: Text("No reviews available."))
          : ListView.builder(
        itemCount: reviews.length,
        itemBuilder: (context, index) {
          return buildReviewCard(reviews[index]);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showReviewDialog,
        child: Icon(Icons.add),
      ),
    );
  }
}
