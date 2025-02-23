import 'package:flutter/material.dart';

class PaymentMethodsScreen extends StatefulWidget {
  @override
  _PaymentMethodsScreenState createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  List<Map<String, dynamic>> paymentMethods = [
    {
      "type": "Credit Card",
      "cardNumber": "**** **** **** 1234",
      "isDefault": true,
      "expiry": "12/25",
    },
    {
      "type": "UPI",
      "upiID": "john.doe@upi",
      "isDefault": false,
    },
  ];

  void _addNewPaymentMethod() {
    // Placeholder for adding a new payment method
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Add New Payment Method')),
    );
  }

  void _deletePaymentMethod(int index) {
    setState(() {
      paymentMethods.removeAt(index);
    });
  }

  void _setDefaultPaymentMethod(int index) {
    setState(() {
      for (int i = 0; i < paymentMethods.length; i++) {
        paymentMethods[i]['isDefault'] = i == index;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF4A90E2),
        title: Text('Payment Methods'),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: paymentMethods.length,
        itemBuilder: (context, index) {
          final method = paymentMethods[index];
          return Card(
            elevation: 4,
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: Icon(
                method['type'] == 'Credit Card' ? Icons.credit_card : Icons.account_balance_wallet,
                color: Color(0xFF4A90E2),
              ),
              title: Text(method['type'], style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(method['type'] == 'Credit Card'
                  ? '${method['cardNumber']} (Exp: ${method['expiry']})'
                  : method['upiID']),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (method['isDefault'])
                    Icon(Icons.check_circle, color: Colors.green), // ✅ Default Indicator
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'Delete') {
                        _deletePaymentMethod(index);
                      } else if (value == 'Set as Default') {
                        _setDefaultPaymentMethod(index);
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      if (!method['isDefault'])
                        PopupMenuItem(value: 'Set as Default', child: Text('Set as Default')),
                      PopupMenuItem(value: 'Delete', child: Text('Delete')),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewPaymentMethod,
        backgroundColor: Colors.green,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Icon(Icons.add, size: 28),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: PaymentMethodsScreen(),
  ));
}
