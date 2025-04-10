//home.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../api/api.dart';

class House {
  final int houseId;
  final int userId;
  final String location;
  final double price;
  final String status;
  final String description;
  final bool furnished;
  final List<String> houseImages;
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
    required this.contactName,
    required this.contactPhone,
  });

  factory House.fromJson(Map<String, dynamic> json) {
    return House(
      houseId: json['house_id'] ?? 0,
      userId: json['user'] is int ? json['user'] : json['user']?['user_id'] ?? 0,
      location: json['location'] ?? 'Unknown location',
      price: json['price'] is String
          ? double.tryParse(json['price']) ?? 0.0
          : json['price']?.toDouble() ?? 0.0,
      status: json['status'] ?? 'sale',
      description: json['description'] ?? '',
      furnished: json['furnished'] ?? false,
      houseImages: List<String>.from(json['house_images'] ?? []),
      contactName: json['contact_name'] ?? '',
      contactPhone: json['contact_phone'] ?? '',
    );
  }
}

class AddHome extends StatefulWidget {
  @override
  _AddHomeState createState() => _AddHomeState();
}

class _AddHomeState extends State<AddHome> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _contactNameController = TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();


  String _status = 'sale';
  String _availability = 'available';
  String _furnished = 'No';
  List<File> _imageFiles = [];
  List<Uint8List> _webImageBytes = [];
  List<String> _imageUrls = [];
  String _userId = "";
  bool _isSubmitting = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('user_id_str') ??
          prefs.getInt('user_id').toString();
    });
  }
  // In home.dart > _getAuthHeaders()


  // In home.dart > _verifyAuthentication()


  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage(
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );

    if (pickedFiles.isNotEmpty) {
      if (kIsWeb) {
        List<Uint8List> webImages = [];
        for (var file in pickedFiles) {
          webImages.add(await file.readAsBytes());
        }
        setState(() {
          _webImageBytes.addAll(webImages);
        });
      } else {
        setState(() {
          _imageFiles.addAll(pickedFiles.map((file) => File(file.path)));
        });
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      if (kIsWeb) {
        _webImageBytes.removeAt(index);
      } else {
        _imageFiles.removeAt(index);
      }
    });
  }

  Future<String?> uploadImage(dynamic image) async {
    try {
      var request = http.MultipartRequest(
        "POST",
        Uri.parse("$baseUrl/api/upload_image/"),
      );

      // Add image file (no auth headers)
      if (kIsWeb) {
        request.files.add(
          http.MultipartFile.fromBytes(
            "image", // Field name for the image
            image, // Uint8List if kIsWeb
            filename: "upload_${DateTime.now().millisecondsSinceEpoch}.png", // Unique filename
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath(
            "image", // Field name for the image
            (image as File).path, // File path if not web
          ),
        );
      }

      // Send request with timeout
      final response = await request.send().timeout(Duration(seconds: 30));

      // Handle response
      if (response.statusCode == 201) {
        final responseBody = await response.stream.bytesToString();
        final jsonResponse = json.decode(responseBody);
        return jsonResponse['file_url'];
      }

      // Handle server errors
      final errorBody = await response.stream.bytesToString();
      print("Image upload failed: ${response.statusCode} - $errorBody");
      return null;

    } catch (e) {
      print("Image upload error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Image upload failed: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }
  }



  Future<void> _uploadImagesAndSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please login to add a property"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    List<String> uploadedImageUrls = [];

    for (var image in (kIsWeb ? _webImageBytes : _imageFiles)) {
      String? imageUrl = await uploadImage(image);
      if (imageUrl != null) {
        uploadedImageUrls.add(imageUrl);
      }
    }

    if (uploadedImageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please add at least one image"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {
        _isSubmitting = false;
      });
      return;
    }

    await _submitForm(uploadedImageUrls);
  }

  Future<void> _submitForm(List<String> uploadedImageUrls) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/add_house/"),
        headers: {"Content-Type": "application/json"}, // No auth header
        body: jsonEncode({
          "user": _userId,
          "location": _locationController.text,
          "price": _priceController.text,
          "description": _descriptionController.text,
          "status": _status,
          "availability": _availability,
          "furnished": _furnished,
          "house_images": uploadedImageUrls,
          "contact_name": _contactNameController.text,
          "contact_phone": _contactPhoneController.text,
        }),
      ).timeout(Duration(seconds: 30)); // Add timeout

      // Log the response for debugging
      print("Response status: ${response.statusCode}");
      print("Response body: ${await response.body}");

      // Handle response
      if (response.statusCode == 201) {
        // Success handling (e.g., navigate or show a success message)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Property listed successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Log the error response
        final responseBody = jsonDecode(await response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed: ${responseBody['detail'] ?? 'Unknown error'}"),
            backgroundColor: Colors.red,
          ),
        );
        print("Error response: $responseBody"); // Log detailed error response
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
      print("Exception: $e"); // Log any exceptions
    } finally {
      setState(() => _isSubmitting = false);
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'List Your Property',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue.shade800,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Property Details',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
                SizedBox(height: 15),
                _buildTextField(
                  controller: _contactNameController,
                  label: 'Contact Name',
                  hint: 'Enter contact person name',
                  icon: Icons.person,
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                SizedBox(height: 15),
                _buildTextField(
                  controller: _contactPhoneController,
                  label: 'Contact Phone',
                  hint: 'Enter 10-digit phone number',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value!.isEmpty) return 'Required';
                    if (!RegExp(r'^\d{10}$').hasMatch(value)) return 'Invalid phone';
                    return null;
                  },
                ),
                SizedBox(height: 20),
                _buildTextField(
                  controller: _priceController,
                  label: 'Price',
                  hint: 'Enter price in INR',
                  isPriceField: true,
                  keyboardType: TextInputType.number,
                  validator: (value) => value!.isEmpty ? 'Please enter price' : null,
                ),
                SizedBox(height: 15),
                _buildTextField(
                  controller: _locationController,
                  label: 'Location',
                  hint: 'Enter property address',
                  icon: Icons.location_on,
                  validator: (value) => value!.isEmpty ? 'Please enter location' : null,
                ),
                SizedBox(height: 15),
                _buildTextField(
                  controller: _descriptionController,
                  label: 'Description',
                  hint: 'Describe your property in detail',
                  icon: Icons.description,
                  maxLines: 4,
                  validator: (value) => value!.isEmpty ? 'Please enter description' : null,
                ),
                SizedBox(height: 20),
                _buildSectionTitle('Property Features'),
                SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(
                        value: _status,
                        items: ['sale', 'rent'],
                        label: 'Listing Type',
                        icon: Icons.sell,
                        onChanged: (newValue) => setState(() => _status = newValue!),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: _buildDropdown(
                        value: _furnished,
                        items: ['Yes', 'No'],
                        label: 'Furnished',
                        icon: Icons.chair,
                        onChanged: (newValue) => setState(() => _furnished = newValue!),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 25),
                _buildSectionTitle('Property Images'),
                SizedBox(height: 10),
                Text(
                  'Add high-quality photos (max 10)',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                SizedBox(height: 10),
                InkWell(
                  onTap: _pickImages,
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_upload, size: 40, color: Colors.blue.shade600),
                        SizedBox(height: 10),
                        Text(
                          'Tap to upload images',
                          style: TextStyle(
                            color: Colors.blue.shade600,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'PNG or JPG (max 5MB each)',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 15),
                if ((kIsWeb ? _webImageBytes : _imageFiles).isNotEmpty) ...[
                  Text(
                    'Selected Images (${kIsWeb ? _webImageBytes.length : _imageFiles.length})',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: kIsWeb ? _webImageBytes.length : _imageFiles.length,
                      itemBuilder: (context, index) {
                        return AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          margin: EdgeInsets.only(right: 8),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: kIsWeb
                                    ? Image.memory(
                                  _webImageBytes[index],
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                )
                                    : Image.file(
                                  _imageFiles[index],
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 5,
                                right: 5,
                                child: GestureDetector(
                                  onTap: () => _removeImage(index),
                                  child: AnimatedContainer(
                                    duration: Duration(milliseconds: 200),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      shape: BoxShape.circle,
                                    ),
                                    padding: EdgeInsets.all(4),
                                    child: Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 20),
                ],
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _uploadImagesAndSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade800,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: AnimatedSwitcher(
                    duration: Duration(milliseconds: 300),
                    child: _isSubmitting
                        ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text('Submitting...'),
                      ],
                    )
                        : Text(
                      'List Property',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.blue.shade800,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    bool isPriceField = false,
    IconData? icon,
  }) {
    final iconColor = Colors.blue.shade600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: isPriceField
                ? Padding(
              padding: EdgeInsets.only(left: 12, right: 8),
              child: Text(
                '₹',
                style: TextStyle(
                  fontSize: 20,
                  color: iconColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
                : (icon != null
                ? Icon(icon, color: iconColor)
                : null),
            prefixIconConstraints: BoxConstraints(
              minWidth: isPriceField ? 24 : 48,
              minHeight: 0,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue.shade600, width: 1.5),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 16,
            ),
            isDense: true,
          ),
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required String label,
    required IconData icon,
    required void Function(String?) onChanged,
  }) {
    final iconColor = Colors.blue.shade600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            onChanged: onChanged,
            items: items.map((item) {
              return DropdownMenuItem(
                value: item,
                child: Text(
                  item,
                  style: TextStyle(fontSize: 14),
                ),
              );
            }).toList(),
            decoration: InputDecoration(
              border: InputBorder.none,
              prefixIcon: Icon(icon, color: iconColor),
              contentPadding: EdgeInsets.symmetric(horizontal: 12),
            ),
            isExpanded: true,
            icon: Icon(Icons.arrow_drop_down, color: iconColor),
            style: TextStyle(color: Colors.grey.shade800),
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ],
    );
  }
}