import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class EditAddressScreen extends StatefulWidget {
  final Map<String, dynamic> address;

  EditAddressScreen({required this.address});

  @override
  _EditAddressScreenState createState() => _EditAddressScreenState();
}

class _EditAddressScreenState extends State<EditAddressScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _townController;
  late TextEditingController _pincodeController;
  late TextEditingController _phoneController;
  late TextEditingController _altPhoneController;
  late TextEditingController _landmarkController;
  late TextEditingController _locationController;

  String _addressType = 'Home';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.address['name'] ?? '');
    _townController = TextEditingController(text: widget.address['town'] ?? '');
    _pincodeController = TextEditingController(text: widget.address['pincode'] ?? '');
    _phoneController = TextEditingController(text: widget.address['phone'] ?? '');
    _altPhoneController = TextEditingController(text: widget.address['altPhone'] ?? '');
    _landmarkController = TextEditingController(text: widget.address['landmark'] ?? '');
    _locationController = TextEditingController(text: widget.address['location'] ?? '');
    _addressType = widget.address['type'] ?? 'Home';
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enable location services.")),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permission denied.")),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location permissions are permanently denied.")),
      );
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _locationController.text = "Latitude: ${position.latitude}, Longitude: ${position.longitude}";
    });
  }

  void _saveAddress() {
    if (_formKey.currentState!.validate()) {
      final updatedAddress = {
        "name": _nameController.text,
        "town": _townController.text,
        "pincode": _pincodeController.text,
        "phone": _phoneController.text,
        "altPhone": _altPhoneController.text,
        "landmark": _landmarkController.text,
        "location": _locationController.text,
        "type": _addressType,
      };
      Navigator.pop(context, updatedAddress);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _townController.dispose();
    _pincodeController.dispose();
    _phoneController.dispose();
    _altPhoneController.dispose();
    _landmarkController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF4A90E2),
        title: Text("Edit Address"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField("Full Name", _nameController),
              _buildTextField("Town/City", _townController),
              _buildTextField("Pincode", _pincodeController, keyboardType: TextInputType.number),
              _buildTextField("Phone Number", _phoneController, keyboardType: TextInputType.phone),
              _buildTextField("Alternate Phone", _altPhoneController, keyboardType: TextInputType.phone),
              _buildTextField("Landmark (Optional)", _landmarkController),
              _buildTextField("Current Location", _locationController, readOnly: true),

              ElevatedButton(
                onPressed: _getCurrentLocation,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text("Get Current Location"),
              ),

              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                value: _addressType,
                items: ['Home', 'Work', 'Other'].map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) => setState(() => _addressType = value!),
                decoration: const InputDecoration(
                  labelText: 'Address Type',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _saveAddress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                ),
                child: const Text("Save Address", style: TextStyle(fontSize: 18)),
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
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        validator: (value) => (value == null || value.isEmpty) ? 'Please enter $label' : null,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
