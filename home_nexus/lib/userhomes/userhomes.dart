import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../api/api.dart';
import '../login/login.dart';



class House {
  final int houseId;
  final String location;
  final double price;
  final String status;
  final List<String> images;
  final String contactName;
  final String contactPhone;
  final String description;
  final bool furnished;

  House({
    required this.houseId,
    required this.location,
    required this.price,
    required this.status,
    required this.images,
    required this.contactName,
    required this.contactPhone,
    required this.description,
    required this.furnished,
  });

  factory House.fromJson(Map<String, dynamic> json) {
    // Process image URLs for web compatibility
    List<String> processedImages = [];
    if (json['house_images'] != null) {
      processedImages = (json['house_images'] as List).map((imageUrl) {
        if (imageUrl is String) {
          if (!imageUrl.startsWith('http')) {
            return '$baseUrl$imageUrl'; // Handle relative URLs
          }
          return imageUrl;
        }
        return '';
      }).where((url) => url.isNotEmpty).toList();
    }

    return House(
      houseId: json['house_id'] ?? 0,
      location: json['location'] ?? 'Unknown Location',
      price: (json['price'] is int) ? (json['price'] as int).toDouble()
          : (json['price'] is double) ? json['price']
          : double.tryParse(json['price'].toString()) ?? 0.0,
      status: (json['status']?.toString().toLowerCase()) ?? 'sale',
      images: processedImages,
      contactName: json['contact_name']?.toString() ?? '',
      contactPhone: json['contact_phone']?.toString() ?? '',
      description: json['description']?.toString() ?? 'No description available',
      furnished: json['furnished']?.toString().toLowerCase() == 'true',
    );
  }
}

class ImageCarousel extends StatefulWidget {
  final List<String> images;
  final double height;
  final bool showNavigationArrows;

  const ImageCarousel({
    super.key,
    required this.images,
    this.height = 200,
    this.showNavigationArrows = false,
  });

  @override
  State<ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _navigatePage(int direction) {
    _pageController.animateToPage(
      _currentIndex + direction,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported, size: 50, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text('No Image Available', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildImageErrorWidget(String url, dynamic error) {
    debugPrint('Image load error: $error');
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 50, color: Colors.red[400]),
            const SizedBox(height: 8),
            Text('Failed to Load Image', style: TextStyle(color: Colors.red[600])),
            const SizedBox(height: 4),
            Text(
              url.length > 30 ? '${url.substring(0, 30)}...' : url,
              style: const TextStyle(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: _buildImagePlaceholder(),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        Column(
          children: [
            SizedBox(
              height: widget.height,
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.images.length,
                onPageChanged: (index) => setState(() => _currentIndex = index),
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: widget.images[index],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: (context, url) => _buildImagePlaceholder(),
                        errorWidget: (context, url, error) =>
                            _buildImageErrorWidget(url, error),
                        httpHeaders: const {
                          'Accept': 'image/*',
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            if (widget.images.length > 1) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.images.length, (index) {
                  return Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentIndex == index
                          ? Colors.blue
                          : Colors.grey.withOpacity(0.5),
                    ),
                  );
                }),
              ),
            ],
          ],
        ),
        if (widget.showNavigationArrows && widget.images.length > 1) ...[
          Positioned(
            left: 8,
            child: IconButton(
              icon: const Icon(Icons.chevron_left, size: 30, color: Colors.white),
              onPressed: _currentIndex > 0 ? () => _navigatePage(-1) : null,
            ),
          ),
          Positioned(
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.chevron_right, size: 30, color: Colors.white),
              onPressed: _currentIndex < widget.images.length - 1
                  ? () => _navigatePage(1)
                  : null,
            ),
          ),
        ],
      ],
    );
  }
}

class UserHomes extends StatefulWidget {
  const UserHomes({super.key});

  @override
  State<UserHomes> createState() => _UserHomesState();
}

class _UserHomesState extends State<UserHomes> {
  late Future<List<House>> _housesFuture;
  String? _userId;
  final Map<int, bool> _expandedStates = {};
  final GlobalKey<RefreshIndicatorState> _refreshKey = GlobalKey();

  // Web-friendly HTTP client
  http.Client createHttpClient() {
    return http.Client(); // Basic client for web
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getString('user_id_str');

      debugPrint('Loaded user ID: $_userId');

      if (_userId == null || _userId!.isEmpty) {
        if (mounted) _redirectToLogin();
        return;
      }

      if (mounted) {
        setState(() {
          _refreshHouses();
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      if (mounted) _redirectToLogin();
    }
  }

  void _refreshHouses() {
    setState(() {
      _housesFuture = _fetchHouses();
    });
    _refreshKey.currentState?.show();
  }

  Future<List<House>> _fetchHouses() async {
    final client = createHttpClient();

    try {
      final uri = Uri.parse('$baseUrl/api/user/$_userId/houses/');
      debugPrint('Fetching from: $uri');

      final response = await client.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      debugPrint('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => House.fromJson(json)).toList();
      } else if (response.statusCode == 404) {
        throw Exception('Endpoint not found. Check your API URL');
      } else {
        throw Exception('Failed to load houses: ${response.statusCode}');
      }
    } on SocketException catch (e) {
      throw Exception('Network error: Is the server running? $e');
    } on TimeoutException {
      throw Exception('Request timed out. Check your connection');
    } catch (e) {
      throw Exception('Error fetching houses: $e');
    } finally {
      client.close();
    }
  }

  Future<void> _deleteHouse(int houseId) async {
    final client = createHttpClient();

    try {
      final response = await client.delete(
        Uri.parse('$baseUrl/api/houses/$houseId/delete/'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Property deleted successfully')),
        );
        _refreshHouses();
      } else {
        throw Exception('Delete failed: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting property: ${e.toString()}')),
        );
      }
    } finally {
      client.close();
    }
  }

  Widget _buildHouseCard(House house) {
    final isExpanded = _expandedStates[house.houseId] ?? false;

    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _expandedStates[house.houseId] = !isExpanded),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: 'house-images-${house.houseId}',
                child: ImageCarousel(
                  images: house.images,
                  showNavigationArrows: true,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                house.location,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '₹${house.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Chip(
                    label: Text(
                      house.status.toUpperCase(),
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: house.status == 'sale'
                        ? Colors.blue.shade100
                        : Colors.orange.shade100,
                  ),
                ],
              ),
              if (isExpanded) ...[
                const SizedBox(height: 12),
                Text(
                  house.description,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                _buildDetailRow('Contact:', house.contactName),
                _buildDetailRow('Phone:', house.contactPhone),
                _buildDetailRow('Furnished:', house.furnished ? 'Yes' : 'No'),
                const SizedBox(height: 12),
                _buildActionButtons(house),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildActionButtons(House house) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _buildIconButton(
          icon: Icons.edit,
          color: Colors.blue,
          onPressed: () => _editHouse(house),
        ),
        const SizedBox(width: 8),
        _buildIconButton(
          icon: Icons.delete,
          color: Colors.red,
          onPressed: () => _confirmDelete(house.houseId),
        ),
      ],
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return CircleAvatar(
      backgroundColor: color.withOpacity(0.1),
      child: IconButton(
        icon: Icon(icon, color: color),
        onPressed: onPressed,
      ),
    );
  }

  Future<void> _editHouse(House house) async {
    final controllers = {
      'location': TextEditingController(text: house.location),
      'price': TextEditingController(text: house.price.toStringAsFixed(2)),
      'contactName': TextEditingController(text: house.contactName),
      'contactPhone': TextEditingController(text: house.contactPhone),
      'description': TextEditingController(text: house.description),
    };

    bool isFurnished = house.furnished;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Edit Property'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildEditField('Location', controllers['location']!),
                  _buildEditField('Price', controllers['price']!, isNumber: true),
                  _buildEditField('Contact Name', controllers['contactName']!),
                  _buildEditField('Contact Phone', controllers['contactPhone']!, isPhone: true),
                  _buildEditField('Description', controllers['description']!, maxLines: 3),
                  SwitchListTile(
                    title: const Text('Furnished'),
                    value: isFurnished,
                    onChanged: (value) => setState(() => isFurnished = value),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => _submitEdits(house.houseId, controllers, isFurnished),
                child: const Text('Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEditField(String label, TextEditingController controller, {
    bool isNumber = false,
    bool isPhone = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        keyboardType: isNumber ? TextInputType.number :
        isPhone ? TextInputType.phone : TextInputType.text,
        maxLines: maxLines,
        inputFormatters: isPhone
            ? [FilteringTextInputFormatter.digitsOnly]
            : null,
      ),
    );
  }

  Future<void> _submitEdits(int houseId,
      Map<String, TextEditingController> controllers, bool furnished) async {
    final client = createHttpClient();

    try {
      final response = await client.put(
        Uri.parse('$baseUrl/api/houses/$houseId/update/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'location': controllers['location']!.text,
          'price': double.parse(controllers['price']!.text),
          'contact_name': controllers['contactName']!.text,
          'contact_phone': controllers['contactPhone']!.text,
          'description': controllers['description']!.text,
          'furnished': furnished,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Property updated successfully')),
        );
        _refreshHouses();
        Navigator.pop(context);
      } else {
        throw Exception('Update failed: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      client.close();
    }
  }

  void _confirmDelete(int houseId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('This action cannot be undone'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteHouse(houseId);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_userId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      key: _refreshKey,
      onRefresh: () async => _refreshHouses(),
      child: FutureBuilder<List<House>>(
        future: _housesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshHouses,
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.home_work, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No properties found'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshHouses,
                    child: const Text('Refresh'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) =>
                _buildHouseCard(snapshot.data![index]),
          );
        },
      ),
    );
  }

  void _redirectToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) =>  Login()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Properties'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshHouses,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _redirectToLogin,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _buildContent(),
    );
  }
}