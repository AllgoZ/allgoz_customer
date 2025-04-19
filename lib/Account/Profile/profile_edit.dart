import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EditProfileScreen extends StatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _altPhoneController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  String _gender = 'Male';
  File? _profileImage;
  String? userCustomerId;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      final emailKey = user.email!.replaceAll('.', '_').replaceAll('@', '_');
      userCustomerId = 'google_$emailKey';
      final doc = await FirebaseFirestore.instance.collection('customers').doc(userCustomerId).get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _nameController.text = data['name'] ?? '';
          _emailController.text = data['email'] ?? user.email!;
          _phoneController.text = data['phone'] ?? '';
          _altPhoneController.text = data['altPhone'] ?? '';
          _dobController.text = data['dob'] ?? '';
          _gender = data['gender'] ?? 'Male';
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      if (userCustomerId != null) {
        await FirebaseFirestore.instance.collection('customers').doc(userCustomerId).update({
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'altPhone': _altPhoneController.text.trim(),
          'dob': _dobController.text.trim(),
          'gender': _gender,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile Updated Successfully')),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF4A90E2),
        title: Text('Edit Profile'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: _profileImage != null
                        ? FileImage(_profileImage!)
                        : AssetImage('assets/profile.png') as ImageProvider,
                  ),
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.blue),
                    onPressed: _pickImage,
                  ),
                ],
              ),
              SizedBox(height: 20),
              _buildTextField("Full Name", _nameController),
              _buildTextField("Email", _emailController, readOnly: true),
              _buildTextField("Phone Number", _phoneController, keyboardType: TextInputType.phone),
              _buildTextField("Alternate Phone", _altPhoneController, keyboardType: TextInputType.phone),
              GestureDetector(
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _dobController.text = "${pickedDate.toLocal()}".split(' ')[0];
                    });
                  }
                },
                child: AbsorbPointer(
                  child: _buildTextField("Date of Birth", _dobController),
                ),
              ),
              DropdownButtonFormField<String>(
                value: _gender,
                items: ['Male', 'Female', 'Other'].map((gender) {
                  return DropdownMenuItem(
                    value: gender,
                    child: Text(gender),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _gender = value!;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Gender',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                ),
                child: Text("Save Changes", style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text, bool readOnly = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        validator: (value) {
          if (!readOnly && (value == null || value.isEmpty)) {
            return 'Please enter $label';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: EditProfileScreen(),
  ));
}
