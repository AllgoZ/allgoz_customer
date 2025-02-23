import 'package:allgoz/Orders/track_order.dart';
import 'package:flutter/material.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  _MyOrdersScreenState createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  String selectedTab = 'Current Orders';

  final List<Map<String, dynamic>> currentOrders = [
    {
      "orderId": "#67890",
      "date": "2024-05-22",
      "status": "Out for Delivery",
      "totalAmount": 200,
      "items": [
        {"name": "Cabbage", "quantity": 3, "price": 20, "image": "assets/product/fruits.png", "weight": "1 kg"}
      ]
    }
  ];

  final List<Map<String, dynamic>> deliveredOrders = [
    {
      "orderId": "#12345",
      "date": "2024-05-20",
      "status": "Delivered",
      "totalAmount": 150,
      "items": [
        {"name": "Spinach", "quantity": 2, "price": 30, "image": "assets/product/fruits.png", "weight": "1 kg"},
        {"name": "Broccoli", "quantity": 1, "price": 50, "image": "assets/product/Broccoli.jpg", "weight": "500 g"}
      ]
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF4A90E2),
        title: Text('My Orders'),
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
            child: ListView.builder(
              itemCount: selectedTab == 'Current Orders' ? currentOrders.length : deliveredOrders.length,
              itemBuilder: (context, index) {
                final order = selectedTab == 'Current Orders' ? currentOrders[index] : deliveredOrders[index];
                return _buildOrderCard(order);
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
      margin: EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(order['orderId'], style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date: ${order['date']}'),
            Text('Status: ${order['status']}', style: TextStyle(color: Colors.green)),
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
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: MyOrdersScreen(),
  ));
}
