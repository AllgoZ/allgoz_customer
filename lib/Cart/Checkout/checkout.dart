import 'package:allgoz/Account/Addresses/manage_adress.dart';
import 'package:allgoz/Home/home.dart';
import 'package:allgoz/services/delivery_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';



class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String selectedPaymentMethod = 'Cash on Delivery';
  String? userPhoneNumber;
  List<Map<String, dynamic>> cartItems = [];

  @override
  void initState() {
    super.initState();
    _fetchUserPhoneNumber();
  }

  void _fetchUserPhoneNumber() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && user.phoneNumber != null) {
      setState(() {
        userPhoneNumber = user.phoneNumber;
      });
    }
  }

  double calculateTotalAmount(List<Map<String, dynamic>> cartItems) {
    return cartItems.fold(
      0.0,
          (sum, item) => sum + ((item['price'] ?? 0) * (item['quantity'] ?? 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A90E2),
        title: const Text('Checkout',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: userPhoneNumber != null
              ? FirebaseFirestore.instance
              .collection('customers')
              .doc(userPhoneNumber)
              .collection('cart')
              .snapshots()
              : null,
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                  child: Text("Your cart is empty",
                      style: TextStyle(fontSize: 18)));
            }

            cartItems = snapshot.data!.docs.map((doc) {
              return {
                'id': doc.id,
                'name': doc['name'],
                'imageURL': doc['imageURL'],
                'price': doc['price'],
                'quantity': doc['quantity'],
                'unit': doc['unit'],
                'grams': doc['grams'] ?? 0,
              };
            }).toList();

            double totalAmount = calculateTotalAmount(cartItems);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Order Summary',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 22)),
                              ...cartItems.map((item) => ListTile(
                                leading: Image.network(item['imageURL'],
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover),
                                title: Text(item['name'],
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500)),
                                subtitle: Text(
                                    "${item['grams']}g x ${item['quantity']}",
                                    style: const TextStyle(fontSize: 18)),
                                trailing: Text(
                                    '₹${item['price'] * item['quantity']}',
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                              )),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          children: [
                            ListTile(
                              title: const Text('Subtotal',
                                  style: TextStyle(fontSize: 18)),
                              trailing: Text('₹$totalAmount',
                                  style: const TextStyle(fontSize: 18)),
                            ),
                            const ListTile(
                              title: Text('Discount',
                                  style: TextStyle(fontSize: 18)),
                              trailing: Text('- ₹0',
                                  style: TextStyle(fontSize: 18)),
                            ),
                            const ListTile(
                              title: Text('Delivery Charges',
                                  style: TextStyle(fontSize: 18)),
                              trailing: Text('Free',
                                  style: TextStyle(fontSize: 18)),
                            ),
                            const Divider(),
                            ListTile(
                              title: const Text('Total',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20)),
                              trailing: Text('₹$totalAmount',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              DeliveryScreen(cartItems: cartItems)),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Confirm',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}



class DeliveryScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;

  const DeliveryScreen({super.key, required this.cartItems});

  @override
  _DeliveryScreenState createState() => _DeliveryScreenState();

}
double? latitude;
double? longitude;

class _DeliveryScreenState extends State<DeliveryScreen>
    with SingleTickerProviderStateMixin {
  String selectedPaymentMethod = 'Cash on Delivery';
  String selectedDeliveryDay = 'Today';
  String? userUID;
  String? userPhoneNumber;
  String? customerName;
  String? selectedAddress;
  Map<String, dynamic>? addressDetails;

  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
    _getCurrentLocation();


    _controller = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _controller.forward();
  }
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      latitude = position.latitude;
      longitude = position.longitude;
    });
  }

  void _fetchUserDetails() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        userUID = user.uid;
        userPhoneNumber = user.phoneNumber;
      });

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('customers')
          .doc(userPhoneNumber)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        setState(() {
          customerName = userDoc['name'] ?? 'Unknown User';
        });

        String? defaultAddressId = userDoc['defaultAddress'];
        if (defaultAddressId != null) {
          DocumentSnapshot addressDoc = await FirebaseFirestore.instance
              .collection('customers')
              .doc(userPhoneNumber)
              .collection('addresses')
              .doc(defaultAddressId)
              .get();

          if (addressDoc.exists) {
            setState(() {
              addressDetails = addressDoc.data() as Map<String, dynamic>;
              selectedAddress =
              "${addressDetails!['house']}, ${addressDetails!['street']}, ${addressDetails!['city']}, ${addressDetails!['state']} - ${addressDetails!['pincode']}";
            });
          }
        }
      }

      /// ✅ Fetch previous Payment Method & Delivery Day
      DocumentSnapshot deliveryDoc = await FirebaseFirestore.instance
          .collection('customers')
          .doc(userPhoneNumber)
          .collection('deliveryDetails')
          .doc('details')
          .get();

      if (deliveryDoc.exists && deliveryDoc.data() != null) {
        Map<String, dynamic> data = deliveryDoc.data() as Map<String, dynamic>;
        setState(() {
          selectedPaymentMethod = data['paymentMethod'] ?? 'Cash on Delivery';
          selectedDeliveryDay = data['deliveryDay'] ?? 'Today';
        });
      }
    }
  }

  Future<void> _updateDeliveryDetails() async {
    if (userPhoneNumber == null || selectedAddress == null) return;

    await FirebaseFirestore.instance
        .collection('customers')
        .doc(userPhoneNumber)
        .collection('deliveryDetails')
        .doc('details')
        .set({
      'deliveryDay': selectedDeliveryDay,
      'paymentMethod': selectedPaymentMethod,
      'deliveryAddress': selectedAddress,
    });

    print("✅ Delivery details saved!");
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _placeOrder() async {
    if (userUID == null || userPhoneNumber == null || selectedAddress == null || addressDetails == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Please select or add an address."),
        backgroundColor: Colors.red,
      ));
      return;
    }

    await _updateDeliveryDetails(); // Save delivery preferences

    try {
      // ✅ Step 1: Delivery Partner Feasibility Check
      final result = await DeliveryService.checkDeliveryFeasibilityAndPlaceOrder(
        sellerUid: '344y6ZUTzuWRfjFMzR5mImLNAmt1', // Replace with actual seller UID
        customerPhoneNumber: userPhoneNumber!,
        addressId: addressDetails!['id'] ?? 'default',
      );

      if (!result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.red,
        ));
        return;
      }

      // ✅ Step 2: Generate unique order ID
      final todayStr = DateTime.now().toLocal().toString().substring(0, 10).replaceAll('-', '');
      final counterRef = FirebaseFirestore.instance.collection('orderCounter').doc(todayStr);
      final counterSnap = await counterRef.get();

      int counter = 1;
      if (counterSnap.exists) {
        counter = (counterSnap.data()?['count'] ?? 0) + 1;
      }
      await counterRef.set({'count': counter});

      final customOrderId = 'ORD-$todayStr-${counter.toString().padLeft(6, '0')}';
      final customerOrderRef = FirebaseFirestore.instance
          .collection('orders')
          .doc(userUID)
          .collection('orders')
          .doc(customOrderId);

      // ✅ Step 3: Store order
      await customerOrderRef.set({
        'orderId': customOrderId,
        'userPhoneNumber': userPhoneNumber,
        'customerName': customerName,
        'customerUID': userUID,
        'items': widget.cartItems,
        'totalAmount': widget.cartItems.fold<double>(
          0,
              (sum, item) => sum + (item['price'] * item['quantity']),
        ).toInt(),
        'paymentMethod': selectedPaymentMethod,
        'deliveryDay': selectedDeliveryDay,
        'deliveryAddress': selectedAddress,
        'status': 'New',
        'orderDate': Timestamp.now(),
        'updatedBy': 'customer',

        // ✅ Added new fields
        'location': result['location'],
        'deliveryPartnerUid': result['deliveryPartnerUid'],
        'distances': result['distances'],
        'mapLinks': result['mapLinks'], // ✅ MAP LINKS added here
      });

      // ✅ Step 4: Clear cart
      final cartRef = FirebaseFirestore.instance
          .collection('customers')
          .doc(userPhoneNumber)
          .collection('cart');

      final cartItems = await cartRef.get();
      for (var doc in cartItems.docs) {
        await doc.reference.delete();
      }

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Your order has been placed successfully!"),
        backgroundColor: Colors.green,
      ));

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
            (route) => false,
      );
    } catch (e) {
      print("❌ Error placing order: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Order failed: $e"),
        backgroundColor: Colors.red,
      ));
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A90E2),
        title: const Text('Delivery Details',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView(
                children: [
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        title: const Text('Delivery Address',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 20)),
                        subtitle: selectedAddress != null
                            ? Text(selectedAddress!,
                            style: const TextStyle(fontSize: 18))
                            : const Text("No address found",
                            style: TextStyle(fontSize: 18, color: Colors.red)),
                        trailing: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ManageAddressesScreen()),
                            ).then((_) {
                              _fetchUserDetails();
                            });
                          },
                          child: const Text('Add Address',
                              style: TextStyle(color: Colors.blue, fontSize: 16)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  /// 🔹 Delivery Day Selection
                  _buildSelectionCard('Delivery Day', ['Today', 'Tomorrow'], selectedDeliveryDay,
                          (value) {
                        setState(() {
                          selectedDeliveryDay = value;
                          _updateDeliveryDetails();
                        });
                      }),

                  const SizedBox(height: 20),

                  /// 🔹 Payment Method Selection
                  _buildSelectionCard('Payment Method',
                      ['Cash on Delivery', 'UPI', 'Credit/Debit Card'], selectedPaymentMethod,
                          (value) {
                        setState(() {
                          selectedPaymentMethod = value;
                          _updateDeliveryDetails();
                        });
                      }),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: _placeOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Place Order',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionCard(String title, List<String> options, String selectedValue, ValueChanged<String> onChanged) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: options
            .map((option) => RadioListTile(
          title: Text(option),
          value: option,
          groupValue: selectedValue,
          onChanged: (value) => onChanged(value!),
        ))
            .toList(),
      ),
    );
  }
}

