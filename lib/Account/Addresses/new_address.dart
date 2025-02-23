import 'package:flutter/material.dart';

class NewAddressScreen extends StatefulWidget {
  @override
  _NewAddressScreenState createState() => _NewAddressScreenState();
}

class _NewAddressScreenState extends State<NewAddressScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _townController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _altPhoneController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  String _addressType = 'Home'; // Default Address Type

  // ✅ Dummy location for now
  void _getCurrentLocation() {
    setState(() {
      _locationController.text = "Latitude: 12.9716, Longitude: 77.5946";
    });
  }

  void _saveAddress() {
    if (_formKey.currentState!.validate()) {
      // ✅ Collect the data without passing it anywhere for now
      final collectedData = {
        "name": _nameController.text.trim(),
        "town": _townController.text.trim(),
        "pincode": _pincodeController.text.trim(),
        "phone": _phoneController.text.trim(),
        "altPhone": _altPhoneController.text.trim(),
        "landmark": _landmarkController.text.trim(),
        "location": _locationController.text.trim(),
        "type": _addressType,
        "isDefault": false,
      };

      // ✅ Just for debugging to see data (can be removed later)
      print(collectedData);

      // ✅ Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Address saved successfully!')),
      );

      // ✅ Navigate back without passing data
      Navigator.pop(context);
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
                    _addressType = value ?? 'Home';
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Address Type',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                value == null || value.isEmpty ? "Please select an address type" : null,
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
