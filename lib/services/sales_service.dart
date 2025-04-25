import 'package:cloud_firestore/cloud_firestore.dart';

class SalesService {
  static Future<Map<String, int>> fetchTopSellingCounts() async {
    final doc = await FirebaseFirestore.instance
        .collection('product_sales')
        .doc('sales_count')
        .get();

    Map<String, int> salesMap = {};

    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;

      for (var entry in data.entries) {
        final fullKey = entry.key; // e.g., "uid_name"
        final uid = fullKey.split('_').first;

        final count = int.tryParse(entry.value.toString()) ?? 0;
        salesMap[uid] = (salesMap[uid] ?? 0) + count;
      }
    }

    return salesMap;
  }
}
