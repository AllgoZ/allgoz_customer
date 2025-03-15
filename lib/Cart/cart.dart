import 'package:allgoz/Account/account.dart';
import 'package:allgoz/Cart/Checkout/checkout.dart';
import 'package:allgoz/Favorite/favorite.dart';
import 'package:allgoz/Home/home.dart';
import 'package:allgoz/Orders/my_orders.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  String? userPhoneNumber;
  List<Map<String, dynamic>> cartItems = [];
  double totalAmount = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserPhoneNumber();
  }

  /// ✅ Fetch User Phone Number (Needed for Firestore)
  void _fetchUserPhoneNumber() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && user.phoneNumber != null) {
      setState(() {
        userPhoneNumber = user.phoneNumber;
      });
      print("📢 User Phone: $userPhoneNumber");
    } else {
      print("❌ User not logged in!");
    }
  }

  /// ✅ Fetch Cart from Firestore in Real-Time
  Stream<QuerySnapshot> _fetchCartStream() {
    if (userPhoneNumber == null) {
      print("❌ No User Logged In!");
      return Stream.empty();
    }
    return FirebaseFirestore.instance
        .collection('customers')
        .doc(userPhoneNumber)
        .collection('cart')
        .snapshots();
  }

  /// ✅ Update Cart Quantity in Firestore
  void _updateCart(String productId, Map<String, dynamic> product, int newQuantity) async {
    if (userPhoneNumber == null) return;

    int baseGrams = (product['unit'] == "Kg") ? 1000 : 1;
    int grams = newQuantity * baseGrams;

    if (newQuantity > 0) {
      await FirebaseFirestore.instance
          .collection('customers')
          .doc(userPhoneNumber)
          .collection('cart')
          .doc(productId)
          .set({
        'name': product['name'],
        'price': product['price'],
        'quantity': newQuantity,
        'grams': grams,
        'imageURL': product['imageURL'],
        'unit': product['unit'],
        'totalQuantity': newQuantity,
      }, SetOptions(merge: true));

      print("✅ Cart Updated: ${product['name']} (Qty: $newQuantity | Grams: $grams)");
    } else {
      await _removeFromCart(productId);
    }
  }

  /// ✅ Remove Product from Firestore Cart
  Future<void> _removeFromCart(String productId) async {
    if (userPhoneNumber == null) return;

    await FirebaseFirestore.instance
        .collection('customers')
        .doc(userPhoneNumber)
        .collection('cart')
        .doc(productId)
        .delete();

    print("🗑 Removed from Cart: $productId");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF4A90E2),
        title: Text('My Cart'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.delivery_dining, color: Colors.white),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => MyOrdersScreen()));
            },
          ),
        ],
      ),

      /// 🔹 Listen to Firestore Cart Updates
      body: StreamBuilder(
        stream: _fetchCartStream(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          var cartData = snapshot.data!.docs;
          if (cartData.isEmpty) {
            return Center(child: Text("Your cart is empty!", style: TextStyle(fontSize: 18)));
          }

          /// ✅ Update Total Price
          totalAmount = cartData.fold(0, (sum, item) => sum + (item['price'] * item['quantity']));

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: cartData.length,
                  itemBuilder: (context, index) {
                    var cartItem = cartData[index];
                    String productId = cartItem.id;
                    int quantity = cartItem['quantity'];
                    String unit = cartItem['unit'];

                    return ListTile(
                      leading: Image.network(cartItem['imageURL'], width: 50),
                      title: Text(cartItem['name'], style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("${cartItem['grams']}g"),
                          Text("₹${cartItem['price']} x $quantity"),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          /// 🔹 Decrement Button
                          IconButton(
                            icon: Icon(Icons.remove_circle_outline, color: Colors.red),
                            onPressed: () {
                              if (quantity > 1) {
                                _updateCart(productId, cartItem.data() as Map<String, dynamic>, quantity - 1);

                              } else {
                                _removeFromCart(productId);
                              }
                            },
                          ),
                          Text('$quantity'),
                          /// 🔹 Increment Button
                          IconButton(
                            icon: Icon(Icons.add_circle_outline, color: Colors.green),
                            onPressed: () {
                              _updateCart(productId, cartItem.data() as Map<String, dynamic>, quantity + 1);

                            },
                          ),
                          /// 🔹 Delete Button
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeFromCart(productId),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              /// 🔹 Total Price & Checkout Button
              Divider(thickness: 1),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('₹$totalAmount', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => CheckoutScreen()));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                        minimumSize: Size(double.infinity, 50),
                      ),
                      child: Text('Proceed to Checkout', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),

      /// 🔹 Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1, // Cart
        selectedItemColor: Color(0xFF4A90E2),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 0) Navigator.push(context, MaterialPageRoute(builder: (context) => HomePage()));
          if (index == 2) Navigator.push(context, MaterialPageRoute(builder: (context) => FavoritesScreen()));
          if (index == 3) Navigator.push(context, MaterialPageRoute(builder: (context) => AccountScreen()));
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Cart'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favorites'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
