import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

import '../api/api.dart'; // Import for Timer

class Order {
  final int orderId;
  final String orderDetails;
  final String status;
  final DateTime orderDate;
  final String contractorLabor;
  final String seeker;

  Order({
    required this.orderId,
    required this.orderDetails,
    required this.status,
    required this.orderDate,
    required this.contractorLabor,
    required this.seeker,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      orderId: json['order_id'],
      orderDetails: json['order_details'],
      status: json['status'],
      orderDate: DateTime.parse(json['order_date']),
      contractorLabor: json['contractor_labor'],
      seeker: json['seeker'],
    );
  }
}

class Orderscreen extends StatefulWidget {
  final int userId;

  const Orderscreen({Key? key, required this.userId}) : super(key: key);

  @override
  _OrdersScreenState createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<Orderscreen> {
  List<Order> _orders = [];
  bool _isLoading = true;
  String _errorMessage = '';
  Timer? _timer; // Timer variable

  @override
  void initState() {
    super.initState();
    _fetchUserOrders();
    _startAutoRefresh(); // Start the auto-refresh
  }

  void _startAutoRefresh() {
    _timer = Timer.periodic(const Duration(seconds: 20), (timer) {
      _fetchUserOrders();
    });
  }

  Future<void> _fetchUserOrders() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/orders/user/${widget.userId}/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _orders = data.map((order) => Order.fromJson(order)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load orders: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching orders: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel timer when screen is closed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Orders'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(child: Text(_errorMessage))
          : _orders.isEmpty
          ? const Center(child: Text('No orders found'))
          : ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _orders.length,
        itemBuilder: (context, index) {
          final order = _orders[index];
          return OrderCard(order: order);
        },
      ),
    );
  }
}

class OrderCard extends StatelessWidget {
  final Order order;

  const OrderCard({Key? key, required this.order}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      elevation: 3.0,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order ID: ${order.orderId}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Details: ${order.orderDetails}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              'Seeker: ${order.seeker}',
              style: TextStyle(fontSize: 14, color: Colors.blue[700]),
            ),
            Text(
              'Contractor/Labor: ${order.contractorLabor}',
              style: TextStyle(fontSize: 14, color: Colors.orange[700]),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Status: ${order.status}',
                  style: TextStyle(
                    fontSize: 14,
                    color: order.status == 'Pending'
                        ? Colors.orange
                        : order.status == 'Accepted'
                        ? Colors.green
                        : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Ordered on: ${order.orderDate.toLocal().toString().split(' ')[0]}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
