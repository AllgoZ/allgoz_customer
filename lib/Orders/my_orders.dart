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

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      final emailKey = user.email!.replaceAll('.', '_').replaceAll('@', '_');
      userCustomerId = 'google_$emailKey';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A90E2),
        title: const Text('My Orders'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTabButton('Current Orders'),
              _buildTabButton('Delivered Orders'),
            ],
          ),
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
                  return const Center(child: Text("No orders found."));
                }

                return ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    return _buildOrderCard(orders[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title) {
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
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(order['orderId'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date: ${order['orderDate'] != null ? (order['orderDate'] as Timestamp).toDate().toString().split(" ")[0] : "N/A"}'),
            Text('Status: ${order['status']}', style: const TextStyle(color: Colors.green)),
            Text('Total: ₹${order['totalAmount']}'),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TrackCurrentOrderScreen()),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9),
            ),
          ),
          child: Text(selectedTab == 'Current Orders' ? 'Track Order' : 'Order Again'),
        ),
      ),
    );
  }
}

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: MyOrdersScreen(),
  ));
}
