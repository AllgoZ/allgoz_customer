import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class EditAddressScreen extends StatefulWidget {
  final String addressId;

  const EditAddressScreen({super.key, required this.addressId});

  @override
  _EditAddressScreenState createState() => _EditAddressScreenState();
}

class _EditAddressScreenState extends State<EditAddressScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _altPhoneController;
  late TextEditingController _houseController;
  late TextEditingController _streetController;
  late TextEditingController _landmarkController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _pincodeController;
  late TextEditingController _locationController;

  String _addressType = 'Home';

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _fetchAddressData();
  }

  void _initializeControllers() {
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _altPhoneController = TextEditingController();
    _houseController = TextEditingController();
    _streetController = TextEditingController();
    _landmarkController = TextEditingController();
    _cityController = TextEditingController();
    _stateController = TextEditingController();
    _pincodeController = TextEditingController();
    _locationController = TextEditingController();
  }

  Future<void> _fetchAddressData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return;

    final userCustomerId = 'google_${user.email!.replaceAll('.', '_').replaceAll('@', '_')}';

    final doc = await FirebaseFirestore.instance
        .collection('customers')
        .doc(userCustomerId)
        .collection('addresses')
        .doc(widget.addressId)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _nameController.text = data['name'] ?? '';
        _phoneController.text = data['phone'] ?? '';
        _altPhoneController.text = data['altPhone'] ?? '';
        _houseController.text = data['house'] ?? '';
        _streetController.text = data['street'] ?? '';
        _landmarkController.text = data['landmark'] ?? '';
        _cityController.text = data['city'] ?? '';
        _stateController.text = data['state'] ?? '';
        _pincodeController.text = data['pincode'] ?? '';
        _locationController.text = data['location'] ?? '';
        _addressType = data['type'] ?? 'Home';
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enable location services.")),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
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

    final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _locationController.text = "Latitude: ${position.latitude}, Longitude: ${position.longitude}";
    });
  }

  void _saveAddress() {
    if (_formKey.currentState!.validate()) {
      final updatedAddress = {
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
      };
      Navigator.pop(context, updatedAddress);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _altPhoneController.dispose();
    _houseController.dispose();
    _streetController.dispose();
    _landmarkController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scaleFactor = MediaQuery.of(context).size.width / 390;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A90E2),
        title: Text("Edit Address", style: TextStyle(fontSize: 20 * scaleFactor,color: Colors.white)),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0 * scaleFactor),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField("Full Name", _nameController, scaleFactor),
              _buildTextField("Phone Number", _phoneController, scaleFactor, keyboardType: TextInputType.phone),
              _buildTextField("Alternate Phone", _altPhoneController, scaleFactor, keyboardType: TextInputType.phone),
              _buildTextField("House / Flat No", _houseController, scaleFactor),
              _buildTextField("Street & Locality", _streetController, scaleFactor),
              _buildTextField("Landmark (Optional)", _landmarkController, scaleFactor),
              _buildTextField("City", _cityController, scaleFactor),
              _buildTextField("State", _stateController, scaleFactor),
              _buildTextField("Pincode", _pincodeController, scaleFactor, keyboardType: TextInputType.number),
              _buildTextField("Current Location", _locationController, scaleFactor, readOnly: true),

              SizedBox(height: 10 * scaleFactor),

              ElevatedButton(
                onPressed: _getCurrentLocation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(vertical: 14 * scaleFactor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8 * scaleFactor)),
                ),
                child: Text("Get Current Location", style: TextStyle(fontSize: 16 * scaleFactor, color: Colors.white)),
              ),

              SizedBox(height: 10 * scaleFactor),

              DropdownButtonFormField<String>(
                value: _addressType,
                items: ['Home', 'Work', 'Other'].map((type) {
                  return DropdownMenuItem(value: type, child: Text(type, style: TextStyle(fontSize: 14 * scaleFactor)));
                }).toList(),
                onChanged: (value) => setState(() => _addressType = value!),
                decoration: InputDecoration(
                  labelText: 'Address Type',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8 * scaleFactor)),
                ),
              ),

              SizedBox(height: 20 * scaleFactor),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveAddress,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(vertical: 14 * scaleFactor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9 * scaleFactor)),
                  ),
                  child: Text("Save Address", style: TextStyle(fontSize: 18 * scaleFactor, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, double scaleFactor,
      {TextInputType keyboardType = TextInputType.text, bool readOnly = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0 * scaleFactor),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        validator: (value) => (value == null || value.isEmpty) ? 'Please enter $label' : null,
        style: TextStyle(fontSize: 16 * scaleFactor),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontSize: 14 * scaleFactor),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8 * scaleFactor)),
          contentPadding: EdgeInsets.symmetric(horizontal: 12 * scaleFactor, vertical: 10 * scaleFactor),
        ),
      ),
    );
  }
}
