import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
 // Import for web-specific features
import 'package:bdemo/chat/alllistchat.dart';
import 'package:bdemo/showItem/show.dart';
import 'package:bdemo/showItem/showreview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../addproduct/home.dart';
import '../api/api.dart';
import '../laber/laber.dart';
import '../profile/profile.dart';
import '../profile/profileview.dart';
import '../sidebar/NavBar.dart';

class sale extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _saleState();
}

class _saleState extends State<sale> {
  late Future<List<House>> houses;
  int _myIndex = 0;
  Icon a = Icon(Icons.favorite_border);
  String _filterType = 'All'; // Default filter: All
  String _searchQuery = ''; // For location search
  bool _isSeller = false;
  int? _currentUserId;

  static List<Widget> _children = <Widget>[
    sale(),
    LaberScreen(),
    Profile(),
  ];

  @override
  void initState() {
    super.initState();
    houses = fetchHouses();
    _checkUserType(); // Add this line
  }

  Future<List<House>> fetchHouses() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/houses/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((data) => House.fromJson(data)).toList();
      } else {
        throw Exception('Failed to load houses. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching houses: $e');
      throw Exception('Failed to fetch houses: $e');
    }
  }
  Future<void> _checkUserType() async {
    final prefs = await SharedPreferences.getInstance();
    final userType = prefs.getString('user_type'); // ✅ Get directly from local storage

    if (mounted) {
      setState(() {
        _isSeller = userType == 'Seller'; // ✅ Compare with exact string
        _currentUserId = prefs.getInt('user_id');
      });
    }
  }

  // Filter houses based on sale/rent and search query
  List<House> _filterHouses(List<House> houses) {
    return houses.where((house) {
      bool matchesType = _filterType == 'All' ||
          (_filterType == 'Sale' && house.status == 'sale') ||
          (_filterType == 'Rent' && house.status == 'rent');
      bool matchesSearch = house.location.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesType && matchesSearch;
    }).toList();
  }

  // Refresh the house list
  Future<void> _refreshHouses() async {
    setState(() {
      houses = fetchHouses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: NavBar(),
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        toolbarHeight: 80,
        title: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search Location...',
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    contentPadding: EdgeInsets.symmetric(vertical: 15),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.location_on, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.send, color: Colors.white),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => ChatList()));
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshHouses,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Sticky Filter Bar
              Container(
                color: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilterChip(
                      label: Text("All"),
                      selected: _filterType == 'All',
                      onSelected: (selected) {
                        setState(() {
                          _filterType = 'All';
                        });
                      },
                      selectedColor: Colors.blue,
                      labelStyle: TextStyle(
                        color: _filterType == 'All' ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 10),
                    FilterChip(
                      label: Text("Sale"),
                      selected: _filterType == 'Sale',
                      onSelected: (selected) {
                        setState(() {
                          _filterType = 'Sale';
                        });
                      },
                      selectedColor: Colors.blue,
                      labelStyle: TextStyle(
                        color: _filterType == 'Sale' ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 10),
                    FilterChip(
                      label: Text("Rent"),
                      selected: _filterType == 'Rent',
                      onSelected: (selected) {
                        setState(() {
                          _filterType = 'Rent';
                        });
                      },
                      selectedColor: Colors.blue,
                      labelStyle: TextStyle(
                        color: _filterType == 'Rent' ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // House List
              FutureBuilder<List<House>>(
                future: houses,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('No houses available'));
                  }
                  // Apply filters
                  List<House> filteredHouses = _filterHouses(snapshot.data!);
                  if (filteredHouses.isEmpty) {
                    return Center(child: Text('No houses match your criteria'));
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: filteredHouses.length,
                    itemBuilder: (context, index) {
                      House house = filteredHouses[index];
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: () {
                            // Handle card tap
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // House Image
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: house.houseImages.isNotEmpty
                                      ? Image.network(
                                    house.houseImages[0],
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(child: CircularProgressIndicator());
                                    },
                                    errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image, size: 50),
                                  )
                                      : Container(
                                    width: 120,
                                    height: 120,
                                    color: Colors.grey[200],
                                    child: Icon(Icons.image_not_supported, size: 50),
                                  ),
                                ),
                                SizedBox(width: 16),
                                // House Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        house.location,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        "Price: \₹${house.price.toStringAsFixed(2)}",
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      // Status: For Sale or For Rent
                                      Text(
                                        house.status == 'sale' ? "For Sale" : "For Rent",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: house.status == 'sale' ? Colors.blue : Colors.orange,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                      Row(
                                        children: [
                                          ElevatedButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => ShowItem(houseId: house.houseId), // Pass houseId
                                                ),
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.blue,
                                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                            child: Text("Show", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                          ),
                                          SizedBox(width: 10),
                                          OutlinedButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => showreview(),
                                                ),
                                              );
                                            },
                                            style: OutlinedButton.styleFrom(
                                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              side: BorderSide(color: Colors.blue),
                                            ),
                                            child: Text("Reviews", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _isSeller
          ? FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddHome()),
          );
          _refreshHouses();
        },
        child: Icon(Icons.add, color: Colors.white),
        backgroundColor: Colors.blue,
      )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_work),
            label: 'Sale/Rent',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work),
            label: 'Laber',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _myIndex,
        onTap: (index) {
          setState(() {
            _myIndex = index;
          });
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => _children[index]));
        },
        backgroundColor: Colors.blue,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.black,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontSize: 14),
        unselectedLabelStyle: TextStyle(fontSize: 12),
      ),
    );
  }
}

class House {
  final int houseId; // Add this field
  final String location;
  final double price;
  final List<String> houseImages;
  final String status; // Use 'sale' or 'rent' to match the API

  House({
    required this.houseId, // Add this field
    required this.location,
    required this.price,
    required this.houseImages,
    required this.status,
  });

  factory House.fromJson(Map<String, dynamic> json) {
    return House(
      houseId: json['house_id'], // Add this field
      location: json['location'] ?? 'Unknown',
      price: (json['price'] != null) ? double.tryParse(json['price'].toString()) ?? 0.0 : 0.0,
      houseImages: (json['house_images'] as List?)
          ?.map((img) => baseUrl + img.toString()) // Fixed image URLs
          .toList() ?? [],
      status: json['status'] ?? 'sale', // Default to 'sale' if not provided
    );
  }
}