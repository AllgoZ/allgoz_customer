import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class TelegramService {
  static const String _botToken = '7855275566:AAHdaPbZkgt2aWa-4JFBuZr8cPRn8wEXXY4';
  static const String _chatId = '825518042';
  static final Set<String> _notifiedOrders = {};

  static Future<void> sendOrderNotification({
    required String orderId,
    required String customerName,
    required String deliveryAddress,
    required num totalAmount,
    required List<Map<String, dynamic>> cartItems,
  }) async {
    if (_notifiedOrders.contains(orderId)) return;
    _notifiedOrders.add(orderId);

    final StringBuffer itemDetails = StringBuffer();
    itemDetails.writeln('```\nItem                          Qty    Price   Total');
    itemDetails.writeln('-----------------------------------------------');

    for (var item in cartItems) {
      final name = (item['name'] ?? 'Unknown').toString().padRight(28).substring(0, 28);
      final quantity = item['grams'] ?? item['quantity'] ?? 0;
      final unit = item['unit'] ?? '';
      final price = item['price'] ?? 0;
      final total = item['totalAmount'] ?? 0;
      itemDetails.writeln(
        '${name.padRight(30)} ${quantity.toString().padRight(5)} ₹${price.toString().padRight(6)} ₹${total.toStringAsFixed(2)}',
      );
    }

    itemDetails.writeln('```');

    final String formattedTime =
    DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    final message = '''
🛒 *New Order Placed from Customer App!*

👤 *Customer:* $customerName
📍 *Address:* $deliveryAddress
💰 *Total Amount:* ₹$totalAmount
🆔 *Order ID:* $orderId
🕐 *Order Time:* $formattedTime

📦 *Items Ordered:*
${itemDetails.toString()}
''';

    final url = Uri.parse('https://api.telegram.org/bot$_botToken/sendMessage');

    try {
      final response = await http.post(url, body: {
        'chat_id': _chatId,
        'text': message,
        'parse_mode': 'Markdown',
      });

      if (response.statusCode != 200) {
        print('Telegram error: ${response.body}');
      }
    } catch (e) {
      print('Telegram send failed: $e');
    }
  }
}
