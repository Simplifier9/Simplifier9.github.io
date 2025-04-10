import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../api/api.dart';
import '../profile/profile.dart';
import '../sale/sale.dart';

class OrderScreen extends StatefulWidget {
  final int seekerId;
  final int workerId;

  OrderScreen({required this.seekerId, required this.workerId});

  @override
  _OrderScreenState createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _detailsController = TextEditingController();
  List<dynamic> _previousOrders = [];
  bool _isLoading = true;
  int _currentIndex = 1;

  @override
  void initState() {
    super.initState();
    _fetchPreviousOrders();
  }

  Future<void> _fetchPreviousOrders() async {
    final url = Uri.parse(
        "$baseUrl/api/orders/list/?seeker_id=${widget.seekerId}&worker_id=${widget.workerId}");

    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _previousOrders = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        print("Failed to fetch orders: ${response.body}");
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching orders: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _submitOrder() async {
    if (_formKey.currentState!.validate()) {
      try {
        final orderData = {
          "seeker_id": widget.seekerId,
          "contractor_labor_id": widget.workerId,
          "order_details": _detailsController.text,
        };

        final response = await http.post(
          Uri.parse("$baseUrl/api/orders/"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(orderData),
        );

        final responseData = jsonDecode(response.body);

        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Order placed successfully!")),
          );
          _detailsController.clear();
          _fetchPreviousOrders();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    "Error: ${responseData['error'] ?? 'Failed to place order'}")),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Network error: ${e.toString()}")),
        );
      }
    }
  }

  void _showConfirmationDialog() {
    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Confirm Order"),
            content: Text("Are you sure you want to place this order?"),
            actions: [
              TextButton(
                child: Text("Cancel"),
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: Text("Confirm"),
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                  _submitOrder(); // Proceed with order
                },
              ),
            ],
          );
        },
      );
    }
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;

    Widget screen;
    switch (index) {
      case 0:
        screen = sale();
        break;
      case 1:
        return;
      case 2:
        screen = Profile();
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        toolbarHeight: 80,
        title: Row(
          children: [
            Expanded(
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
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.location_on, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.send, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Previous Orders:",
                style:
                TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Expanded(
              child: _previousOrders.isNotEmpty
                  ? ListView.builder(
                itemCount: _previousOrders.length,
                itemBuilder: (context, index) {
                  var order = _previousOrders[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 4,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text("Order ID: ${order['order_id']}",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold)),
                          Text("Details: ${order['order_details']}"),
                          Text("Status: ${order['status']}",
                              style:
                              TextStyle(color: Colors.blue)),
                          Text("Date: ${order['order_date']}"),
                        ],
                      ),
                    ),
                  );
                },
              )
                  : Center(
                child: Text("No previous orders found.",
                    style: TextStyle(
                        fontSize: 16, color: Colors.red)),
              ),
            ),
            SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Enter Order Details:",
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: _detailsController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: "Describe the work you need...",
                    ),
                    maxLines: 4,
                    validator: (value) => value!.isEmpty
                        ? "Please enter order details"
                        : null,
                  ),
                  SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      onPressed: _showConfirmationDialog,
                      child: Text("Submit Order"),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_work),
            label: 'Sale/Rent',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work),
            label: 'Labor',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
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
