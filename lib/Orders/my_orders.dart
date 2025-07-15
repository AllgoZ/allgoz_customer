import 'package:allgoz/Account/account.dart';
import 'package:allgoz/Cart/cart.dart';
import 'package:allgoz/Home/home.dart';
import 'package:allgoz/Orders/track_order.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  _MyOrdersScreenState createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  String selectedTab = 'Current Orders';
  String? userCustomerId;
  int _selectedIndex = 2; // Default to My Orders

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      final emailKey = user.email!.replaceAll('.', '_').replaceAll('@', '_');
      userCustomerId = 'google_$emailKey';
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePage()));
    } else if (index == 1) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => CartScreen()));
    } else if (index == 3) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AccountScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scaleFactor = MediaQuery.of(context).size.width / 390;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomePage()));
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF4A90E2),
          title: Text(
            'My Orders',
            style: TextStyle(fontSize: 20 * scaleFactor,color: Colors.white, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            SizedBox(height: 12 * scaleFactor),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTabButton('Current Orders', scaleFactor),
                _buildTabButton('Delivered Orders', scaleFactor),
              ],
            ),
            SizedBox(height: 10 * scaleFactor),
            Expanded(
              child: userCustomerId == null
                  ? const Center(child: CircularProgressIndicator())
                  : StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('orders')
                    .doc(userCustomerId)
                    .collection('orders')
                    .orderBy('orderDate', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data!.docs;
                  final orders = docs
                      .map((doc) => doc.data() as Map<String, dynamic>)
                      .where((order) => selectedTab == 'Current Orders'
                      ? order['status'] != 'Delivered'
                      : order['status'] == 'Delivered')
                      .toList();

                  if (orders.isEmpty) {
                    return Padding(
                      padding: EdgeInsets.all(24.0 * scaleFactor),
                      child: Text(
                        "No orders found.",
                        style: TextStyle(fontSize: 16 * scaleFactor),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      return _buildOrderCard(orders[index], scaleFactor);
                    },
                  );
                },
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          selectedItemColor: const Color(0xFF4A90E2),
          unselectedItemColor: Colors.grey,
          onTap: _onItemTapped,
          selectedFontSize: 14 * scaleFactor,
          unselectedFontSize: 12 * scaleFactor,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Cart'),
            BottomNavigationBarItem(icon: Icon(Icons.delivery_dining), label: 'My Order'),
            // BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String title, double scaleFactor) {
    return TextButton(
      onPressed: () {
        setState(() {
          selectedTab = title;
        });
      },
      style: TextButton.styleFrom(
        backgroundColor: selectedTab == title ? Colors.blue.shade100 : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: selectedTab == title ? Colors.blue : Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 16 * scaleFactor,
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, double scaleFactor) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.all(12 * scaleFactor),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(
          order['orderId'] ?? '',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16 * scaleFactor),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Date: ${order['orderDate'] != null ? (order['orderDate'] as Timestamp).toDate().toString().split(" ")[0] : "N/A"}',
              style: TextStyle(fontSize: 14 * scaleFactor),
            ),
            Text(
              'Status: ${order['status']}',
              style: TextStyle(color: Colors.green, fontSize: 14 * scaleFactor),
            ),
            Text(
              'Total: ₹${order['totalAmount']}',
              style: TextStyle(fontSize: 14 * scaleFactor),
            ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TrackCurrentOrderScreen(orderData: order),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
          ),
          child: Text(
            selectedTab == 'Current Orders' ? 'Track Order' : 'Order Again',
            style: TextStyle(fontSize: 14 * scaleFactor),
          ),
        ),
      ),
    );
  }
}
