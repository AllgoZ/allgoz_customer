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
    final riderSnap = await FirebaseFirestore.instance.collection(
        'delivery_partners').doc(riderUid).get();
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
    final scaleFactor = MediaQuery
        .of(context)
        .size
        .width / 390; // Base width for scaling

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A90E2),
        title: Text('Track Order',
          style: TextStyle(
            fontSize: 20 * scaleFactor,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0 * scaleFactor),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Order #${currentOrder['orderId'] ?? ''}",
              style: TextStyle(
                  fontSize: 20 * scaleFactor, fontWeight: FontWeight.bold),
            ),
            Text(
              "Date: ${currentOrder['orderDate'] != null
                  ? (currentOrder['orderDate'] as Timestamp).toDate()
                  .toString()
                  .split(" ")[0]
                  : "N/A"}",
              style: TextStyle(fontSize: 14 * scaleFactor),
            ),
            Divider(thickness: 1 * scaleFactor),

            ...List<Widget>.from(
                (currentOrder['items'] as List<dynamic>).map((item) {
                  return ListTile(
                    contentPadding: EdgeInsets.symmetric(
                        vertical: 4 * scaleFactor, horizontal: 8 * scaleFactor),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(6 * scaleFactor),
                      child: Image.network(
                        item['imageURL'],
                        height: 50 * scaleFactor,
                        width: 50 * scaleFactor,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: Text(item['name'],
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16 * scaleFactor)),
                    subtitle: Text('${item['unit']} x ${item['quantity']}',
                        style: TextStyle(fontSize: 14 * scaleFactor)),
                    trailing: Text('₹${item['price'] * item['quantity']}',
                        style: TextStyle(fontSize: 14 * scaleFactor)),
                  );
                })),

            Divider(thickness: 1 * scaleFactor),

            Text(
              "Order Total: ₹${currentOrder['totalAmount'] ?? '--'}",
              style: TextStyle(
                  fontSize: 16 * scaleFactor, fontWeight: FontWeight.bold),
            ),
            if (currentOrder.containsKey('deliveryCharge'))
              Text(
                "Delivery Fee: ₹${currentOrder['deliveryCharge'] ?? '--'}",
                style: TextStyle(
                    fontSize: 16 * scaleFactor, fontWeight: FontWeight.bold),
              ),

            Divider(thickness: 1 * scaleFactor),

            Text(
              "Status: ${currentOrder['status']}",
              style: TextStyle(
                fontSize: 18 * scaleFactor,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            SizedBox(height: 5 * scaleFactor),

            Text(
              "Estimated Delivery: 7 - 8 AM",
              style: TextStyle(
                  fontSize: 16 * scaleFactor, color: Colors.orange),
            ),

            SizedBox(height: 10 * scaleFactor),

            LinearProgressIndicator(
              value: 0.75,
              backgroundColor: Colors.grey,
              color: Colors.green,
              minHeight: 8 * scaleFactor,
            ),

            SizedBox(height: 20 * scaleFactor),

            if (currentOrder['status'] == 'Accepted' &&
                currentOrder['mapLinks'] != null &&
                currentOrder['mapLinks']['customer'] != null)
              ElevatedButton.icon(
                onPressed: () async {
                  final Uri mapUrl = Uri.parse(
                      currentOrder['mapLinks']['customer']);
                  if (await canLaunchUrl(mapUrl)) {
                    await launchUrl(mapUrl);
                  }
                },
                icon: Icon(Icons.map, size: 20 * scaleFactor),
                label: Text('View on Google Maps',
                    style: TextStyle(fontSize: 16 * scaleFactor)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(vertical: 12 * scaleFactor),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10 * scaleFactor)),
                ),
              ),

            SizedBox(height: 15 * scaleFactor),

            if (currentOrder['status'] == 'Accepted' && riderDetails != null)
              ListTile(
                contentPadding: EdgeInsets.all(8 * scaleFactor),
                leading: Icon(
                    Icons.person, color: Colors.blue, size: 28 * scaleFactor),
                title: Text('Rider: ${riderDetails!['fullName'] ?? 'N/A'}',
                    style: TextStyle(fontSize: 16 * scaleFactor)),
                subtitle: Text(
                  'Phone: ${riderDetails!['phone'] ?? '--'}\nVehicle: ${riderDetails!['vehicleNumber'] ?? '--'}',
                  style: TextStyle(fontSize: 14 * scaleFactor),
                ),
                trailing: IconButton(
                  icon: Icon(
                      Icons.phone, color: Colors.green, size: 28 * scaleFactor),
                  onPressed: () => _makePhoneCall(riderDetails!['phone']),
                ),
              ),

            SizedBox(height: 22 * scaleFactor),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9 * scaleFactor),
                  ),
                  minimumSize: Size(double.infinity, 50 * scaleFactor),
                ),
                child: Text(
                  'Contact Support',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20 * scaleFactor,
                  ),
                ),
              ),
            ),

          ],
        ),
      ),

    );
  }
}