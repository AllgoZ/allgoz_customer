import 'package:allgoz/Account/Addresses/manage_adress.dart';
import 'package:allgoz/Home/home.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:allgoz/services/delivery_service.dart';
import 'dart:ui';
import 'package:intl/intl.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String selectedPaymentMethod = 'Cash on Delivery';
  double discount = 0;
  double deliveryCharge = 0;
  double packagingFee = 0;

  String? userPhoneNumber;
  List<Map<String, dynamic>> cartItems = [];

  @override
  void initState() {
    super.initState();
    _fetchUserPhoneNumber();
    _fetchPricingSettings();
  }

  void _fetchUserPhoneNumber() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && user.phoneNumber != null) {
      setState(() {
        userPhoneNumber = user.phoneNumber;
      });
    }
  }

  void _fetchPricingSettings() async {
    final doc = await FirebaseFirestore.instance
        .collection('pricingSettings')
        .doc('values')
        .get();

    if (doc.exists) {
      final data = doc.data();
      if (data != null) {
        setState(() {
          discount = (doc.data()?['discount'] ?? 0).toDouble();
          deliveryCharge = double.tryParse(data['deliveryCharge'].toString()) ?? 0;
          packagingFee = double.tryParse(data['packagingFee'].toString()) ?? 0;
        });
      }
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
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = screenWidth / 390;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A90E2),
        title: Text('Checkout',
            style: TextStyle(fontSize: 24 * scaleFactor, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0 * scaleFactor),
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
              return Center(
                  child: Text("Your cart is empty",
                      style: TextStyle(fontSize: 18 * scaleFactor)));
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
            double finalAmount = totalAmount - discount + deliveryCharge + packagingFee;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12 * scaleFactor)),
                        child: Padding(
                          padding: EdgeInsets.all(8.0 * scaleFactor),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Order Summary',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 22 * scaleFactor)),
                              ...cartItems.map((item) => ListTile(
                                leading: Image.network(
                                  item['imageURL'],
                                  width: 40 * scaleFactor,
                                  height: 40 * scaleFactor,
                                  fit: BoxFit.cover,
                                ),
                                title: Text(item['name'],
                                    style: TextStyle(
                                        fontSize: 18 * scaleFactor,
                                        fontWeight: FontWeight.w500)),
                                subtitle: Text(
                                    "${item['grams']}g x ${item['quantity']}",
                                    style: TextStyle(fontSize: 16 * scaleFactor)),
                                trailing: Text(
                                    '₹${item['price'] * item['quantity']}',
                                    style: TextStyle(
                                        fontSize: 18 * scaleFactor,
                                        fontWeight: FontWeight.bold)),
                              )),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 10 * scaleFactor),
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12 * scaleFactor)),
                        child: Column(
                          children: [
                            ListTile(
                              title: Text('Subtotal', style: TextStyle(fontSize: 18 * scaleFactor)),
                              trailing: Text('₹$totalAmount', style: TextStyle(fontSize: 18 * scaleFactor)),
                            ),
                            ListTile(
                              title: Text('Discount', style: TextStyle(fontSize: 18 * scaleFactor)),
                              trailing: Text('- ₹$discount', style: TextStyle(fontSize: 18 * scaleFactor)),
                            ),
                            ListTile(
                              title: Text('Delivery Charges', style: TextStyle(fontSize: 18 * scaleFactor)),
                              trailing: Text('₹$deliveryCharge', style: TextStyle(fontSize: 18 * scaleFactor)),
                            ),
                            ListTile(
                              title: Text('Packaging Fee', style: TextStyle(fontSize: 18 * scaleFactor)),
                              trailing: Text('₹$packagingFee', style: TextStyle(fontSize: 18 * scaleFactor)),
                            ),
                            const Divider(),
                            ListTile(
                              title: Text('Total',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20 * scaleFactor)),
                              trailing: Text('₹$finalAmount',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20 * scaleFactor)),
                            ),
                          ],
                        ),
                      )

                    ],
                  ),
                ),
                SizedBox(height: 10 * scaleFactor),
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
                      borderRadius: BorderRadius.circular(9 * scaleFactor),
                    ),
                    minimumSize: Size(double.infinity, 50 * scaleFactor),
                  ),
                  child: Text('Confirm',
                      style: TextStyle(
                          fontSize: 20 * scaleFactor,
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

class _DeliveryScreenState extends State<DeliveryScreen> with SingleTickerProviderStateMixin {
  List<String> paymentMethods = [];

  String selectedPaymentMethod = 'Cash on Delivery';
  String selectedDeliveryDay = 'Today';
  String? userUID;
  String? userPhoneNumber;
  String? customerName;
  String? selectedAddress;
  Map<String, dynamic>? addressDetails;

  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool isAfter9AM = false;
  bool isLoading = false; // 🔹 For full screen loader

  @override
  void initState() {
    super.initState();
    _checkDeliveryEligibility();
    _fetchUserDetails();
    _getCurrentLocation();

    _fetchPaymentMethods();

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
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      latitude = position.latitude;
      longitude = position.longitude;
    });
  }
  void _checkDeliveryEligibility() {
    final now = DateTime.now().toUtc().add(Duration(hours: 5, minutes: 30)); // IST
    final nineAM = DateTime(now.year, now.month, now.day, 9);
    setState(() {
      isAfter9AM = now.isAfter(nineAM);
      if (isAfter9AM) {
        selectedDeliveryDay = 'Tomorrow'; // Force set
      }
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
  }

  Future<void> _fetchPaymentMethods() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('CashOut')
        .doc('methods')
        .get();

    if (snapshot.exists) {
      setState(() {
        paymentMethods = snapshot.data()!.keys.toList();
      });
    }
  }



  void _placeOrder() async {
    if (userUID == null || userPhoneNumber == null || selectedAddress == null || addressDetails == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Please select or add an address."),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() => isLoading = true); // 🔹 Show loader

    await _updateDeliveryDetails();

    try {
      final result = await DeliveryService.checkDeliveryFeasibilityAndPlaceOrder(
        sellerUid: '344y6ZUTzuWRfjFMzR5mImLNAmt1',
        customerPhoneNumber: userPhoneNumber!,
        addressId: addressDetails!['id'] ?? 'default',
      );

      if (!result['success']) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.red,
        ));
        return;
      }

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
        'location': result['location'],
        'deliveryPartnerUid': result['deliveryPartnerUid'],
        'distances': result['distances'],
        'mapLinks': result['mapLinks'],

        // ✅ Delivery Partner Info
        'deliveryPartnerUid': result['deliveryPartnerUid'],
        'allDeliveryPartners': result['deliveryPartners'], // ✅ Save all nearby
      });

      final cartRef = FirebaseFirestore.instance
          .collection('customers')
          .doc(userPhoneNumber)
          .collection('cart');

      final cartItems = await cartRef.get();
      for (var doc in cartItems.docs) {
        await doc.reference.delete();
      }

      setState(() => isLoading = false); // 🔹 Hide loader

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
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Order failed: $e"),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scaleFactor = MediaQuery.of(context).size.width / 390;

    return Stack(
      children: [
        Scaffold(
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
                                ? Text(selectedAddress!, style: const TextStyle(fontSize: 18))
                                : const Text("No address found", style: TextStyle(fontSize: 18, color: Colors.red)),
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
                      _buildSelectionCard(
                        'Delivery Day',
                        isAfter9AM ? ['Tomorrow'] : ['Today', 'Tomorrow'],
                        selectedDeliveryDay,
                            (value) {
                          setState(() {
                            selectedDeliveryDay = value;
                            _updateDeliveryDetails();
                          });
                        },
                      ),
                      if (isAfter9AM)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "🕗 Your order will be delivered tomorrow morning at 7 - 8 AM.\n\n🕗 உங்கள் ஆர்டர் நாளை காலை 7 - 8 மணிக்கு டெலிவரி செய்யப்படும்.\n",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.orange[800],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "✅ Today delivery is available only for orders placed before 9 AM.\n\n✅ இன்று காலை 9 மணிக்கு முன் செய்யப்படும் ஆர்டர்களுக்கு மட்டுமே டெலிவரி கிடைக்கும்.",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),


                      const SizedBox(height: 20),
                  if (paymentMethods.isNotEmpty)
                  _buildSelectionCard('Payment Method', paymentMethods, selectedPaymentMethod, (value)
                        {
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
        ),

        // 🔹 iOS-Style Full Screen Blur Loader
        if (isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.6),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    SizedBox(height: 16),

                  ],
                ),
              ),
            ),
          ),

      ],
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
