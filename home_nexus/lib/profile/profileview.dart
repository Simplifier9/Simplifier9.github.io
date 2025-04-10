import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_service.dart';
import 'edit.dart';

class ProfileView extends StatefulWidget {
  final int userId;
  final String? profileImageUrl;

  const ProfileView({
    Key? key,
    required this.userId,
    this.profileImageUrl,
  }) : super(key: key);

  @override
  _ProfileViewState createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  late Future<User> _userFuture;
  String? _cachedProfileImage;

  @override
  void initState() {
    super.initState();
    _cachedProfileImage = widget.profileImageUrl;
    _loadUserData();
  }

  void _loadUserData() {
    setState(() {
      _userFuture = ApiService.getUserProfile(widget.userId);
    });
  }

  Widget _buildProfileImage(User user) {
    final imageUrl = _cachedProfileImage ?? user.profilePic;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 50,
        backgroundColor: Colors.grey[600],
        backgroundImage: NetworkImage(
          '$imageUrl?t=${DateTime.now().millisecondsSinceEpoch}',
        ),
        onBackgroundImageError: (exception, stackTrace) {
          debugPrint('Image load error: $exception');
        },
      );
    } else {
      return CircleAvatar(
        radius: 50,
        backgroundColor: Colors.grey[600],
        child: const Icon(Icons.person, size: 50, color: Colors.white),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("View Profile"),
        backgroundColor: Colors.blue,
      ),
      body: FutureBuilder<User>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('No user data found'));
          }

          final user = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildProfileImage(user),
                const SizedBox(height: 20),
                _buildInfoTile('Name', user.name),
                _buildInfoTile('Email', user.email),
                _buildInfoTile('Phone Number', user.phoneNo),
                _buildInfoTile('User Type', user.userType),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () async {
                    final needsRefresh = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Edit(userId: widget.userId),
                      ),
                    );
                    if (needsRefresh == true) {
                      _loadUserData();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: const Text('Edit Profile'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}