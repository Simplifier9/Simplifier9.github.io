import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../api/api.dart';

class CreatePortfolioScreen extends StatefulWidget {
  final int userId;
  final Map<String, dynamic>? initialData;
  final bool isEditing;
  final Function(Map<String, dynamic>)? onSave;

  CreatePortfolioScreen({
    required this.userId,
    this.initialData,
    this.isEditing = false,
    this.onSave,
  });

  @override
  _CreatePortfolioScreenState createState() => _CreatePortfolioScreenState();
}

class _CreatePortfolioScreenState extends State<CreatePortfolioScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _specialityController;
  late TextEditingController _priceController;
  late TextEditingController _experienceController;
  late TextEditingController _descriptionController;
  late TextEditingController _previousWorkController;
  List<String> previousWorkList = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _specialityController = TextEditingController(
        text: widget.initialData?['speciality']?.toString());
    _priceController = TextEditingController(
        text: widget.initialData?['price']?.toString());
    _experienceController = TextEditingController(
        text: widget.initialData?['experience_years']?.toString());
    _descriptionController = TextEditingController(
        text: widget.initialData?['description']?.toString());
    _previousWorkController = TextEditingController();

    if (widget.initialData?['previous_work'] != null) {
      previousWorkList = List<String>.from(widget.initialData!['previous_work']);
    }
  }

  @override
  void dispose() {
    _specialityController.dispose();
    _priceController.dispose();
    _experienceController.dispose();
    _descriptionController.dispose();
    _previousWorkController.dispose();
    super.dispose();
  }

  void _addPreviousWork() {
    if (_previousWorkController.text.trim().isNotEmpty) {
      setState(() {
        previousWorkList.add(_previousWorkController.text.trim());
        _previousWorkController.clear();
      });
    }
  }

  void _removePreviousWork(int index) {
    setState(() {
      previousWorkList.removeAt(index);
    });
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      final data = {
        'speciality': _specialityController.text.trim(),
        'price': double.tryParse(_priceController.text) ?? 0.0,
        'experience_years': int.tryParse(_experienceController.text) ?? 0,
        'description': _descriptionController.text.trim(),
        'previous_work': previousWorkList,
      };

      try {
        if (widget.isEditing && widget.onSave != null) {
          await widget.onSave!(data);
          Navigator.pop(context);
        } else {
          final response = await http.post(
            Uri.parse('$baseUrl/api/create_portfolio/'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'user_id': widget.userId,
              ...data,
            }),
          );

          if (response.statusCode == 201) {
            Navigator.pop(context);
          } else {
            final errorData = json.decode(response.body);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(errorData['error'] ?? 'Failed to create portfolio')),
            );
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Portfolio' : 'Create Portfolio'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _specialityController,
                decoration: InputDecoration(labelText: 'Speciality'),
                validator: (value) =>
                value!.isEmpty ? 'Please enter a speciality' : null,
              ),
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                value!.isEmpty ? 'Please enter a price' : null,
              ),
              TextFormField(
                controller: _experienceController,
                decoration: InputDecoration(labelText: 'Experience (years)'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                value!.isEmpty ? 'Please enter experience' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (value) =>
                value!.isEmpty ? 'Please enter a description' : null,
              ),
              SizedBox(height: 16),
              Text('Previous Work:', style: TextStyle(fontSize: 16)),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _previousWorkController,
                      decoration: InputDecoration(labelText: 'Add work item'),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add),
                    onPressed: _addPreviousWork,
                  ),
                ],
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: previousWorkList.length,
                itemBuilder: (context, index) => ListTile(
                  title: Text(previousWorkList[index]),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => _removePreviousWork(index),
                  ),
                ),
              ),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                child: _isSubmitting
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(widget.isEditing ? 'Update Portfolio' : 'Create Portfolio'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}