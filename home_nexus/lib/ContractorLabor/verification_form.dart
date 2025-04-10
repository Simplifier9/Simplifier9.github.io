import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api.dart';
import 'VerificationInProgressPage.dart';

class VerificationFormPage extends StatefulWidget {
  @override
  _VerificationFormPageState createState() => _VerificationFormPageState();
}

class _VerificationFormPageState extends State<VerificationFormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  Uint8List? _idProofImageBytes;
  Uint8List? _currentPhotoBytes;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedEmail = prefs.getString('email');
    String? storedPhone = prefs.getString('phone');

    Future.delayed(Duration.zero, () {
      setState(() {
        emailController.text = storedEmail ?? '';
        phoneController.text = storedPhone ?? '';
      });
    });
  }


  Future<void> _pickImage(bool isIdProof) async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      Uint8List imageBytes = await pickedFile.readAsBytes();
      setState(() {
        isIdProof ? _idProofImageBytes = imageBytes : _currentPhotoBytes = imageBytes;
      });
    }
  }

  Future<void> _submitVerification() async {
    if (!_formKey.currentState!.validate() || _idProofImageBytes == null || _currentPhotoBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields and upload both images.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? userId = prefs.getInt('user_id');
    if (userId == null) return;

    var request = http.MultipartRequest('POST', Uri.parse("$baseUrl/api/submit-verification/"))
      ..fields['user_id'] = userId.toString()
      ..fields['full_name'] = fullNameController.text
      ..fields['email'] = emailController.text
      ..fields['phone'] = phoneController.text
      ..fields['status'] = "pending"
      ..files.add(http.MultipartFile.fromBytes('id_proof_image', _idProofImageBytes!, filename: 'id_proof.jpg'))
      ..files.add(http.MultipartFile.fromBytes('current_photo', _currentPhotoBytes!, filename: 'current_photo.jpg'));

    var response = await request.send();

    if (response.statusCode == 200) {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      // ✅ Update verification submission status in local storage
      await prefs.setBool('has_submitted_verification', true);
      await prefs.setString('verification_status', 'pending');

      print("✅ Verification Submitted: Status Updated in SharedPreferences");

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => VerificationInProgressPage()),
      );
    }
    else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Submission failed. Please try again.')),
      );
    }

    setState(() => _isSubmitting = false);
  }

  Widget _buildImageUploader(String label, Uint8List? imageBytes, bool isIdProof) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 5),
        GestureDetector(
          onTap: () => _pickImage(isIdProof),
          child: Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey),
            ),
            child: imageBytes != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(imageBytes, fit: BoxFit.cover),
            )
                : Center(child: Icon(Icons.upload_file, size: 40, color: Colors.grey[600])),
          ),
        ),
        SizedBox(height: 10),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Submit Verification")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: fullNameController,
                  decoration: InputDecoration(labelText: "Full Name"),
                  validator: (value) => value!.isEmpty ? "Full Name is required" : null,
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: "Email"),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => value!.isEmpty ? "Email is required" : null,
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: phoneController,
                  decoration: InputDecoration(labelText: "Phone"),
                  keyboardType: TextInputType.phone,
                  validator: (value) => value!.isEmpty ? "Phone number is required" : null,
                ),
                SizedBox(height: 20),
                _buildImageUploader("Upload ID Proof", _idProofImageBytes, true),
                _buildImageUploader("Upload Current Photo", _currentPhotoBytes, false),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitVerification,
                  child: _isSubmitting
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text("Submit for Verification"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
