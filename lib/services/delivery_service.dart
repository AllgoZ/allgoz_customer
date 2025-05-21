import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class DeliveryService {
  static double _degToRad(double deg) => deg * pi / 180;

  static String generateMapLink(double lat, double lng) {
    return "https://www.google.com/maps/search/?api=1&query=$lat,$lng";
  }

  static String generateDirectionLink(double originLat, double originLng, double destLat, double destLng) {
    return 'https://www.google.com/maps/dir/?api=1'
        '&origin=$originLat,$originLng'
        '&destination=$destLat,$destLng'
        '&travelmode=driving';
  }

  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371; // in km
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) * cos(_degToRad(lat2)) *
            sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static Future<Map<String, dynamic>> checkDeliveryFeasibilityAndPlaceOrder({
    required String sellerUid,
    required String customerPhoneNumber,
    required String addressId,
  }) async {
    final firestore = FirebaseFirestore.instance;

    // Get seller location
    final sellerDoc = await firestore.collection('users').doc(sellerUid).get();
    final sellerLoc = sellerDoc.data()?['store']?['currentLocation'];
    if (sellerLoc == null) return {'success': false, 'message': 'Seller location missing'};

    // Get customer location
    final customerDoc = await firestore.collection('customers').doc(customerPhoneNumber).get();
    final defaultAddressId = customerDoc.data()?['defaultAddress'];

    final customerAddrDoc = await firestore
        .collection('customers')
        .doc(customerPhoneNumber)
        .collection('addresses')
        .doc(defaultAddressId)
        .get();

    final customerLocStr = customerAddrDoc.data()?['location'];
    if (customerLocStr == null) return {'success': false, 'message': 'Customer address location missing'};

    final latLngMatch = RegExp(r'Latitude:\s*([\d.]+),\s*Longitude:\s*([\d.]+)').firstMatch(customerLocStr);
    if (latLngMatch == null) return {'success': false, 'message': 'Invalid customer location format'};

    final customerLat = double.parse(latLngMatch.group(1)!);
    final customerLng = double.parse(latLngMatch.group(2)!);

    // Check seller to customer distance
    final sellerToCustomer = calculateDistance(
      sellerLoc['latitude'],
      sellerLoc['longitude'],
      customerLat,
      customerLng,
    );
    if (sellerToCustomer > 20)  //change back to 500
    {
      return {'success': false, 'message': 'Seller is too far from customer'};
    }

    // Get all delivery partners
    final deliveryPartnersSnap = await firestore.collection('delivery_partners').get();
    List<Map<String, dynamic>> availablePartners = [];

    for (final doc in deliveryPartnersSnap.docs) {
      final data = doc.data();
      final loc = data['location'];
      final isAvailable = data['isAvailable'] ?? false;

      if (loc == null || !isAvailable) continue;

      final sellerToPartner = calculateDistance(
          sellerLoc['latitude'], sellerLoc['longitude'],
          loc['latitude'], loc['longitude']
      );

      if (sellerToPartner <= 20) //change back to 500
      {
        final deliveryToCustomer = calculateDistance(
            loc['latitude'], loc['longitude'],
            customerLat, customerLng
        );

        availablePartners.add({
          'uid': doc.id,
          'location': {
            'latitude': loc['latitude'],
            'longitude': loc['longitude'],
          },
          'mapLink': generateMapLink(loc['latitude'], loc['longitude']),
          'distances': {
            'sellerToDelivery': sellerToPartner.toStringAsFixed(2),
            'deliveryToCustomer': deliveryToCustomer.toStringAsFixed(2),
          },
        });
      }
    }

    if (availablePartners.isEmpty) {
      return {'success': false, 'message': 'No delivery partner available nearby'};
    }

    // Choose the nearest partner (optional: can use more logic)
    availablePartners.sort((a, b) =>
        double.parse(a['distances']['sellerToDelivery']).compareTo(
            double.parse(b['distances']['sellerToDelivery'])
        ));

    final nearestPartner = availablePartners.first;

    return {
      'success': true,
      'deliveryPartnerUid': nearestPartner['uid'],
      'deliveryPartners': availablePartners,
      'location': {
        'latitude': customerLat,
        'longitude': customerLng,
      },
      'distances': {
        'sellerToCustomer': sellerToCustomer.toStringAsFixed(2),
      },
      'mapLinks': {
        'customer': generateMapLink(customerLat, customerLng),
        'seller': generateMapLink(sellerLoc['latitude'], sellerLoc['longitude']),
        'directions': {
          'sellerToCustomer': generateDirectionLink(
              sellerLoc['latitude'], sellerLoc['longitude'],
              customerLat, customerLng),
          'deliveryToSeller': generateDirectionLink(
              nearestPartner['location']['latitude'], nearestPartner['location']['longitude'],
              sellerLoc['latitude'], sellerLoc['longitude']),
          'deliveryToCustomer': generateDirectionLink(
              nearestPartner['location']['latitude'], nearestPartner['location']['longitude'],
              customerLat, customerLng),
        }
      }
    };
  }
}
