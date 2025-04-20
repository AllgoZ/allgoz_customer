import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'dart:io';

class TrackCurrentOrderScreen extends StatefulWidget {
  final Map<String, dynamic> orderData;
  const TrackCurrentOrderScreen({super.key, required this.orderData});

  @override
  State<TrackCurrentOrderScreen> createState() => _TrackCurrentOrderScreenState();
}

class _TrackCurrentOrderScreenState extends State<TrackCurrentOrderScreen> {
  Map<String, dynamic>? riderDetails;

  @override
  void initState() {
    super.initState();
    final order = widget.orderData;
    if (order['status'] == 'Accepted' && order['deliveryPartnerUid'] != null) {
      _fetchRiderDetails(order['deliveryPartnerUid']);
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

  void _makePhoneCall(String phoneNumber) async {
    if (Platform.isAndroid) {
      final intent = AndroidIntent(
        action: 'android.intent.action.DIAL',
        data: 'tel:$phoneNumber',
        flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
      );
      await intent.launch();
    } else {
      final Uri url = Uri.parse('tel:$phoneNumber');
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        throw 'Could not launch dialer';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentOrder = widget.orderData;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A90E2),
        title: const Text('Track Order'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Order #${currentOrder['orderId'] ?? ''}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text("Date: ${currentOrder['orderDate'] != null ? (currentOrder['orderDate'] as Timestamp).toDate().toString().split(" ")[0] : "N/A"}"),
            const Divider(),

            ...List<Widget>.from((currentOrder['items'] as List<dynamic>).map((item) {
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
              "Order Total: ₹${currentOrder['totalAmount'] ?? '--'}",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (currentOrder.containsKey('deliveryCharge'))
              Text(
                "Delivery Fee: ₹${currentOrder['deliveryCharge'] ?? '--'}",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),

            const Divider(),

            Text(
              "Status: ${currentOrder['status']}",
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

            if (currentOrder['status'] == 'Accepted' && currentOrder['mapLinks'] != null && currentOrder['mapLinks']['customer'] != null)
              ElevatedButton.icon(
                onPressed: () async {
                  final Uri mapUrl = Uri.parse(currentOrder['mapLinks']['customer']);
                  if (await canLaunchUrl(mapUrl)) {
                    await launchUrl(mapUrl);
                  }
                },
                icon: const Icon(Icons.map),
                label: const Text('View on Google Maps'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),

            const SizedBox(height: 15),

            if (currentOrder['status'] == 'Accepted' && riderDetails != null)
              ListTile(
                leading: const Icon(Icons.person, color: Colors.blue),
                title: Text('Rider: ${riderDetails!['fullName'] ?? 'N/A'}'),
                subtitle: Text('Phone: ${riderDetails!['phone'] ?? '--'}\nVehicle: ${riderDetails!['vehicleNumber'] ?? '--'}'),
                trailing: IconButton(
                  icon: const Icon(Icons.phone, color: Colors.green),
                  onPressed: () => _makePhoneCall(riderDetails!['phone']),
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}
