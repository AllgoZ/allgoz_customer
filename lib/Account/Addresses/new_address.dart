import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'package:allgoz/services/location_picker.dart';
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
  // final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  bool _isFetchingLocation = false;
  bool _isSavingAddress = false;

  loc.Location location = loc.Location();

  String _addressType = 'Home';
  bool _setAsDefault = true;
  double? latitude;
  double? longitude;

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

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LocationPickerScreen()),
    );

    if (result != null && result is LatLng) {
      setState(() {
        latitude = result.latitude;
        longitude = result.longitude;
        _locationController.text =
        'Latitude: ${latitude!.toStringAsFixed(5)}, Longitude: ${longitude!.toStringAsFixed(5)}';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location selected successfully!')),
      );
    }
  }


  Future<void> _saveAddress() async {
    if (_formKey.currentState!.validate()) {
      if (_locationController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please fetch your Delivery location by Clicking on Get Delivery Location button before saving.")),
        );
        return;
      }

      if (_isSavingAddress) return; // prevent double click

      setState(() => _isSavingAddress = true);
      try {
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
          // "pincode": _pincodeController.text.trim(),
          "location": _locationController.text.trim(),
          "type": _addressType,
          "isDefault": _setAsDefault,
        };

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
      } finally {
        setState(() => _isSavingAddress = false);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    final scaleFactor = screenWidth / 390;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A90E2),
        title: Text(
            "Add New Address", style: TextStyle(fontSize: 20 * scaleFactor, color: Colors.white
        )),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0 * scaleFactor),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField("Full Name", _nameController, scaleFactor),
              _buildTextField("Phone Number", _phoneController, scaleFactor,
                  keyboardType: TextInputType.phone),
              _buildTextField("Alternate Phone (Optional)", _altPhoneController,
                  scaleFactor, keyboardType: TextInputType.phone,
                  optional: true),
              _buildTextField("House/Flat No, Building Name", _houseController,
                  scaleFactor),
              _buildTextField(
                  "Street & Locality", _streetController, scaleFactor),
              _buildTextField(
                  "Landmark (Optional)", _landmarkController, scaleFactor,
                  optional: true),
              _buildTextField("City", _cityController, scaleFactor),
              // _buildTextField(
              //     "State", _stateController, scaleFactor, optional: true),
              // _buildTextField("Pincode", _pincodeController, scaleFactor,
              //     keyboardType: TextInputType.number, optional: true),
              _buildTextField(
                  "Current Location", _locationController, scaleFactor,
                  readOnly: true),

              SizedBox(height: 8 * scaleFactor),

              ElevatedButton(
                onPressed: _selectDeliveryLocation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(vertical: 14 * scaleFactor),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8 * scaleFactor)),
                ),
                child: Text("📍 Select Delivery Location",
                    style: TextStyle(fontSize: 16 * scaleFactor, color: Colors.white)),
              ),


              SizedBox(height: 10 * scaleFactor),

              DropdownButtonFormField<String>(
                value: _addressType,
                items: ['Home', 'Work', 'Other'].map((type) {
                  return DropdownMenuItem(
                      value: type, child: Text(type, style: TextStyle(
                      fontSize: 14 * scaleFactor)));
                }).toList(),
                onChanged: (value) => setState(() => _addressType = value!),
                decoration: InputDecoration(
                  labelText: 'Address Type',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8 * scaleFactor)),
                ),
              ),

              SwitchListTile(
                title: Text("Set as Default Address",
                    style: TextStyle(fontSize: 14 * scaleFactor)),
                value: _setAsDefault,
                onChanged: (value) {
                  setState(() {
                    _setAsDefault = value;
                  });
                },
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
          if (label.contains('Phone') && value != null && value.isNotEmpty && value.length != 10) {
            return 'Please enter a valid 10-digit mobile number';
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