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
  double totalAmount = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserPhoneNumber();
  }

  void _fetchUserPhoneNumber() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && user.phoneNumber != null) {
      setState(() {
        userPhoneNumber = user.phoneNumber;
      });
    }
  }

  Stream<QuerySnapshot> _fetchCartStream() {
    if (userPhoneNumber == null) return Stream.empty();
    return FirebaseFirestore.instance
        .collection('customers')
        .doc(userPhoneNumber)
        .collection('cart')
        .snapshots();
  }

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
    } else {
      await _removeFromCart(productId);
    }
  }

  Future<void> _removeFromCart(String productId) async {
    if (userPhoneNumber == null) return;
    await FirebaseFirestore.instance
        .collection('customers')
        .doc(userPhoneNumber)
        .collection('cart')
        .doc(productId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = screenWidth / 390;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
        return false; // prevent default pop
      },// 🚫 Prevent back button
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false, // 🚫 Hide back button
          backgroundColor: const Color(0xFF4A90E2),
          title: Text('My Cart', style: TextStyle(fontSize: 20 * scaleFactor)),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.delivery_dining, color: Colors.white, size: 24 * scaleFactor),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => MyOrdersScreen()));
              },
            ),
          ],
        ),
        body: StreamBuilder(
          stream: _fetchCartStream(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

            var cartData = snapshot.data!.docs;
            if (cartData.isEmpty) {
              return Center(
                child: Text("Your cart is empty!", style: TextStyle(fontSize: 18 * scaleFactor)),
              );
            }

            totalAmount = cartData.fold(0.0, (sum, item) => sum + (item['price'] * item['quantity']));

            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cartData.length,
                    itemBuilder: (context, index) {
                      var cartItem = cartData[index];
                      String productId = cartItem.id;
                      int quantity = cartItem['quantity'];

                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12 * scaleFactor, vertical: 8 * scaleFactor),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Image.network(cartItem['imageURL'], width: 60 * scaleFactor),
                            SizedBox(width: 12 * scaleFactor),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(cartItem['name'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16 * scaleFactor)),
                                  SizedBox(height: 4 * scaleFactor),
                                  Text("${cartItem['grams']}g", style: TextStyle(fontSize: 13 * scaleFactor)),
                                  Text("₹${cartItem['price']} x $quantity", style: TextStyle(fontSize: 13 * scaleFactor)),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.remove_circle_outline, color: Colors.red, size: 20 * scaleFactor),
                                  onPressed: () {
                                    if (quantity > 1) {
                                      _updateCart(productId, cartItem.data() as Map<String, dynamic>, quantity - 1);
                                    } else {
                                      _removeFromCart(productId);
                                    }
                                  },
                                ),
                                Text('$quantity', style: TextStyle(fontSize: 14 * scaleFactor)),
                                IconButton(
                                  icon: Icon(Icons.add_circle_outline, color: Colors.green, size: 20 * scaleFactor),
                                  onPressed: () {
                                    _updateCart(productId, cartItem.data() as Map<String, dynamic>, quantity + 1);
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red, size: 20 * scaleFactor),
                                  onPressed: () => _removeFromCart(productId),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const Divider(thickness: 1),
                Padding(
                  padding: EdgeInsets.all(16 * scaleFactor),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total:', style: TextStyle(fontSize: 18 * scaleFactor, fontWeight: FontWeight.bold)),
                          Text('₹$totalAmount', style: TextStyle(fontSize: 18 * scaleFactor, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      SizedBox(height: 10 * scaleFactor),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => CheckoutScreen()));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                          minimumSize: Size(double.infinity, 50 * scaleFactor),
                        ),
                        child: Text(
                          'Proceed to Checkout',
                          style: TextStyle(fontSize: 16 * scaleFactor, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: 1,
          selectedItemColor: const Color(0xFF4A90E2),
          unselectedItemColor: Colors.grey,
          onTap: (index) {
            if (index == 0) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomePage()));
            if (index == 2) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const FavoritesScreen()));
            if (index == 3) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AccountScreen()));
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Cart'),
            BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favorites'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
