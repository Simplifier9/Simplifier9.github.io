import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api.dart';
import '../profile/profile.dart';
import '../sale/sale.dart';
import '../userOrders/WorkerDetailScreen.dart';
import 'ReviewsPage.dart';

class LaberScreen extends StatefulWidget {
  @override
  _LaberScreenState createState() => _LaberScreenState();
}

class _LaberScreenState extends State<LaberScreen> {
  int _currentIndex = 1;
  List<dynamic> workers = [];

  @override
  void initState() {
    super.initState();
    fetchWorkers();
  }

  Future<void> fetchWorkers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    final response = await http.get(
      Uri.parse('$baseUrl/api/contractors-labors/'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        workers = json.decode(response.body);
      });
    } else {
      print("🔴 Error fetching data: ${response.body}");
    }
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return; // Prevent reloading the same screen

    Widget screen;
    switch (index) {
      case 0:
        screen = sale();
        break;
      case 1:
        return; // Already on the current screen
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
      body: workers.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: workers.length,
        itemBuilder: (context, index) {
          final worker = workers[index];
          final portfolio = worker['portfolios'] as List? ?? [];
          // Safely build full image URL
          final profilePicUrl = worker['profile_pic']?.toString().startsWith('http') == true
              ? worker['profile_pic']
              : '$baseUrl${worker['profile_pic'] ?? ''}';

          return Card(
            margin: EdgeInsets.all(8.0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      profilePicUrl,
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 90,
                          height: 90,
                          color: Colors.grey[300],
                          child: Icon(Icons.person, size: 50, color: Colors.grey[700]),
                        );
                      },
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          worker['name'] ?? 'N/A',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          "🛠️ User Type: ${worker['user_type'] ?? 'N/A'}",
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                        ),
                        Text(
                          "Specialty: ${portfolio.isNotEmpty ? portfolio[0]['speciality'] ?? 'N/A' : 'N/A'}",
                          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          "💰 Price: ₹${portfolio.isNotEmpty ? portfolio[0]['price'] ?? 'N/A' : 'N/A'}",
                          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                        ),
                        SizedBox(height: 8),
                        Wrap(
                          spacing: 10,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => WorkerDetailScreen(worker: worker),
                                  ),
                                );
                              },
                              child: Text("Show"),
                              style: ElevatedButton.styleFrom(minimumSize: Size(80, 36)),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ReviewsPage(worker: worker),
                                  ),
                                );
                              },
                              child: Text("Reviews"),
                              style: ElevatedButton.styleFrom(minimumSize: Size(80, 36)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );


        },
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
