import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class NewAddressScreen extends StatefulWidget {
  @override
  _NewAddressScreenState createState() => _NewAddressScreenState();
}

class _NewAddressScreenState extends State<NewAddressScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _altPhoneController = TextEditingController();
  final TextEditingController _houseController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  String _addressType = 'Home';
  bool _setAsDefault = false;

  void _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          await Geolocator.openAppSettings();
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _locationController.text = "Latitude: ${position.latitude}, Longitude: ${position.longitude}";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location fetched successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch location. Enable GPS!')),
      );
    }
  }

  Future<void> _saveAddress() async {
    if (_formKey.currentState!.validate()) {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("User not logged in!")),
        );
        return;
      }

      final emailKey = user.email!.replaceAll('.', '_').replaceAll('@', '_');
      String userCustomerId = 'google_$emailKey';

      Map<String, dynamic> addressData = {
        "name": _nameController.text.trim(),
        "phone": _phoneController.text.trim(),
        "altPhone": _altPhoneController.text.trim(),
        "house": _houseController.text.trim(),
        "street": _streetController.text.trim(),
        "landmark": _landmarkController.text.trim(),
        "city": _cityController.text.trim(),
        "state": _stateController.text.trim(),
        "pincode": _pincodeController.text.trim(),
        "location": _locationController.text.trim(),
        "type": _addressType,
        "isDefault": _setAsDefault,
      };

      try {
        DocumentReference newAddressRef = FirebaseFirestore.instance
            .collection('customers')
            .doc(userCustomerId)
            .collection('addresses')
            .doc();

        await newAddressRef.set(addressData);

        if (_setAsDefault) {
          await FirebaseFirestore.instance
              .collection('customers')
              .doc(userCustomerId)
              .update({"defaultAddress": newAddressRef.id});
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Address saved successfully!")),
        );

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving address: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF4A90E2),
        title: Text("Add New Address"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField("Full Name", _nameController),
              _buildTextField("Phone Number", _phoneController, keyboardType: TextInputType.phone),
              _buildTextField("Alternate Phone (Optional)", _altPhoneController, keyboardType: TextInputType.phone, optional: true),
              _buildTextField("House/Flat No, Building Name", _houseController),
              _buildTextField("Street & Locality", _streetController),
              _buildTextField("Landmark (Optional)", _landmarkController, optional: true),
              _buildTextField("City", _cityController),
              _buildTextField("State", _stateController, optional: true),
              _buildTextField("Pincode", _pincodeController, keyboardType: TextInputType.number, optional: true),

              _buildTextField("Current Location", _locationController, readOnly: true),
              ElevatedButton(
                onPressed: _getCurrentLocation,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: Text("Get Current Location"),
              ),

              SizedBox(height: 10),

              DropdownButtonFormField<String>(
                value: _addressType,
                items: ['Home', 'Work', 'Other'].map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) => setState(() => _addressType = value!),
                decoration: InputDecoration(labelText: 'Address Type', border: OutlineInputBorder()),
              ),

              SwitchListTile(
                title: Text("Set as Default Address"),
                value: _setAsDefault,
                onChanged: (value) {
                  setState(() {
                    _setAsDefault = value;
                  });
                },
              ),

              SizedBox(height: 20),

              ElevatedButton(
                onPressed: _saveAddress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                ),
                child: Text("Save Address", style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text, bool readOnly = false, bool optional = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        validator: (value) {
          if (!readOnly && !optional && (value == null || value.isEmpty)) {
            return 'Please enter $label';
          }
          return null;
        },
        decoration: InputDecoration(labelText: label, border: OutlineInputBorder()),
      ),
    );
  }
}
