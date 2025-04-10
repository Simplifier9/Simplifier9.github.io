import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../api/api.dart';
import '../chat/alllistchat.dart';
import '../profile/profile.dart';
import 'pending_orders_screen.dart';
import 'review_screen.dart';

class OrderScreen extends StatefulWidget {
  @override
  _OrderScreenState createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  List<dynamic> acceptedOrders = [];
  List<dynamic> rejectedOrders = [];
  List<dynamic> pendingOrders = [];
  Set<int> expandedOrders = {}; // Tracks expanded cards
  bool isLoading = true;
  int? workerId;
  bool showPendingOrders = false; // Toggle pending orders
  bool showAcceptedOrders = true; // Toggle between accepted and rejected orders
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
    fetchWorkerId();
    startFetchingOrders();
  }


  @override
  void dispose() {
    _timer?.cancel(); // Stop the timer when screen is disposed
    super.dispose();
  }

  void startFetchingOrders() {
    fetchOrders(); // Fetch initially
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      fetchOrders();
    });
  }

  Future<void> fetchWorkerId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? storedUserId = prefs.getInt('user_id');

    if (storedUserId == null) {
      print("🔴 No worker ID found in SharedPreferences");
      setState(() {
        isLoading = false;
      });
      return;
    }

    setState(() {
      workerId = storedUserId;
    });

    fetchOrders();
  }

  Future<void> fetchOrders() async {
    if (workerId == null) return;

    try {
      var response = await http.get(Uri.parse("$baseUrl/api/get_orders/$workerId/"));

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        print("✅ Orders Fetched: $data");

        setState(() {
          acceptedOrders = data.where((order) => order['status'] == 'Accepted').toList();
          rejectedOrders = data.where((order) => order['status'] == 'Rejected').toList();
          pendingOrders = data.where((order) => order['status'] == 'Pending').toList();
          isLoading = false;
        });
      } else {
        print("🔴 Error fetching orders: ${response.body}");
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

  Widget buildOrderCard(Map<String, dynamic> order) {
    bool isExpanded = expandedOrders.contains(order['order_id']);

    return Card(
      elevation: 5,
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Main Card Content
          ListTile(
            contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            leading: Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              color: Colors.blueAccent,
              size: 30,
            ),
            title: Text(
              "Order #${order['order_id']} - ${order['status']}",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 5),
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.grey),
                    SizedBox(width: 5),
                    Text("Seeker: ${order['seeker_name']}", style: TextStyle(fontSize: 14)),
                  ],
                ),
                SizedBox(height: 3),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                    SizedBox(width: 5),
                    Text("Date: ${order['order_date']}", style: TextStyle(fontSize: 14)),
                  ],
                ),
              ],
            ),
            trailing: Icon(Icons.arrow_drop_down_circle, color: Colors.blueAccent),
            onTap: () {
              setState(() {
                if (expandedOrders.contains(order['order_id'])) {
                  expandedOrders.remove(order['order_id']);
                } else {
                  expandedOrders.add(order['order_id']);
                }
              });
            },
          ),

          // Expanded Section with Animation
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            padding: isExpanded ? EdgeInsets.all(12) : EdgeInsets.zero,
            decoration: BoxDecoration(
              gradient: isExpanded
                  ? LinearGradient(colors: [Colors.blue.shade50, Colors.blue.shade100])
                  : null,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: isExpanded
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Divider(color: Colors.blueAccent),
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: Colors.blueAccent),
                    SizedBox(width: 5),
                    Text("Details:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                SizedBox(height: 5),
                Text(order['order_details'], style: TextStyle(fontSize: 15)),
                SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 18, color: Colors.blueAccent),
                    SizedBox(width: 5),
                    Text("Seeker Name: ${order['seeker_name']}", style: TextStyle(fontSize: 15)),
                  ],
                ),
                SizedBox(height: 5),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 18, color: Colors.blueAccent),
                    SizedBox(width: 5),
                    Text("Order Date: ${order['order_date']}", style: TextStyle(fontSize: 15)),
                  ],
                ),
                SizedBox(height: 10),
              ],
            )
                : SizedBox(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> displayOrders = showPendingOrders
        ? pendingOrders
        : showAcceptedOrders
        ? acceptedOrders
        : rejectedOrders;

    return Scaffold(
      body: Column(
        children: [
          // Toggle Button for Accepted & Rejected Orders
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      showAcceptedOrders = true;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: showAcceptedOrders ? Colors.green : Colors.grey,
                  ),
                  child: Text("Accepted"),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      showAcceptedOrders = false;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: !showAcceptedOrders ? Colors.red : Colors.grey,
                  ),
                  child: Text("Rejected"),
                ),
              ],
            ),
          ),

          // Orders List
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : displayOrders.isEmpty
                ? Center(
              child: Text(
                "No orders found!",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            )
                : ListView(
              children: displayOrders.map((order) => buildOrderCard(order)).toList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PendingOrdersScreen()),
          );
        },
        icon: Icon(Icons.pending),
        label: Text("Pending Orders"),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
