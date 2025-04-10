import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

import '../api/api.dart';
import '../chat/chat.dart';

// House Model
class House {
  final int houseId;
  final int userId;
  final String location;
  final double price;
  final String status;
  final String description;
  final bool furnished;
  final List<String> houseImages;
  final DateTime dateListed;
  final String contactName;
  final String contactPhone;

  House({
    required this.houseId,
    required this.userId,
    required this.location,
    required this.price,
    required this.status,
    required this.description,
    required this.furnished,
    required this.houseImages,
    required this.dateListed,
    required this.contactName,
    required this.contactPhone,
  });

  factory House.fromJson(Map<String, dynamic> json) {
    return House(
      houseId: json['house_id'] ?? 0,
      userId: json['user'] ?? 0,
      location: json['location'] ?? 'Unknown',
      price: double.tryParse(json['price']?.toString() ?? '0.0') ?? 0.0,
      status: json['status'] ?? 'sale',
      description: json['description'] ?? 'No description available',
      furnished: json['furnished'].toString().toLowerCase() == 'true',
      houseImages: (json['house_images'] as List?)
          ?.map((img) => '$baseUrl$img')
          .toList() ??
          [],
      dateListed: DateTime.tryParse(json['date_listed'] ?? '') ?? DateTime.now(),
      contactName: json['contact_name'] ?? 'No contact',
      contactPhone: json['contact_phone'] ?? 'N/A',
    );
  }
}

class ShowItem extends StatefulWidget {
  final int houseId;

  const ShowItem({super.key, required this.houseId});

  @override
  State<ShowItem> createState() => _ShowItemState();
}

class _ShowItemState extends State<ShowItem> {
  late Future<House> _houseFuture;

  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _houseFuture = fetchHouseDetails(widget.houseId);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<House> fetchHouseDetails(int houseId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/houses/$houseId/'));
      if (response.statusCode == 200) {
        return House.fromJson(json.decode(response.body));
      }
      throw Exception('Failed to load: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error fetching details: $e');
    }
  }

  Future<void> _openDialer(String number) async {
    final Uri dialerUri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(dialerUri)) {
      await launchUrl(dialerUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot make call')),
      );
    }
  }

  void _showFullScreenGallery(BuildContext context, List<String> images, int initialIndex) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(0),
          child: Stack(
            children: [
              PageView.builder(
                itemCount: images.length,
                controller: PageController(initialPage: initialIndex),
                onPageChanged: (index) => setState(() => _currentImageIndex = index),
                itemBuilder: (context, index) => InteractiveViewer(
                  panEnabled: true,
                  minScale: 1,
                  maxScale: 4,
                  child: Center(
                    child: Image.network(
                      images[index],
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image, size: 50),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    images.length,
                        (index) => Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentImageIndex == index
                            ? Colors.white
                            : Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handlePageChange(int index) {
    if (mounted) {
      setState(() {
        _currentImageIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Property Details', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue.shade800,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<House>(
        future: _houseFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('No property found'));
          }

          final house = snapshot.data!;
          final dateFormat = DateFormat('MMM dd, yyyy');

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildImageGallerySection(house),
                const SizedBox(height: 24),
                // Add after price display
                _buildDetailTile(Icons.person, 'Contact Name', house.contactName),

                _buildDetailContainer('Price', '\₹${house.price.toStringAsFixed(2)}', Colors.green.shade800),
                _buildDetailTile(Icons.phone, 'Contact PhoneNo', house.contactPhone),
                const SizedBox(height: 20),
                _buildDetailTile(Icons.location_on, 'Location', house.location),
                _buildDetailTile(Icons.description, 'Description', house.description),
                _buildDetailTile(Icons.sell, 'Status', house.status == 'sale' ? 'For Sale' : 'For Rent'),
                _buildDetailTile(Icons.chair, 'Furnished', house.furnished ? 'Yes' : 'No'),
                _buildDetailTile(Icons.calendar_today, 'Listed Date', dateFormat.format(house.dateListed)),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(Icons.message, 'Chat', Colors.blue, () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => Chat()));
                    }),
                    _buildActionButton(Icons.call, 'Call', Colors.green, () {
                      _openDialer(house.contactPhone); // Use house.contactPhone instead of contactNumber
                    }),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildImageGallerySection(House house) {
    return Column(
      children: [
        SizedBox(
          height: 300,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: house.houseImages.length,
                onPageChanged: _handlePageChange,
                itemBuilder: (context, index) => GestureDetector(
                  onTap: () => _showFullScreenGallery(context, house.houseImages, index),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        house.houseImages[index],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.broken_image, size: 50),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (house.houseImages.length > 1) ...[
                Positioned(
                  left: 10,
                  child: IconButton(
                    icon: const Icon(Icons.chevron_left, size: 40, color: Colors.white),
                    onPressed: () {
                      if (_currentImageIndex > 0) {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                  ),
                ),
                Positioned(
                  right: 10,
                  child: IconButton(
                    icon: const Icon(Icons.chevron_right, size: 40, color: Colors.white),
                    onPressed: () {
                      if (_currentImageIndex < house.houseImages.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                  ),
                ),
              ],
              Positioned(
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentImageIndex + 1}/${house.houseImages.length}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (house.houseImages.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              house.houseImages.length,
                  (index) => GestureDetector(
                onTap: () => _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                ),
                child: Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentImageIndex == index
                        ? Colors.blue.shade600
                        : Colors.grey.shade400,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.photo_library, size: 18),
            label: const Text('View Image'),
            onPressed: () => _showFullScreenGallery(context, house.houseImages, _currentImageIndex),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 2,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDetailContainer(String title, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.w600)),
          Text(value, style: TextStyle(fontSize: 24, color: valueColor, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildDetailTile(IconData icon, String title, String value) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue.shade800),
      title: Text(title, style: TextStyle(color: Colors.grey.shade600)),
      subtitle: Text(value, style: TextStyle(fontWeight: FontWeight.w500)),
    );
  }


  Widget _buildActionButton(IconData icon, String label, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      icon: Icon(icon, color: Colors.white),
      label: Text(label),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}