import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TrackCurrentOrderScreen extends StatefulWidget {
  const TrackCurrentOrderScreen({super.key});

  @override
  State<TrackCurrentOrderScreen> createState() => _TrackCurrentOrderScreenState();
}

class _TrackCurrentOrderScreenState extends State<TrackCurrentOrderScreen> {
  Map<String, dynamic>? currentOrder;
  String? userCustomerId;
  Map<String, dynamic>? riderDetails;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      final emailKey = user.email!.replaceAll('.', '_').replaceAll('@', '_');
      userCustomerId = 'google_$emailKey';
      _fetchLatestOrder();
    }
  }

  Future<void> _fetchLatestOrder() async {
    if (userCustomerId == null) return;
    final snapshot = await FirebaseFirestore.instance
        .collection('orders')
        .doc(userCustomerId)
        .collection('orders')
        .orderBy('orderDate', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final orderData = snapshot.docs.first.data();
      setState(() {
        currentOrder = orderData;
      });

      if (orderData['status'] == 'Accepted' && orderData['deliveryPartnerUid'] != null) {
        _fetchRiderDetails(orderData['deliveryPartnerUid']);
      }
    }
  }

  Future<void> _fetchRiderDetails(String riderUid) async {
    final riderSnap = await FirebaseFirestore.instance.collection('delivery_partners').doc(riderUid).get();
    if (riderSnap.exists && riderSnap.data() != null) {
      setState(() {
        riderDetails = riderSnap.data();
      });
    }
  }

  Future<void> _cancelOrder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Cancellation'),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes')),
        ],
      ),
    );

    if (confirm != true) return;

    if (userCustomerId == null || currentOrder == null) return;
    final orderId = currentOrder!['orderId'];
    await FirebaseFirestore.instance
        .collection('orders')
        .doc(userCustomerId)
        .collection('orders')
        .doc(orderId)
        .update({'status': 'User_Cancelled'});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Order cancelled successfully.')),
    );

    _fetchLatestOrder();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A90E2),
        title: const Text('Track Order'),
        centerTitle: true,
      ),
      body: currentOrder == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Order #${currentOrder!['orderId'] ?? ''}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text("Date: ${currentOrder!['orderDate'] != null ? (currentOrder!['orderDate'] as Timestamp).toDate().toString().split(" ")[0] : "N/A"}"),
            const Divider(),

            ...List<Widget>.from((currentOrder!['items'] as List<dynamic>).map((item) {
              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(item['imageURL'], height: 50, width: 50, fit: BoxFit.cover),
                ),
                title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${item['unit']} x ${item['quantity']}'),
                trailing: Text('₹${item['price'] * item['quantity']}'),
              );
            })),

            const Divider(),

            Text(
              "Order Total: ₹${currentOrder!['totalAmount'] ?? '--'}",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (currentOrder!.containsKey('deliveryCharge'))
              Text(
                "Delivery Fee: ₹${currentOrder!['deliveryCharge'] ?? '--'}",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),

            const Divider(),

            Text(
              "Status: ${currentOrder!['status']}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            const SizedBox(height: 5),

            const Text(
              "Estimated Delivery: 7 - 8 AM",
              style: TextStyle(fontSize: 16, color: Colors.orange),
            ),

            const SizedBox(height: 10),

            const LinearProgressIndicator(
              value: 0.75,
              backgroundColor: Colors.grey,
              color: Colors.green,
              minHeight: 8,
            ),
            const SizedBox(height: 20),

            Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.black26),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map, size: 60, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('Map Placeholder',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 15),

            if (currentOrder!['status'] == 'Accepted' && riderDetails != null)
              ListTile(
                leading: const Icon(Icons.person, color: Colors.blue),
                title: Text('Rider: ${riderDetails!['name'] ?? 'N/A'}'),
                subtitle: Text('Phone: ${riderDetails!['phone'] ?? '--'}\nVehicle: ${riderDetails!['vehicleNumber'] ?? '--'}'),
                trailing: IconButton(
                  icon: const Icon(Icons.phone, color: Colors.green),
                  onPressed: () {},
                ),
              ),

            const Spacer(),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                    ),
                    child: const Text('Contact Support', style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: (currentOrder!['status'] == 'New' || currentOrder!['status'] == 'Confirmed')
                        ? _cancelOrder
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (currentOrder!['status'] == 'New' || currentOrder!['status'] == 'Confirmed')
                          ? Colors.red
                          : Colors.grey,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                    ),
                    child: const Text('Cancel Order', style: TextStyle(color: Colors.white)),
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
