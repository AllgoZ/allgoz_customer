import 'package:cloud_firestore/cloud_firestore.dart';

/// Normalizes a product category string for comparison.
/// - Trims spaces and converts to lowercase.
/// - Maps singular/plural variations to a standard value.
String normalizeCategory(String category) {
  final normalized = category.trim().toLowerCase();
  if (normalized == 'grocery' || normalized == 'groceries') {
    return 'groceries';
  }
  if (normalized == 'fruit' || normalized == 'fruits') {
    return 'fruits';
  }
  if (normalized == 'vegetable' || normalized == 'vegetables') {
    return 'vegetables';
  }
  return normalized;
}

/// Returns `true` if the provided [now] (device local) time is before the
/// given [hour] and [minute] in IST (Asia/Kolkata).
bool isISTBefore(DateTime now, int hour, int minute) {
  final istNow = now.toUtc().add(const Duration(hours: 5, minutes: 30));
  final threshold = DateTime(istNow.year, istNow.month, istNow.day, hour, minute);
  return istNow.isBefore(threshold);
}

/// Determines whether the cart contains any vegetables.
bool hasVegetables(List<String> categories) {
  return categories.map(normalizeCategory).contains('vegetables');
}

/// Determines whether the cart contains any fruits or groceries.
bool hasFruitsOrGroceries(List<String> categories) {
  final normalized = categories.map(normalizeCategory).toSet();
  return normalized.contains('fruits') || normalized.contains('groceries');
}

/// Internal enum to represent delivery day choice.
enum _DeliveryDay { today, tomorrow }

/// Computes delivery day for vegetables based on time window.
_DeliveryDay _vegetableRule(DateTime now) {
  return isISTBefore(now, 8, 0) ? _DeliveryDay.today : _DeliveryDay.tomorrow;
}

/// Computes delivery day for fruits/groceries based on time window.
_DeliveryDay _groceryRule(DateTime now) {
  return isISTBefore(now, 16, 0) ? _DeliveryDay.today : _DeliveryDay.tomorrow;
}

/// Builds a multi-line delivery message for the given [cartCategories].
///
/// The Firestore document `DeliveryMessage/Message` can contain the following
/// optional fields:
///   - `today` : message for orders delivered today
///   - `tomorrow` : message for orders delivered tomorrow
///   - `order` : legacy fallback for `tomorrow`
///   - `note` : legacy vegetable note
///   - `noteVeg` : vegetable specific note
///   - `noteGroceries` : groceries/fruits specific note
///
/// The function is backward compatible with legacy data. If `today` is missing
/// a default message is used. If `tomorrow` is missing, `order` is used instead.
Future<String> buildDeliveryMessage({
  required List<String> cartCategories,
  required FirebaseFirestore firestore,
  DateTime? now,
}) async {
  final current = now ?? DateTime.now();
  final normalized = cartCategories.map(normalizeCategory).toList();
  final veg = hasVegetables(normalized);
  final fg = hasFruitsOrGroceries(normalized);

  // Fetch Firestore messages once
  final doc = await firestore.collection('DeliveryMessage').doc('Message').get();
  final data = doc.data() ?? {};

  final todayText = (data['today'] as String?) ??
      '🕗 Your order will be delivered today between 6 – 8 PM.';
  final tomorrowText = (data['tomorrow'] as String?) ??
      (data['order'] as String?) ??
      '🕗 Your order will be delivered tomorrow between 6 – 8 PM.';
  final note = data['note'] as String?;
  final noteVeg = data['noteVeg'] as String?;
  final noteGroceries = data['noteGroceries'] as String?;

  final buffer = StringBuffer();

  if (veg && !fg) {
    final day = _vegetableRule(current);
    buffer.write(day == _DeliveryDay.today ? todayText : tomorrowText);
  } else if (!veg && fg) {
    final day = _groceryRule(current);
    buffer.write(day == _DeliveryDay.today ? todayText : tomorrowText);
  } else if (veg && fg) {
    final vegDay = _vegetableRule(current);
    buffer.writeln('🥬 Vegetables — '
        '${vegDay == _DeliveryDay.today ? todayText : tomorrowText}');
    final groceryDay = _groceryRule(current);
    buffer.write('🛒 Groceries/Fruits — '
        '${groceryDay == _DeliveryDay.today ? todayText : tomorrowText}');
  }

  final notes = <String>{};
  if (veg) {
    if (noteVeg != null && noteVeg.isNotEmpty) notes.add(noteVeg);
    if (note != null && note.isNotEmpty) notes.add(note);
  }
  if (fg) {
    if (noteGroceries != null && noteGroceries.isNotEmpty) {
      notes.add(noteGroceries);
    }
  }

  if (notes.isNotEmpty) {
    if (buffer.isNotEmpty) buffer.write('\n');
    buffer.writeAll(notes, '\n');
  }

  return buffer.toString();
}

/*
Example integration in checkout flow:

final message = await buildDeliveryMessage(
  cartCategories: cartItems.map((e) => e['category'] as String).toList(),
  firestore: FirebaseFirestore.instance,
);

setState(() => dynamicOrderMessage = message);
...
Text(dynamicOrderMessage ?? '');
*/
