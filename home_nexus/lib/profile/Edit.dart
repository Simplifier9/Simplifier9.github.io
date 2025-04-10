import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as web;
import 'package:path_provider/path_provider.dart';
import '../profile/api_service.dart';
import 'profileview.dart';
import 'dart:convert'; // Add this line

class Edit extends StatefulWidget {
  final int userId;
  const Edit({super.key, required this.userId});

  @override
  State<Edit> createState() => _EditState();
}

class _EditState extends State<Edit> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _oldPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;
  bool _isLoading = false;
  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  Uint8List? _selectedImageBytes;
  String? _selectedImageMime;
  String? _currentProfilePic;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _oldPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await ApiService.getUserProfile(widget.userId);
      setState(() {
        _nameController.text = user.name;
        _phoneController.text = user.phoneNo;
        _currentProfilePic = user.profilePic;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load user data: $e')),
      );
    }
  }

  Future<void> _pickImage() async {
    if (kIsWeb) {
      final input = web.FileUploadInputElement()..accept = 'image/*';
      input.click();

      input.onChange.listen((e) async {
        final files = input.files;
        if (files != null && files.isNotEmpty) {
          final reader = web.FileReader();
          reader.readAsDataUrl(files[0] as web.Blob); // Fixed method name
          reader.onLoadEnd.listen((event) {
            if (mounted) {
              setState(() {
                _selectedImageMime = files[0].type;
                _selectedImageBytes = base64.decode(
                    reader.result.toString().split(',').last);
              });
            }
          });
        }
      });
    } else {
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
        });
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final Map<String, dynamic> updateData = {
        'name': _nameController.text,
        'phone_no': _phoneController.text,
      };

      if (_newPasswordController.text.isNotEmpty) {
        updateData.addAll({
          'old_password': _oldPasswordController.text,
          'new_password': _newPasswordController.text,
        });
      }

      // Update the image handling in _updateProfile
      if (_selectedImageBytes != null) {
        // Unified handling for all platforms
        updateData['profile_pic'] = {
          'data': base64.encode(_selectedImageBytes!),
          'mime': _selectedImageMime ?? 'image/png'
        };
      }

      final updatedUser = await ApiService.updateUserProfile(
        widget.userId,
        updateData,
      );

      if (mounted) {
        Navigator.pop(context, true); // Force refresh
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildProfilePicture() {
    return GestureDetector(
      onTap: _pickImage,
      child: CircleAvatar(
        radius: 50,
        backgroundColor: Colors.grey[600],
        backgroundImage: _selectedImageBytes != null
            ? MemoryImage(_selectedImageBytes!)
            : (_currentProfilePic != null
            ? NetworkImage('$_currentProfilePic?t=${DateTime.now().millisecondsSinceEpoch}')
            : null),
        child: _selectedImageBytes == null && _currentProfilePic == null
            ? const Icon(Icons.camera_alt, size: 40, color: Colors.white)
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildProfilePicture(),
                const SizedBox(height: 20),
                _buildTextField('Name', _nameController),
                _buildTextField('Phone Number', _phoneController),
                _buildPasswordField(
                  controller: _oldPasswordController,
                  label: 'Old Password',
                  obscure: _obscureOldPassword,
                  onToggle: () => setState(
                          () => _obscureOldPassword = !_obscureOldPassword),
                  isRequired: _newPasswordController.text.isNotEmpty,
                ),
                _buildPasswordField(
                  controller: _newPasswordController,
                  label: 'New Password',
                  obscure: _obscureNewPassword,
                  onToggle: () => setState(
                          () => _obscureNewPassword = !_obscureNewPassword),
                ),
                _buildPasswordField(
                  controller: _confirmPasswordController,
                  label: 'Confirm New Password',
                  obscure: _obscureConfirmPassword,
                  onToggle: () => setState(
                          () => _obscureConfirmPassword = !_obscureConfirmPassword),
                  isConfirm: true,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Save Changes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) => value!.isEmpty ? 'Please enter $label' : null,
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    bool isConfirm = false,
    bool isRequired = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
            onPressed: onToggle,
          ),
        ),
        validator: (value) {
          if (isRequired && value!.isEmpty) {
            return 'This field is required';
          }
          if (isConfirm && _newPasswordController.text != value) {
            return 'Passwords do not match';
          }
          if (!isConfirm && value!.isNotEmpty && value.length < 8) {
            return 'Password must be at least 8 characters';
          }
          return null;
        },
      ),
    );
  }
}