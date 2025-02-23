import 'package:flutter/material.dart';

class TrackCurrentOrderScreen extends StatelessWidget {
  final Map<String, dynamic> currentOrder = {
    "orderId": "ORD12345",
    "date": "2024-04-20",
    "status": "Out for Delivery",
    "estimatedDelivery": "30 mins",
    "rider": {"name": "Ravi Kumar", "phone": "+91 98765 43210"},
    "items": [
      {"name": "Spinach", "quantity": 2, "price": 30, "weight": "1 kg"},
      {"name": "Broccoli", "quantity": 1, "price": 50, "weight": "500 g"},
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF4A90E2),
        title: Text('Track Order'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📝 Order Summary
            Text(
              "Order #${currentOrder['orderId']}",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text("Date: ${currentOrder['date']}"),
            Divider(),

            // 📦 Items List
            ...currentOrder['items'].map<Widget>((item) {
              return ListTile(
                leading: Icon(Icons.shopping_bag, color: Colors.blue),
                title: Text(item['name'], style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${item['weight']} x ${item['quantity']}'),
                trailing: Text('₹${item['price'] * item['quantity']}'),
              );
            }).toList(),
            Divider(),

            // 📍 Order Status & ETD
            Text(
              "Status: ${currentOrder['status']}",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            SizedBox(height: 5),
            Text(
              "Estimated Delivery: ${currentOrder['estimatedDelivery']}",
              style: TextStyle(fontSize: 16, color: Colors.orange),
            ),
            SizedBox(height: 10),

            // 🚚 Delivery Progress Indicator
            LinearProgressIndicator(
              value: 0.75, // Example progress (75%)
              backgroundColor: Colors.grey[300],
              color: Colors.green,
              minHeight: 8,
            ),
            SizedBox(height: 20),

            // 🗺️ Map Placeholder
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.black26),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map, size: 60, color: Colors.grey[700]),
                    SizedBox(height: 8),
                    Text(
                      'Map Placeholder',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 15),

            // 👤 Rider Information
            ListTile(
              leading: Icon(Icons.person, color: Colors.blue),
              title: Text('Rider: ${currentOrder['rider']['name']}'),
              subtitle: Text('Phone: ${currentOrder['rider']['phone']}'),
              trailing: IconButton(
                icon: Icon(Icons.phone, color: Colors.green),
                onPressed: () {
                  // Add call functionality here
                },
              ),
            ),

            Spacer(),

            // 🚨 Contact Support & Cancel Order Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Contact Support Functionality
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                    ),
                    child: Text('Contact Support', style: TextStyle(color: Colors.white)),
                  ),
                ),
                SizedBox(width: 10,),
                if (currentOrder['status'] != "Out for Delivery") // 🚫 Cancel only if not out for delivery
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Cancel Order Functionality
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                      ),
                      child: Text('Cancel Order', style: TextStyle(color: Colors.white)),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: TrackCurrentOrderScreen(),
  ));
}
