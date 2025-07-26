import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'package:allgoz/services/location_picker.dart';

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
  bool _isFetchingLocation = false;
  bool _isSavingAddress = false;
  loc.Location location = loc.Location();
  double? latitude;
  double? longitude;

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
        latitude = data['latitude'];
        longitude = data['longitude'];

        _addressType = data['type'] ?? 'Home';
      });
    }
  }

  void _getCurrentLocation() async {
    setState(() => _isFetchingLocation = true);
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
        _locationController.text =
        "Latitude: ${position.latitude}, Longitude: ${position.longitude}";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location fetched successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch location. Enable GPS!')),
      );
    } finally {
      setState(() => _isFetchingLocation = false);
    }
  }

  Future<bool> _showLocationBottomSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_off, size: 50, color: Colors.red),
            const SizedBox(height: 10),
            const Text(
              'Your device location is off',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Please enable location permission for better delivery experience',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              onPressed: () async {
                bool serviceEnabled = await location.requestService();
                if (serviceEnabled) {
                  Navigator.pop(context);
                }
              },
              child: const Text(
                'Continue',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );

    return await location.serviceEnabled();
  }

  Future<void> _selectDeliveryLocation() async {
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _showLocationBottomSheet();
      if (!serviceEnabled) return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return;
    }

    final LatLng? selected = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialLocation: latitude != null && longitude != null
              ? LatLng(latitude!, longitude!)
              : null,
        ),
      ),
    );

    if (selected != null) {
      setState(() {
        latitude = selected.latitude;
        longitude = selected.longitude;
        _locationController.text =
            'Latitude: ${latitude!.toStringAsFixed(5)}, Longitude: ${longitude!.toStringAsFixed(5)}';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location updated!')),
      );
    }
  }

  void _saveAddress() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSavingAddress = true);

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
        "latitude": latitude,
        "longitude": longitude,

        "type": _addressType,
      };

      await Future.delayed(Duration(seconds: 1)); // Optional fake delay

      if (mounted) {
        Navigator.pop(context, updatedAddress);
      }

      setState(() => _isSavingAddress = false);
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
              _buildTextField("Alternate Phone", _altPhoneController, scaleFactor, keyboardType: TextInputType.phone,optional: true),
              _buildTextField("House / Flat No", _houseController, scaleFactor),
              _buildTextField("Street & Locality", _streetController, scaleFactor),
              _buildTextField("Landmark (Optional)", _landmarkController, scaleFactor,optional: true),
              _buildTextField("City", _cityController, scaleFactor),
              _buildTextField("State", _stateController, scaleFactor,optional: true),
              _buildTextField("Pincode", _pincodeController, scaleFactor, keyboardType: TextInputType.number,optional: true),
              _buildTextField("Current Location", _locationController, scaleFactor, readOnly: true),

              SizedBox(height: 10 * scaleFactor),

              ElevatedButton(
                onPressed: _selectDeliveryLocation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(vertical: 14 * scaleFactor),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8 * scaleFactor)),
                ),
                child: Text("📍 Select on Map",
                    style: TextStyle(fontSize: 16 * scaleFactor, color: Colors.white)),
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
                child:ElevatedButton(
                  onPressed: _isSavingAddress ? null : _saveAddress,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(vertical: 14 * scaleFactor),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9 * scaleFactor)),
                  ),
                  child: _isSavingAddress
                      ? SizedBox(
                      width: 22 * scaleFactor,
                      height: 22 * scaleFactor,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text("Save Address",
                      style: TextStyle(fontSize: 18 * scaleFactor, color: Colors.white)),
                ),

              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      double scaleFactor,
      {TextInputType keyboardType = TextInputType
          .text, bool readOnly = false, bool optional = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0 * scaleFactor),
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
        style: TextStyle(fontSize: 16 * scaleFactor),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontSize: 14 * scaleFactor),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8 * scaleFactor)),
          contentPadding: EdgeInsets.symmetric(
              horizontal: 12 * scaleFactor, vertical: 10 * scaleFactor),
        ),
      ),
    );
  }
}