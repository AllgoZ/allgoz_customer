import 'package:allgoz/Account/Addresses/edit_address.dart';
import 'package:allgoz/Account/Addresses/new_address.dart';
import 'package:flutter/material.dart';

class ManageAddressesScreen extends StatefulWidget {
  @override
  _ManageAddressesScreenState createState() => _ManageAddressesScreenState();
}

class _ManageAddressesScreenState extends State<ManageAddressesScreen> {
  List<Map<String, dynamic>> addresses = [
    {
      "type": "Home",
      "address": "123, Main Street, City, Country",
      "isDefault": true,
    },
    {
      "type": "Work",
      "address": "456, Office Avenue, Business Park",
      "isDefault": false,
    },
  ];

  // ✅ Add New Address Function
  void _addNewAddress() {
    setState(() {
      addresses.add({
        "type": "New Address",
        "address": "789, New Road, Sample City",
        "isDefault": false,
      });
    });
  }

  // ✅ Delete Address Function
  void _deleteAddress(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete Address"),
        content: Text("Are you sure you want to delete this address?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                addresses.removeAt(index);
              });
              Navigator.pop(context);
            },
            child: Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ✅ Set Default Address Function
  void _setDefaultAddress(int index) {
    setState(() {
      for (int i = 0; i < addresses.length; i++) {
        addresses[i]['isDefault'] = i == index;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF4A90E2),
        title: Text("Manage Addresses"),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: addresses.length,
        itemBuilder: (context, index) {
          final address = addresses[index];
          return Card(
            elevation: 4,
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: Icon(
                address['type'] == 'Home'
                    ? Icons.home
                    : address['type'] == 'Work'
                    ? Icons.work
                    : Icons.location_on,
                color: Color(0xFF4A90E2),
              ),
              title: Text(address['type'], style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(address['address']),

              // ✅ Fixed the issue: Single trailing widget
              trailing: Row(
                mainAxisSize: MainAxisSize.min, // Keeps the row compact
                children: [
                  if (address['isDefault'])
                    Icon(Icons.check_circle, color: Colors.green), // ✅ Default Address Icon

                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == "Edit") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditAddressScreen(address: addresses[index]),
                          ),
                        );
                      } else if (value == "Delete") {
                        _deleteAddress(index);
                      } else if (value == "Set Default") {
                        _setDefaultAddress(index);
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      PopupMenuItem(value: "Edit", child: Text("Edit")),
                      PopupMenuItem(value: "Delete", child: Text("Delete")),
                      if (!address['isDefault'])
                        PopupMenuItem(value: "Set Default", child: Text("Set as Default")),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => NewAddressScreen()),
          ).then((newAddress) {
            if (newAddress != null) {
              setState(() {
                addresses.add(newAddress); // ✅ Add the new address to the list
              });
            }
          });
        },
        backgroundColor: Colors.green,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Icon(Icons.add, size: 28),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: ManageAddressesScreen(),
  ));
}
