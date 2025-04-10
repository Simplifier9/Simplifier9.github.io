import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../api/api.dart';
import 'CreatePortfolio.dart';

class Portfolio {
  final int id;
  final double price;
  final int experienceYears;
  final String speciality;
  final String description;
  final List<String> previousWork;
  final int userId;

  Portfolio({
    required this.id,
    required this.price,
    required this.experienceYears,
    required this.speciality,
    required this.description,
    required this.previousWork,
    required this.userId,
  });

  factory Portfolio.fromJson(Map<String, dynamic> json) {
    // Handle the previous_work field which might be a string, list, or already parsed
    List<String> previousWork = [];

    if (json['previous_work'] != null) {
      if (json['previous_work'] is String) {
        try {
          // Handle case where it's a JSON string
          final decoded = jsonDecode(json['previous_work']);
          if (decoded is List) {
            previousWork = List<String>.from(decoded.map((item) => item.toString()));
          } else {
            previousWork = [json['previous_work']];
          }
        } catch (e) {
          // If decoding fails, treat as a single string
          previousWork = [json['previous_work']];
        }
      } else if (json['previous_work'] is List) {
        // Handle case where it's already a list
        previousWork = List<String>.from(json['previous_work'].map((item) => item.toString()));
      }
    }

    return Portfolio(
      id: json['portfolio_id'] ?? json['id'] ?? 0,
      price: json['price'] is String
          ? double.tryParse(json['price']) ?? 0.0
          : json['price']?.toDouble() ?? 0.0,
      experienceYears: json['experience_years'] ?? 0,
      speciality: json['speciality'] ?? '',
      description: json['description'] ?? '',
      previousWork: previousWork,
      userId: json['user'] is int ? json['user'] : json['user']?['user_id'] ?? 0,
    );
  }
}

class UserProfile {
  final int userId;
  final String name;
  final String? profilePic;
  final String? email;
  final List<Portfolio> portfolios;

  UserProfile({
    required this.userId,
    required this.name,
    this.profilePic,
    this.email,
    required this.portfolios,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    List<Portfolio> portfolios = [];
    if (json['portfolios'] != null && json['portfolios'] is List) {
      portfolios = (json['portfolios'] as List)
          .map((p) => Portfolio.fromJson(p))
          .toList();
    }

    return UserProfile(
      userId: json['user_id'] ?? 0,
      name: json['name'] ?? '',
      profilePic: json['profile_pic'],
      email: json['email'],
      portfolios: portfolios,
    );
  }
}

class PortfolioScreen extends StatefulWidget {
  final int userId;

  PortfolioScreen({required this.userId});

  @override
  _PortfolioScreenState createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  Portfolio? portfolio;
  UserProfile? userProfile;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchPortfolio();
  }

  Future<void> fetchPortfolio() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/get_worker_portfolio/${widget.userId}/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Fetched portfolio data: $data');

        setState(() {
          userProfile = UserProfile.fromJson(data['user']);
          portfolio = userProfile?.portfolios.isNotEmpty == true
              ? userProfile!.portfolios.first
              : null;
          isLoading = false;
          errorMessage = null;
        });

        if (portfolio != null) {
          print('Portfolio ID: ${portfolio!.id}');
        } else {
          print('No portfolio found');
        }
      } else {
        throw Exception('Failed to load portfolio: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        portfolio = null;
        userProfile = null;
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  void _createPortfolio() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePortfolioScreen(userId: widget.userId),
      ),
    ).then((_) => fetchPortfolio());
  }

  Future<void> _submitEditPortfolio(Map<String, dynamic> updatedData) async {
    if (portfolio == null || portfolio!.id == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Invalid portfolio ID')),
      );
      return;
    }

    try {
      final dataToSend = {
        ...updatedData,
        'user_id': widget.userId, // Include the user ID from widget
      };

      final response = await http.put(
        Uri.parse('$baseUrl/api/edit_portfolio/${portfolio!.id}/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(dataToSend),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Portfolio updated successfully!')),
        );
        fetchPortfolio();
      } else {
        final errorData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorData['error'] ?? 'Failed to update portfolio')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _editPortfolio() {
    if (portfolio != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreatePortfolioScreen(
            userId: widget.userId,
            initialData: {
              'speciality': portfolio!.speciality,
              'price': portfolio!.price.toString(),
              'experience_years': portfolio!.experienceYears,
              'description': portfolio!.description,
              'previous_work': portfolio!.previousWork,
            },
            isEditing: true,
            onSave: _submitEditPortfolio,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Professional Portfolio'),
        centerTitle: true,
        actions: [
          if (portfolio != null)
            IconButton(
              icon: Icon(Icons.edit, color: Colors.white),
              onPressed: _editPortfolio,
            ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: portfolio == null && !isLoading && errorMessage == null
          ? FloatingActionButton(
        onPressed: _createPortfolio,
        child: Icon(Icons.add),
        backgroundColor: Theme.of(context).primaryColor,
      )
          : null,
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Loading portfolio...'),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 50, color: Colors.red),
            SizedBox(height: 20),
            Text('Error loading portfolio:', style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            Text(errorMessage!, textAlign: TextAlign.center),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: fetchPortfolio,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (portfolio == null) {
      return _buildNoPortfolioView();
    }

    return _buildPortfolioView();
  }

  Widget _buildNoPortfolioView() {
    return Center(
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          Icon(Icons.work_outline, size: 80, color: Colors.blueGrey),
      SizedBox(height: 20),
      Text('No Portfolio Found',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      SizedBox(height: 10),
      Text('Create your professional portfolio to showcase your skills',
          style: TextStyle(fontSize: 16),
          textAlign: TextAlign.center),
      SizedBox(height: 30),
      ElevatedButton(
        onPressed: _createPortfolio,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Text('Create Portfolio', style: TextStyle(fontSize: 18)),
        ),
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      )],
      ),
    );
  }

  Widget _buildPortfolioView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: userProfile?.profilePic != null
                      ? NetworkImage(userProfile!.profilePic!)
                      : AssetImage('assets/default_profile.png') as ImageProvider,
                ),
                SizedBox(height: 16),
                Text(
                  userProfile?.name ?? 'Professional',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  portfolio!.speciality.isNotEmpty ? portfolio!.speciality : 'Specialist',
                  style: TextStyle(fontSize: 18, color: Colors.blueGrey),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard(
                      context,
                      icon: Icons.work_history,
                      title: 'Experience',
                      value: '${portfolio!.experienceYears} years',
                    ),
                    _buildStatCard(
                      context,
                      icon: Icons.attach_money,
                      title: 'Per Day Rate',
                      value: '\$${portfolio!.price.toStringAsFixed(2)}',
                    )
                  ],
                ),
                SizedBox(height: 30),
                Text(
                  'About Me',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text(
                  portfolio!.description.isNotEmpty
                      ? portfolio!.description
                      : 'No description provided',
                  style: TextStyle(fontSize: 16, height: 1.5),
                ),
                SizedBox(height: 30),
                Text(
                  'Previous Work',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                if (portfolio!.previousWork.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'No previous work examples provided yet',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ),
                if (portfolio!.previousWork.isNotEmpty)
                  ...portfolio!.previousWork.map((work) => Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            work,
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, {required IconData icon, required String title, required String value}) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 30, color: Theme.of(context).primaryColor),
            SizedBox(height: 8),
            Text(title, style: TextStyle(color: Colors.grey)),
            SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}