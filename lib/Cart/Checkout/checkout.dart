import 'package:allgoz/Account/Addresses/manage_adress.dart';
import 'package:allgoz/Home/home.dart';
import 'package:allgoz/services/youtube_player_widget.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:allgoz/services/delivery_service.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:allgoz/services/telegram_service.dart';
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String selectedPaymentMethod = 'Cash on Delivery';
  String? userCustomerId;
  List<Map<String, dynamic>> cartItems = [];

  @override
  void initState() {
    super.initState();
    _fetchUserCustomerId();
  }

  void _fetchUserCustomerId() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      setState(() {
        userCustomerId = 'google_${user.email!.replaceAll('.', '_').replaceAll('@', '_')}';
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
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = screenWidth / 390;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A90E2),
        title: Text('Checkout',
            style: TextStyle(fontSize: 24 * scaleFactor, color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0 * scaleFactor),
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('pricingSettings').doc('values').snapshots(),
          builder: (context, pricingSnapshot) {
            if (!pricingSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final pricingData = pricingSnapshot.data!.data() as Map<String, dynamic>? ?? {};
            final discount = double.tryParse(pricingData['discount'].toString()) ?? 0;
            final deliveryCharge = double.tryParse(pricingData['deliveryCharge'].toString()) ?? 0;
            final packagingFee = double.tryParse(pricingData['packagingFee'].toString()) ?? 0;

            return StreamBuilder<QuerySnapshot>(
              stream: userCustomerId != null
                  ? FirebaseFirestore.instance
                  .collection('customers')
                  .doc(userCustomerId)
                  .collection('cart')
                  .snapshots()
                  : null,
              builder: (context, cartSnapshot) {
                if (!cartSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (cartSnapshot.data!.docs.isEmpty) {
                  return Center(
                      child: Text("Your cart is empty",
                          style: TextStyle(fontSize: 18 * scaleFactor)));
                }

                cartItems = cartSnapshot.data!.docs.map((doc) {
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
                                  title: Text('Subtotal',
                                      style: TextStyle(fontSize: 18 * scaleFactor)),
                                  trailing: Text('₹$totalAmount',
                                      style: TextStyle(fontSize: 18 * scaleFactor)),
                                ),
                                ListTile(
                                  title: Text('Discount',
                                      style: TextStyle(fontSize: 18 * scaleFactor)),
                                  trailing: Text('- ₹$discount',
                                      style: TextStyle(fontSize: 18 * scaleFactor)),
                                ),
                                ListTile(
                                  title: Text('Delivery Charges',
                                      style: TextStyle(fontSize: 18 * scaleFactor)),
                                  trailing: Text('₹$deliveryCharge',
                                      style: TextStyle(fontSize: 18 * scaleFactor)),
                                ),
                                ListTile(
                                  title: Text('Packaging Fee',
                                      style: TextStyle(fontSize: 18 * scaleFactor)),
                                  trailing: Text('₹$packagingFee',
                                      style: TextStyle(fontSize: 18 * scaleFactor)),
                                ),
                                Divider(thickness: 1 * scaleFactor),
                                ListTile(
                                  title: Text('Total',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20 * scaleFactor)),
                                  trailing: Text('₹${finalAmount.toStringAsFixed(2)}',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20 * scaleFactor)),
                                ),
                              ],
                            ),
                          ),
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
                              fontSize: 20 * scaleFactor, color: Colors.white)),
                    ),
                  ],
                );
              },
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
  String? dynamicOrderMessage;
  String? dynamicNoteMessage;

  String selectedPaymentMethod = 'Cash on Delivery';
  String selectedDeliveryDay = 'Today';
  String? userUID;
  String? userCustomerId;
  String? customerName;
  String? selectedAddress;
  String? customerUniqueId; // 👈 Add this

  Map<String, dynamic>? addressDetails;

  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool isAfter9AM = false;
  bool isLoading = false; // 🔹 For full screen loader

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
    _getCurrentLocation();
    _fetchPaymentMethods();
    _fetchDeliveryMessages(); // ✅ Always fetch tomorrow’s message

    selectedDeliveryDay = 'Tomorrow'; // ✅ Always set to tomorrow
    _updateDeliveryDetails();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _controller.forward();
  }


  Future<void> _fetchDeliveryMessages() async {
    final doc = await FirebaseFirestore.instance
        .collection('DeliveryMessage')
        .doc('Message')
        .get();

    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final formattedTomorrow = DateFormat('dd/MM/yyyy').format(tomorrow);

      setState(() {
        dynamicOrderMessage = data['order'] ?? '';
        dynamicNoteMessage = data['note'] ?? '';
        // You can keep date separately if you want to use at end
        dynamicOrderMessage = "$dynamicOrderMessage\n🗓📌 $formattedTomorrow";
      });
    }
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

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      latitude = position.latitude;
      longitude = position.longitude;
    });
  }

  void _checkDeliveryEligibility() {
    final now = DateTime.now().toUtc().add(
        const Duration(hours: 5, minutes: 30)); // Convert to IST
    final nineAM = DateTime(now.year, now.month, now.day, 9);

    final isPast9AM = now.isAfter(nineAM);

    setState(() {
      isAfter9AM = isPast9AM;
      selectedDeliveryDay = isPast9AM ? 'Tomorrow' : 'Today';
    });

    _updateDeliveryDetails(); // ✅ Update Firestore with the auto-selected value
  }

  void _fetchUserDetails() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        userUID = user.uid;
        userCustomerId =
        'google_${user.email!.replaceAll('.', '_').replaceAll('@', '_')}';
      });

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('customers')
          .doc(userCustomerId)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data() as Map<String, dynamic>;

        setState(() {
          customerName = data['name'] ?? 'Unknown User';
          customerUniqueId = data['uniqueId']; // ✅ Now properly assigned to class variable
        });

        String? defaultAddressId = data['defaultAddress'];
        if (defaultAddressId != null) {
          DocumentSnapshot addressDoc = await FirebaseFirestore.instance
              .collection('customers')
              .doc(userCustomerId)
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
          .doc(userCustomerId)
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
    if (userCustomerId == null || selectedAddress == null) return;

    await FirebaseFirestore.instance
        .collection('customers')
        .doc(userCustomerId)
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
    if (userUID == null || userCustomerId == null || selectedAddress == null ||
        addressDetails == null || customerUniqueId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Please select or add an address."),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() => isLoading = true);

    final formattedToday = DateTime.now().toLocal().toString().substring(0, 10).replaceAll('-', '');
    final currentYear = DateTime.now().year.toString();
    final emailKey = FirebaseAuth.instance.currentUser!.email!
        .replaceAll('.', '_').replaceAll('@', '_');
    userCustomerId = 'google_$emailKey';

    final counterRef = FirebaseFirestore.instance
        .collection('orderCounter')
        .doc(customerUniqueId);

    final orderRef = FirebaseFirestore.instance
        .collection('orders')
        .doc(userCustomerId)
        .collection('orders');

    final nameRef = FirebaseFirestore.instance
        .collection('orders')
        .doc(userCustomerId);

    final cartRef = FirebaseFirestore.instance
        .collection('customers')
        .doc(userCustomerId)
        .collection('cart');

    final salesRef = FirebaseFirestore.instance
        .collection('product_sales')
        .doc('sales_count');

    try {
      // ⏱ Parallel execution
      final results = await Future.wait([
        _updateDeliveryDetails(),
        DeliveryService.checkDeliveryFeasibilityAndPlaceOrder(
          sellerUid: '344y6ZUTzuWRfjFMzR5mImLNAmt1',
          customerPhoneNumber: userCustomerId!,
          addressId: addressDetails!['id'] ?? 'default',
        ),
        counterRef.get(),
        salesRef.get(),
      ]);

      final result = results[1] as Map<String, dynamic>;
      final counterSnap = results[2] as DocumentSnapshot;
      final salesSnap = results[3] as DocumentSnapshot;

      if (!result['success']) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
        );
        return;
      }

      int counter = 1;
      if (counterSnap.exists) {
        final counterData = counterSnap.data() as Map<String, dynamic>? ?? {};
        counter = (counterData['count'] ?? 0) + 1;

      }

      final orderId = '$currentYear$customerUniqueId-${counter.toString().padLeft(4, '0')}';
      final orderDoc = orderRef.doc(orderId);

      // 🧾 Order Data
      final orderData = {
        'orderId': orderId,
        'userPhoneNumber': userCustomerId,
        'customerName': customerName,
        'customerUID': userUID,
        'mobileNumber': addressDetails!['phone'],
        'items': widget.cartItems,
        'totalAmount': widget.cartItems.fold<double>(
          0, (sum, item) => sum + (item['price'] * item['quantity']),
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
        'sellerid': '344y6ZUTzuWRfjFMzR5mImLNAmt1',
        'allDeliveryPartners': result['deliveryPartners'],
      };

      // 📈 Update product sales counts
      Map<String, dynamic> existingCounts = {};
      if (salesSnap.exists) {
        final salesData = salesSnap.data() as Map<String, dynamic>? ?? {};
        existingCounts = Map<String, dynamic>.from(salesData);

      }

      Map<String, dynamic> updatedCounts = {};
      for (var item in widget.cartItems) {
        final id = item['id'];
        final name = item['name'];
        final key = '${id}_$name';
        final qty = item['quantity'] ?? 1;
        final current = int.tryParse(existingCounts[key]?.toString() ?? '0') ?? 0;
        updatedCounts[key] = (current + qty).toString();
      }

      // 🧾 Batch write
      final batch = FirebaseFirestore.instance.batch();
      batch.set(orderDoc, orderData);
      batch.set(nameRef, {'name': customerName}, SetOptions(merge: true));
      batch.set(counterRef, {'count': counter});
      batch.set(salesRef, updatedCounts, SetOptions(merge: true));
      await batch.commit();
      TelegramService.sendOrderNotification(
        orderId: orderId,
        customerName: customerName ?? 'Unknown',
        deliveryAddress: selectedAddress ?? 'No Address',
        totalAmount: orderData['totalAmount'],
        cartItems: widget.cartItems,
      );


      // 🧹 Clear cart (non-blocking)
      FirebaseFirestore.instance.runTransaction((transaction) async {
        final cartItems = await cartRef.get();
        for (final doc in cartItems.docs) {
          transaction.delete(doc.reference);
        }
      });

      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Your order has been placed successfully!"), backgroundColor: Colors.green),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
            (route) => false,
      );
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Order failed: $e"), backgroundColor: Colors.red),
      );
    }
  }


  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    // final formattedTomorrow = "${_getWeekday(tomorrow.weekday)}, ${tomorrow.day} ${_getMonthName(tomorrow.month)}";
    final formattedTomorrow = DateFormat('d/MM/yyyy').format(tomorrow);

    final scaleFactor = MediaQuery
        .of(context)
        .size
        .width / 390;

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFF4A90E2),
            title: Text(
              'Delivery Details',
              style: TextStyle(
                fontSize: 24 * scaleFactor,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.video_collection_rounded, color: Colors.white),
                onPressed: () {
                  showDialog(
                    context: context,
                    barrierColor: Colors.transparent,
                    builder: (_) => const YoutubePlayerOverlay(fieldName: 'deliveryscreen'),
                  );
                },
              ),

            ],
          ),
          body: Padding(

            padding: EdgeInsets.all(16.0 * scaleFactor),
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
                            borderRadius: BorderRadius.circular(
                                12 * scaleFactor),
                          ),
                          child: ListTile(
                            title: Text(
                              'Delivery Address',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20 * scaleFactor,
                              ),
                            ),
                            subtitle: selectedAddress != null
                                ? Text(
                              selectedAddress!,
                              style: TextStyle(fontSize: 18 * scaleFactor),
                            )
                                : Text(
                              "No address found",
                              style: TextStyle(
                                fontSize: 18 * scaleFactor,
                                color: Colors.red,
                              ),
                            ),
                            trailing: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ManageAddressesScreen(),
                                  ),
                                ).then((_) {
                                  _fetchUserDetails();
                                });
                              },
                              child: Text(
                                'Add Address',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 16 * scaleFactor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20 * scaleFactor),
                      _buildSelectionCard(
                        'Delivery Day',
                        isAfter9AM ? ['Tomorrow'] : ['Tomorrow'],
                        selectedDeliveryDay,
                            (value) {
                          setState(() {
                            selectedDeliveryDay = value;
                            _updateDeliveryDetails();
                          });
                        },
                        scaleFactor,
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 10 * scaleFactor),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (dynamicOrderMessage != null && dynamicOrderMessage!.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.only(top: 10 * scaleFactor),
                                child: Text(
                                  dynamicOrderMessage!,
                                  style: TextStyle(
                                    fontSize: 16 * scaleFactor,
                                    color: Colors.orange[700],
                                    fontWeight: FontWeight.w600,
                                    height: 1.5, // spacing between lines
                                  ),
                                ),
                              ),
                            if (dynamicNoteMessage != null && dynamicNoteMessage!.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.only(top: 10 * scaleFactor),
                                child: Text(
                                  dynamicNoteMessage!,
                                  style: TextStyle(
                                    fontSize: 16 * scaleFactor,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[600],
                                    height: 1.4,
                                  ),
                                ),
                              ),

                          ],
                        ),
                      ),

                      SizedBox(height: 20 * scaleFactor),
                      if (paymentMethods.isNotEmpty)
                        _buildSelectionCard(
                          'Payment Method',
                          paymentMethods,
                          selectedPaymentMethod,
                              (value) {
                            setState(() {
                              selectedPaymentMethod = value;
                              _updateDeliveryDetails();
                            });
                          },
                          scaleFactor,
                        ),
                    ],
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _placeOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9 * scaleFactor),
                      ),
                      minimumSize: Size(double.infinity, 50 * scaleFactor),
                    ),
                    child: Text(
                      'Place Order',
                      style: TextStyle(
                        fontSize: 20 * scaleFactor,

                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
  String _getWeekday(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[(weekday - 1) % 7];
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  Widget _buildSelectionCard(String title, List<String> options,
      String selectedValue, ValueChanged<String> onChanged,
      double scaleFactor) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12 * scaleFactor)),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8 * scaleFactor),
        child: Column(
          children: options
              .map((option) =>
              RadioListTile(
                title: Text(
                    option, style: TextStyle(fontSize: 16 * scaleFactor)),
                value: option,
                groupValue: selectedValue,
                onChanged: (value) => onChanged(value!),
                contentPadding: EdgeInsets.symmetric(
                    horizontal: 4 * scaleFactor),
              ))
              .toList(),
        ),
      ),
    );
  }
}