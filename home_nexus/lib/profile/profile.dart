import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../login/login.dart';
import '../userOrders/userOrders.dart';
import '../profile/profileview.dart';
import '../ContractorLabor/portfolio.dart';
import '../userHomes/userHomes.dart';
import '../sale/sale.dart';
import '../laber/laber.dart';
import '../api/api.dart' as api;
import 'api_service.dart';

class Profile extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  String? userType;
  String? profileImageUrl;
  int? userId;
  int _currentIndex = 2; // Set to 2 since we are on Profile screen

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = prefs.getInt('user_id');
    final currentUserType = prefs.getString('user_type');
    final currentProfilePic = prefs.getString('profile_pic');

    setState(() {
      userType = currentUserType;
      userId = currentUserId;
      profileImageUrl = currentProfilePic;
    });

    if (userId != null) {
      try {
        final user = await ApiService.getUserProfile(userId!);
        if (mounted) {
          setState(() {
            profileImageUrl = user.profilePic;
          });
        }
        await prefs.setString('profile_pic', user.profilePic ?? '');
      } catch (e) {
        debugPrint('Error fetching profile: $e');
      }
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
        screen = LaberScreen(); // Adjust as per your Labor screen
        break;
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              _buildProfileAvatar(),
              const SizedBox(height: 10),
              _buildViewProfileButton(),
              const SizedBox(height: 10),
              if (userType == 'Seeker') ...[
                _buildNavigationButton("Your Orders", (userId) => Orderscreen(userId: userId)),
              ] else if (userType == 'Seller') ...[
                _buildNavigationButton("Your Homes", (userId) => UserHomes()),
              ] else if (userType == 'Contractor' || userType == 'Labor') ...[
                _buildNavigationButton("Your Portfolio", (userId) => PortfolioScreen(userId: userId)),
                const SizedBox(height: 10),
                _buildNavigationButton("Your Orders", (userId) => Orderscreen(userId: userId)),
              ],
              const SizedBox(height: 20),
              _buildLogoutButton(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: (userType == 'Seeker' || userType == 'Seller')
          ? BottomNavigationBar(
        items: const [
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
      )
          : null,
    );
  }

  Widget _buildProfileAvatar() {
    return CircleAvatar(
      radius: 50,
      backgroundColor: Colors.grey[300],
      backgroundImage: profileImageUrl != null && profileImageUrl!.isNotEmpty
          ? NetworkImage(_getFullImageUrl(profileImageUrl!))
          : null,
      child: profileImageUrl == null || profileImageUrl!.isEmpty
          ? const Icon(Icons.person, size: 50, color: Colors.white)
          : null,
    );
  }

  Widget _buildViewProfileButton() {
    return GestureDetector(
      onTap: () async {
        if (userId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileView(
                userId: userId!,
                profileImageUrl: profileImageUrl,
              ),
            ),
          );
        } else {
          _handleLoginRequired();
        }
      },
      child: _buildButton("View your Profile"),
    );
  }

  Widget _buildNavigationButton(String text, Widget Function(int userId) screen) {
    return GestureDetector(
      onTap: () async {
        if (userId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => screen(userId!)),
          );
        } else {
          _handleLoginRequired();
        }
      },
      child: _buildButton(text),
    );
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: () async {
        final shouldLogout = await _showLogoutConfirmationDialog(context);
        if (shouldLogout) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.clear();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => Login()),
                (Route<dynamic> route) => false,
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.red, Colors.redAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.redAccent.withOpacity(0.4),
              blurRadius: 8,
              spreadRadius: 1,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: const Text(
          "Log Out",
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildButton(String text) {
    return Container(
      padding: const EdgeInsets.all(15),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.black, fontSize: 16),
        textAlign: TextAlign.center,
      ),
    );
  }

  Future<bool> _showLogoutConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Logout"),
          ),
        ],
      ),
    ) ?? false;
  }

  void _handleLoginRequired() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please login again')),
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => Login()),
    );
  }

  String _getFullImageUrl(String url) {
    if (url.startsWith('http')) {
      return url;
    }
    return '${api.baseUrl}$url';
  }
}
