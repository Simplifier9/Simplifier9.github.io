import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../api/api.dart';
import '../chat/alllistchat.dart';
import 'OrderScreen.dart';
import '../profile/profile.dart';
import 'review_screen.dart';

class PendingOrdersScreen extends StatefulWidget {
  @override
  _PendingOrdersScreenState createState() => _PendingOrdersScreenState();
}

class _PendingOrdersScreenState extends State<PendingOrdersScreen> {
  List<dynamic> pendingOrders = [];
  Set<int> expandedOrders = {}; // Track expanded orders
  bool isLoading = true;
  int? workerId;
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
    startFetchingPendingOrders();
  }

  @override
  void dispose() {
    _timer?.cancel(); // Stop the timer when screen is disposed
    super.dispose();
  }

  void startFetchingPendingOrders() {
    fetchPendingOrders(); // Fetch initially
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      fetchPendingOrders();
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

    fetchPendingOrders();
  }

  Future<void> fetchPendingOrders() async {
    if (workerId == null) return;

    try {
      var response = await http.get(Uri.parse("$baseUrl/api/get_orders/$workerId/"));

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        print("✅ Pending Orders Fetched: $data");

        setState(() {
          pendingOrders = data.where((order) => order['status'] == 'Pending').toList();
          isLoading = false;
        });
      } else {
        print("🔴 Error fetching pending orders: ${response.body}");
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

  Future<void> updateOrderStatus(int orderId, String status) async {
    try {
      var response = await http.post(
        Uri.parse("$baseUrl/api/update_order_status/"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({"order_id": orderId, "status": status}),
      );

      if (response.statusCode == 200) {
        print("✅ Order Updated: Order #$orderId marked as $status");

        setState(() {
          pendingOrders.removeWhere((order) => order['order_id'] == orderId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Order #$orderId marked as $status"), backgroundColor: Colors.green),
        );
      } else {
        print("🔴 Error updating order: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update order"), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      print("🔴 Exception: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Network error"), backgroundColor: Colors.red),
      );
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
          ListTile(
            contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            leading: Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              color: Colors.orangeAccent,
              size: 30,
            ),
            title: Text(
              "Order #${order['order_id']} - Pending",
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
            trailing: Icon(Icons.arrow_drop_down_circle, color: Colors.orangeAccent),
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

          // Expanded Section with Buttons
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            padding: isExpanded ? EdgeInsets.all(12) : EdgeInsets.zero,
            decoration: BoxDecoration(
              gradient: isExpanded
                  ? LinearGradient(colors: [Colors.orange.shade50, Colors.orange.shade100])
                  : null,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: isExpanded
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Divider(color: Colors.orangeAccent),
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: Colors.orangeAccent),
                    SizedBox(width: 5),
                    Text("Details:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                SizedBox(height: 5),
                Text(order['order_details'], style: TextStyle(fontSize: 15)),
                SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 18, color: Colors.orangeAccent),
                    SizedBox(width: 5),
                    Text("Seeker Name: ${order['seeker_name']}", style: TextStyle(fontSize: 15)),
                  ],
                ),
                SizedBox(height: 5),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 18, color: Colors.orangeAccent),
                    SizedBox(width: 5),
                    Text("Order Date: ${order['order_date']}", style: TextStyle(fontSize: 15)),
                  ],
                ),
                SizedBox(height: 10),

                // Accept & Reject Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () => updateOrderStatus(order['order_id'], 'Accepted'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: Text("Accept"),
                    ),
                    ElevatedButton(
                      onPressed: () => updateOrderStatus(order['order_id'], 'Rejected'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: Text("Reject"),
                    ),
                  ],
                ),
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        toolbarHeight: 80,
        title:Row(
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
              Navigator.push(context, MaterialPageRoute(builder: (context)=>ChatList()));
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : pendingOrders.isEmpty
          ? Center(
        child: Text(
          "No pending orders!",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
      )
          : ListView(
        children: pendingOrders.map((order) => buildOrderCard(order)).toList(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.reviews), label: 'Reviews'), // Changed from Sale/Rent
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Orders'), // Changed from Labor
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => _pages[index]));
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
