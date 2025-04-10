import 'package:flutter/material.dart';
import '../profile/profile.dart';
import '../sale/sale.dart';
import 'order_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';



class WorkerDetailScreen extends StatefulWidget {
  final Map<String, dynamic> worker;

  WorkerDetailScreen({required this.worker});

  @override
  _WorkerDetailScreenState createState() => _WorkerDetailScreenState();
}

class _WorkerDetailScreenState extends State<WorkerDetailScreen> {
  bool _isPortfolioVisible = false;
  int? seekerId;
  int _currentIndex = 1;

  @override
  void initState() {
    super.initState();
    _fetchSeekerId();
  }

  Future<void> _fetchSeekerId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      seekerId = prefs.getInt('user_id'); // Fetching stored user_id as seekerId
    });
    debugPrint("Fetched Seeker ID: $seekerId"); // Debug log
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
    final portfolio = widget.worker['portfolios'] as List? ?? [];

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Worker Image
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  widget.worker['profile_image'] ?? 'https://via.placeholder.com/200',
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(height: 16),

            // Worker Details
            Text(
              widget.worker['name'] ?? 'N/A',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text("📧 Email: ${widget.worker['email'] ?? 'N/A'}", style: TextStyle(fontSize: 16)),
            Text("📞 Phone: ${widget.worker['phone_no'] ?? 'N/A'}", style: TextStyle(fontSize: 16)),

            // Toggle Portfolio Button
            Center(
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isPortfolioVisible = !_isPortfolioVisible;
                  });
                },
                child: Text(_isPortfolioVisible ? "Hide Portfolio" : "See Portfolio"),
              ),
            ),

            // Portfolio Section
            if (_isPortfolioVisible)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: portfolio.map<Widget>((portfolioItem) {
                  // Safely handle previous_work conversion
                  List<String> previousWorkList = [];
                  if (portfolioItem['previous_work'] is List) {
                    previousWorkList = List<String>.from(
                        (portfolioItem['previous_work'] as List).map((item) => item.toString())
                    );
                  } else if (portfolioItem['previous_work'] is String) {
                    previousWorkList = [portfolioItem['previous_work']];
                  }

                  String previousWorkText = previousWorkList.join('\n• ');
                  String cost = portfolioItem['price'] != null ? "\$${portfolioItem['price']}" : 'N/A';

                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    child: Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Specialty: ${portfolioItem['speciality'] ?? 'N/A'}"),
                          SizedBox(height: 4),
                          Text("Experience: ${portfolioItem['experience_years'] ?? '0'} years"),
                          Text("Price: $cost", style: TextStyle(color: Colors.green)),
                          SizedBox(height: 8),
                          Text("Previous Work:", style: TextStyle(fontWeight: FontWeight.bold)),
                          ...previousWorkList.map((work) =>
                              Text('• $work', style: TextStyle(fontSize: 14))
                          ).toList(),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

            // Place Order Button
            Center(
              child: ElevatedButton(
                onPressed: (seekerId != null)
                    ? () {
                  debugPrint("Navigating with Seeker ID: $seekerId");
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OrderScreen(
                        workerId: widget.worker['user_id'],
                        seekerId: seekerId!,
                      ),
                    ),
                  );
                }
                    : null, // Disable if seekerId is null
                child: Text("Place Order"),
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
