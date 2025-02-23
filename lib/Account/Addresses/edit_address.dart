import 'package:flutter/material.dart';

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

  String _addressType = 'Home'; // Default value for the dropdown

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

  void _getCurrentLocation() {
    // For demo purposes, using a dummy location
    setState(() {
      _locationController.text = "Latitude: 12.9716, Longitude: 77.5946";
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
      Navigator.pop(context, updatedAddress); // Pass the updated data back
    }
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
                child: Text("Get Current Location"),
              ),

              SizedBox(height: 10),

              // ✅ Address Type Dropdown
              DropdownButtonFormField<String>(
                value: _addressType,
                items: ['Home', 'Work', 'Other'].map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _addressType = value!;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Address Type',
                  border: OutlineInputBorder(),
                ),
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

  // 🔤 Text Field Builder
  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text, bool readOnly = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        validator: (value) {
          if (value == null || value.isEmpty) {
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
