import 'package:allgoz/Account/Addresses/manage_adress.dart';
import 'package:allgoz/Home/home.dart';
import 'package:flutter/material.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String selectedPaymentMethod = 'Cash on Delivery';
  List<Map<String, dynamic>> cartItems = [
    {
      "name": "Spinach/பசலைக் கீரை",
      "image": "assets/product/fruits.png",
      "price": 30,
      "quantity": 2,
      "weight": "1 kg"
    },
    {
      "name": "Broccoli",
      "image": "assets/product/Broccoli.jpg",
      "price": 50,
      "quantity": 1,
      "weight": "500 g"
    },
    {
      "name": "Broccoli",
      "image": "assets/product/Broccoli.jpg",
      "price": 50,
      "quantity": 1,
      "weight": "500 g"
    },
    {
      "name": "Broccoli",
      "image": "assets/product/Broccoli.jpg",
      "price": 50,
      "quantity": 1,
      "weight": "500 g"
    },
    {
      "name": "Broccoli",
      "image": "assets/product/Broccoli.jpg",
      "price": 50,
      "quantity": 1,
      "weight": "500 g"
    },
    {
      "name": "Broccoli",
      "image": "assets/product/Broccoli.jpg",
      "price": 50,
      "quantity": 1,
      "weight": "500 g"
    },
  ];

  double get totalAmount {
    return cartItems.fold(0, (sum, item) => sum + (item['price'] * item['quantity']));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF4A90E2),
        title: Text('Checkout', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Order Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
                          ...cartItems.map((item) => ListTile(
                            leading: Image.asset(item['image'], width: 40, height: 40, fit: BoxFit.cover),
                            title: Text(item['name'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                            subtitle: Text('${item['weight']} x ${item['quantity']}', style: TextStyle(fontSize: 18)),
                            trailing: Text('₹${item['price'] * item['quantity']}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          )),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        ListTile(
                          title: Text('Subtotal', style: TextStyle(fontSize: 18)),
                          trailing: Text('₹$totalAmount', style: TextStyle(fontSize: 18)),
                        ),
                        ListTile(
                          title: Text('Discount', style: TextStyle(fontSize: 18)),
                          trailing: Text('- ₹0', style: TextStyle(fontSize: 18)),
                        ),
                        ListTile(
                          title: Text('Delivery Charges', style: TextStyle(fontSize: 18)),
                          trailing: Text('Free', style: TextStyle(fontSize: 18)),
                        ),
                        Divider(),
                        ListTile(
                          title: Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                          trailing: Text('₹$totalAmount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
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
                  MaterialPageRoute(builder: (context) => DeliveryScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
                minimumSize: Size(double.infinity, 50),
              ),
              child: Text('Confirm', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}





class DeliveryScreen extends StatefulWidget {
  @override
  _DeliveryScreenState createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> with SingleTickerProviderStateMixin {
  String selectedPaymentMethod = 'Cash on Delivery';
  String selectedDeliveryDay = 'Today';

  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // 🎬 Animation Setup
    _controller = AnimationController(
      duration: Duration(milliseconds: 2500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    // Trigger animation when screen loads
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF4A90E2),
        title: Text('Delivery Details', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
                  // ✅ Pop Animation for Delivery Address
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        title: Text('Delivery Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                        subtitle: Text('123 Main Street, City, Country', style: TextStyle(fontSize: 18)),
                        trailing: TextButton(
                          onPressed: () {

                            Navigator.push(context, MaterialPageRoute(builder: (context) => ManageAddressesScreen()));
                          },
                          child: Text('Change', style: TextStyle(color: Colors.blue, fontSize: 16)),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),

                  // 🚚 Delivery Day Section
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        ListTile(
                          title: Text('Delivery Day', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                        ),
                        _buildRadioOption('Today', selectedDeliveryDay, (value) {
                          setState(() => selectedDeliveryDay = value);
                        }),
                        _buildRadioOption('Tomorrow', selectedDeliveryDay, (value) {
                          setState(() => selectedDeliveryDay = value);
                        }),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),

                  // 💳 Payment Method Section
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        ListTile(
                          title: Text('Payment Method', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                        ),
                        _buildRadioOption('Cash on Delivery', selectedPaymentMethod, (value) {
                          setState(() => selectedPaymentMethod = value);
                        }),
                        _buildRadioOption('UPI', selectedPaymentMethod, (value) {
                          setState(() => selectedPaymentMethod = value);
                        }),
                        _buildRadioOption('Credit/Debit Card', selectedPaymentMethod, (value) {
                          setState(() => selectedPaymentMethod = value);
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 🛒 Place Order Button
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Your order has been placed!'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => HomePage()),
                      (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
                minimumSize: Size(double.infinity, 50),
              ),
              child: Text('Place Order', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // 🔘 Reusable Radio Button
  Widget _buildRadioOption(String title, String groupValue, ValueChanged<String> onChanged) {
    return ListTile(
      title: Text(title, style: TextStyle(fontSize: 16)),
      leading: Radio<String>(
        value: title,
        groupValue: groupValue,
        onChanged: (value) => onChanged(value!),
      ),
    );
  }
}
