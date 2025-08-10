import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:allgoz/services/delivery_message_builder.dart';

void main() {
  group('buildDeliveryMessage', () {
    late FakeFirebaseFirestore firestore;

    setUp(() async {
      firestore = FakeFirebaseFirestore();
      await firestore.collection('DeliveryMessage').doc('Message').set({
        'today': 'today msg',
        'tomorrow': 'tomorrow msg',
        'noteVeg': 'veg note',
        'noteGroceries': 'groceries note',
      });
    });

    test('Vegetables before 8am -> today', () async {
      final message = await buildDeliveryMessage(
        cartCategories: ['Vegetables'],
        firestore: firestore,
        now: DateTime(2024, 1, 1, 7, 55),
      );
      expect(message.contains('today msg'), isTrue);
    });

    test('Vegetables after 8am -> tomorrow', () async {
      final message = await buildDeliveryMessage(
        cartCategories: ['Vegetables'],
        firestore: firestore,
        now: DateTime(2024, 1, 1, 9, 10),
      );
      expect(message.contains('tomorrow msg'), isTrue);
    });

    test('Groceries before 4pm -> today', () async {
      final message = await buildDeliveryMessage(
        cartCategories: ['Groceries'],
        firestore: firestore,
        now: DateTime(2024, 1, 1, 15, 10),
      );
      expect(message.contains('today msg'), isTrue);
    });

    test('Groceries after 4pm -> tomorrow', () async {
      final message = await buildDeliveryMessage(
        cartCategories: ['Groceries'],
        firestore: firestore,
        now: DateTime(2024, 1, 1, 16, 1),
      );
      expect(message.contains('tomorrow msg'), isTrue);
    });

    test('Mixed cart morning', () async {
      final message = await buildDeliveryMessage(
        cartCategories: ['Fruits', 'Vegetables'],
        firestore: firestore,
        now: DateTime(2024, 1, 1, 9, 30),
      );
      expect(message.contains('🥬 Vegetables — tomorrow msg'), isTrue);
      expect(message.contains('🛒 Groceries/Fruits — today msg'), isTrue);
    });

    test('Mixed cart evening', () async {
      final message = await buildDeliveryMessage(
        cartCategories: ['Fruits', 'Vegetables'],
        firestore: firestore,
        now: DateTime(2024, 1, 1, 17, 30),
      );
      expect(message.contains('🥬 Vegetables — tomorrow msg'), isTrue);
      expect(message.contains('🛒 Groceries/Fruits — tomorrow msg'), isTrue);
    });
  });
}
