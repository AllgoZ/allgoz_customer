import 'package:allgoz/Account/Addresses/edit_address.dart';
import 'package:allgoz/Account/Addresses/new_address.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ManageAddressesScreen extends StatefulWidget {
  @override
  _ManageAddressesScreenState createState() => _ManageAddressesScreenState();
}

class _ManageAddressesScreenState extends State<ManageAddressesScreen> {
  String? userCustomerId;
  String? defaultAddressId;

  @override
  void initState() {
    super.initState();
    _fetchUserCustomerId();
    _fetchDefaultAddress();
  }

  void _fetchUserCustomerId() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      setState(() {
        userCustomerId = 'google_${user.email!.replaceAll('.', '_').replaceAll('@', '_')}';
      });
    } else {
      print("❌ User not logged in or email is unavailable!");
    }
  }

  Future<void> _fetchDefaultAddress() async {
    if (userCustomerId == null) return;
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('customers')
        .doc(userCustomerId)
        .get();

    if (userDoc.exists) {
      setState(() {
        defaultAddressId = userDoc['defaultAddress'];
      });
    }
  }

  void _setDefaultAddress(String addressId) async {
    if (userCustomerId == null) return;

    await FirebaseFirestore.instance
        .collection('customers')
        .doc(userCustomerId)
        .update({'defaultAddress': addressId});

    setState(() {
      defaultAddressId = addressId;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Default address updated!")),
    );
  }

  void _deleteAddress(String addressId) async {
    if (userCustomerId == null) return;

    bool isDefault = addressId == defaultAddressId;

    await FirebaseFirestore.instance
        .collection('customers')
        .doc(userCustomerId)
        .collection('addresses')
        .doc(addressId)
        .delete();

    if (isDefault) {
      await FirebaseFirestore.instance
          .collection('customers')
          .doc(userCustomerId)
          .update({'defaultAddress': null});

      setState(() {
        defaultAddressId = null;
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Address deleted!")),
    );

    setState(() {});
  }

  void _editAddress(Map<String, dynamic> addressData, String addressId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditAddressScreen(addressId: addressId),
      ),
    ).then((updatedAddress) {
      if (updatedAddress != null) {
        FirebaseFirestore.instance
            .collection('customers')
            .doc(userCustomerId)
            .collection('addresses')
            .doc(addressId)
            .update(updatedAddress);
        _fetchDefaultAddress();
        setState(() {});
      }
    });
  }

  void _addNewAddress() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NewAddressScreen()),
    );
    await _fetchDefaultAddress();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final scaleFactor = MediaQuery.of(context).size.width / 390;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF4A90E2),
        title: Text(
          "Manage Addresses",
          style: TextStyle(
            fontSize: 20 * scaleFactor,
            color: Colors.white,
            // fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: userCustomerId == null
          ? Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('customers')
            .doc(userCustomerId)
            .collection('addresses')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var addresses = snapshot.data!.docs;

          if (addresses.isEmpty) {
            return Center(
              child: Text(
                "No addresses found. Add a new address!",
                style: TextStyle(fontSize: 16 * scaleFactor, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: addresses.length,
            itemBuilder: (context, index) {
              var address = addresses[index];
              var addressData = address.data() as Map<String, dynamic>;
              String addressId = address.id;
              bool isDefault = addressId == defaultAddressId;

              return Card(
                elevation: 4,
                margin: EdgeInsets.symmetric(
                  horizontal: 16 * scaleFactor,
                  vertical: 6 * scaleFactor,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12 * scaleFactor),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 5 * scaleFactor,
                    vertical: 5 * scaleFactor,
                  ),
                  leading: Icon(
                    addressData['type'] == 'Home'
                        ? Icons.home
                        : addressData['type'] == 'Work'
                        ? Icons.work
                        : Icons.location_on,
                    color: Color(0xFF4A90E2),
                    size: 26 * scaleFactor,
                  ),
                  title: Text(
                    addressData['type'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16 * scaleFactor,
                    ),
                  ),
                  subtitle: Text(
                    "${addressData['house']}, ${addressData['street']}, ${addressData['city']}, ${addressData['state']} - ${addressData['pincode']}",
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 14 * scaleFactor,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isDefault)
                        Icon(Icons.check_circle, color: Colors.green, size: 22 * scaleFactor),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == "Edit") {
                            _editAddress(addressData, addressId);
                          } else if (value == "Delete") {
                            _deleteAddress(addressId);
                          } else if (value == "Set Default") {
                            _setDefaultAddress(addressId);
                          }
                        },
                        itemBuilder: (BuildContext context) => [
                          PopupMenuItem(
                            value: "Edit",
                            child: Text("Edit", style: TextStyle(fontSize: 14 * scaleFactor)),
                          ),
                          PopupMenuItem(
                            value: "Delete",
                            child: Text("Delete", style: TextStyle(fontSize: 14 * scaleFactor)),
                          ),
                          if (!isDefault)
                            PopupMenuItem(
                              value: "Set Default",
                              child: Text("Set as Default", style: TextStyle(fontSize: 14 * scaleFactor)),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewAddress,
        backgroundColor: Colors.green,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12 * scaleFactor),
        ),
        child: Icon(Icons.add, size: 28 * scaleFactor),
      ),
    );
  }
}
