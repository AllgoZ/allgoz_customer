import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:allgoz/Cart/cart.dart';
import 'package:firebase_auth/firebase_auth.dart';
class CategoryScreen extends StatefulWidget {
  final String categoryName; // ✅ Passed from home.dart
  const CategoryScreen({super.key, required this.categoryName});

  @override
  _CategoryScreenState createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> products = [];
  String selectedType = ""; // Track selected type
  String? userPhoneNumber;
  Map<String, int> cartItems = {}; // ✅ Store productId and quantity

  @override
  void initState() {
    super.initState();
    _fetchUserPhoneNumber();
    _fetchCart();
    _fetchTypes(); // Fetch left sidebar content
       // ✅ Start listening to Firestore cart updates

  }

  void _fetchUserPhoneNumber() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && user.phoneNumber != null) {
      setState(() {
        userPhoneNumber = user.phoneNumber;
      });
      print("📢 userPhoneNumber set from FirebaseAuth: $userPhoneNumber");
    } else {
      print("❌ User is not logged in or phone number is not available!");
    }
  }



  void _fetchCart() {
    if (userPhoneNumber == null) return;

    FirebaseFirestore.instance
        .collection('customers')
        .doc(userPhoneNumber)
        .collection('cart')
        .snapshots()
        .listen((snapshot) {
      Map<String, int> updatedCart = {};

      for (var doc in snapshot.docs) {
        updatedCart[doc.id] = doc['quantity']; // ✅ Store Firestore quantity
      }

      setState(() {
        cartItems = updatedCart; // ✅ UI now syncs with Firestore cart

        // 🔥 Update product quantities in the UI if they exist in the cart
        for (var product in products) {
          if (cartItems.containsKey(product['id'])) {
            product['cartQuantity'] = cartItems[product['id']]; // ✅ Update quantity in UI
          }
        }
      });

      print("📢 Updated cart from Firestore: $cartItems");
    });
  }




  /// ✅ Fetch Types (Left Sidebar) from Firestore
  Future<void> _fetchTypes() async {
    try {
      print("📢 Fetching types for category: ${widget.categoryName}...");

      QuerySnapshot typeSnapshot = await FirebaseFirestore.instance
          .collection('categories')
          .doc(widget.categoryName.toLowerCase()) // 🔥 Ensure correct doc path
          .collection('types') // ✅ Fetch from "types" subcollection
          .get();

      setState(() {
        categories = typeSnapshot.docs.map((doc) {
          print("📢 Found Type: ${doc['name']}"); // ✅ Debugging logs
          return {
            'name': doc['name'],
            'image': doc['image'],
          };
        }).toList();

        print("✅ Fetched ${categories.length} types: $categories");

        if (categories.isNotEmpty) {
          selectedType = categories[0]['name']; // Default type selection
          _fetchProducts(); // Fetch products after getting types
        }
      });
    } catch (e) {
      print("❌ Error fetching types: $e");
    }
  }


  /// ✅ Fetch Products based on Selected Type
  /// ✅ Fetch Products based on Selected Type
  Future<void> _fetchProducts() async {
    try {
      print("📢 Fetching products for category: ${widget.categoryName}, type: $selectedType...");

      QuerySnapshot productSnapshot = await FirebaseFirestore.instance
          .collectionGroup('products') // ✅ Fetch products from all users
          .where('category', isEqualTo: widget.categoryName) // Example: Vegetables
          .where('available', isEqualTo: true)
          .get();

      List<Map<String, dynamic>> fetchedProducts = [];

      for (var doc in productSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?; // ✅ Explicit casting
        if (data == null || !data.containsKey('type')) {
          print("⚠️ Skipping product: Missing 'type' field in ${doc.id}");
          continue; // Skip this entry if 'type' field is missing
        }

        if (data['type'] == selectedType) {
          print("✅ Product Found: ${data['name']} - ₹${data['price']} - Type: ${data['type']}");

          // ✅ Ensure 'quantity' & 'unit' are included
          fetchedProducts.add({
            'id': doc.id, // ✅ Product ID
            'name': data['name'],
            'price': data['price'],
            'imageURL': data['imageURL'],
            'discount': data['discount'] ?? 0,
            'quantity': data['quantity'] ?? "N/A", // ✅ Get quantity dynamically
            'unit': data['unit'] ?? "N/A", // ✅ Get unit dynamically
            'cartQuantity': cartItems[doc.id] ?? 0, // ✅ Attach existing cart quantity from Firestore
          });
        }
      }

      setState(() {
        products = fetchedProducts;
        print("✅ Final Product List (${products.length} items): $products");
      });

    } catch (e) {
      print("❌ Error fetching products: $e");
    }
  }






  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        backgroundColor: Color(0xFF4A90E2),
        actions: [
          IconButton(icon: Icon(Icons.shopping_cart), onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => CartScreen()));
          }),
        ],
      ),
      body: Row(
        children: [
          /// 🔹 Left Sidebar (Types)
          Container(
            width: 100,
            color: Color(0xFFE3F2FD),
            child: ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    print("📢 Selected Type: ${categories[index]['name']}"); // ✅ Debug type selection
                    setState(() {
                      selectedType = categories[index]['name'];
                      _fetchProducts(); // Fetch products for selected type
                    });
                  },
                  child: Container(
                    color: selectedType == categories[index]['name']
                        ? Colors.blue.shade100
                        : Colors.transparent,
                    padding: EdgeInsets.all(8),
                    child: Column(
                      children: [
                        Image.network(categories[index]['image'], height: 50),
                        Text(categories[index]['name'],
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          Expanded(
            child: products.isEmpty
                ? Center(child: Text("No products found", style: TextStyle(fontSize: 18)))
                : GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.53, // Adjusted to prevent overflow
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                String productId = product['id'];
                int cartQuantity = cartItems[productId] ?? 0; // ✅ Get quantity from Firestore

                return GestureDetector(
                  onTap: () => _showBottomSheet(context, product),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // 🔹 Product Image with Discount Badge
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                              child: Image.network(
                                product['imageURL'],
                                height: 120,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            if (product['discount'] > 0) // 🔹 Show discount badge only if applicable
                              Positioned(
                                top: 5,
                                left: 5,
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "${product['discount']}% Off",
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                          ],
                        ),

                        SizedBox(height: 8),

                        // 🔹 Product Name
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            product['name'],
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        // 🔹 Quantity & Unit
                        Text(
                          "${product['quantity']} ${product['unit']}", // ✅ Show quantity dynamically
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),

                        // 🔹 Price
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "₹${product['price']}",
                              style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(width: 5),
                            if (product['originalPrice'] != null) // Strike-through price if available
                              Text(
                                "₹${product['originalPrice']}",
                                style: TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),

                        Spacer(), // Push Add to Cart button to bottom

                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: cartQuantity == 0
                              ? ElevatedButton(
                            onPressed: () {
                              int baseGrams = (product['unit'] == "Kg") ? 1000 : 1;
                              _updateCart(productId, product, 1, baseGrams);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white, // ✅ White background
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9), // ✅ Rounded corners
                                side: BorderSide(color: Colors.green, width: 2), // ✅ Green Outline
                              ),
                              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10), // ✅ Better padding
                              minimumSize: Size(120, 40), // ✅ Make width match increment/decrement button
                            ),
                            child: Text(
                              "Add to Cart",
                              style: TextStyle(
                                color: Colors.green, // ✅ Green text
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                              : Container(
                            width: double.infinity, // ✅ Same width as "Add to Cart"
                            height: 45, // ✅ Same height as "Add to Cart"
                            decoration: BoxDecoration(
                              color: Colors.white, // ✅ White Background
                              borderRadius: BorderRadius.circular(9), // ✅ Rounded Corners
                              border: Border.all(color: Colors.green, width: 2), // ✅ Green Outline
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween, // ✅ Better spacing
                              children: [
                                Expanded(
                                  child: IconButton(
                                    icon: Icon(Icons.remove, color: Colors.green, size: 20), // ✅ Green icon
                                    onPressed: () {
                                      int baseGrams = (product['unit'] == "Kg") ? 1000 : 1;
                                      if (cartQuantity > 1) {
                                        _updateCart(productId, product, cartQuantity - 1, baseGrams);
                                      } else {
                                        _removeFromCart(product); // ✅ Removes when quantity is 0
                                      }
                                    },
                                  ),
                                ),
                                Text(
                                  "$cartQuantity",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green, // ✅ Green text
                                  ),
                                ),
                                Expanded(
                                  child: IconButton(
                                    icon: Icon(Icons.add, color: Colors.green, size: 20), // ✅ Green icon
                                    onPressed: () {
                                      int baseGrams = (product['unit'] == "Kg") ? 1000 : 1;
                                      _updateCart(productId, product, cartQuantity + 1, baseGrams);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),




                      ],
                    ),
                  ),
                );
              },
            ),
          ),


        ],
      ),
      bottomNavigationBar: cartItems.isNotEmpty
          ? Container(
        decoration: BoxDecoration(
          color: Colors.white, // ✅ White background for a clean look
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)), // ✅ Rounded top corners
          border: Border.all(color: Colors.grey, width: 2), // ✅ Green outline
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -4), // ✅ Creates a floating effect
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10), // ✅ Even padding
        height: 68, // ✅ Increased height for a premium feel
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // ✅ Total Items in Cart (Left Side)
            Text(
              "${cartItems.values.fold(0, (sum, item) => sum + item)} Items",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87, // ✅ Slightly darker text for readability
              ),
            ),

            // ✅ Styled "View Cart" Button
            ElevatedButton(
              onPressed: () {
                _showCartModal(context); // ✅ Open Cart Modal
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, // ✅ White background
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9), // ✅ Rounded Corners
                  // side: BorderSide(color: Colors.white, width: 2), // ✅ Green Outline
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12), // ✅ More padding for a premium feel
                minimumSize: Size(130, 45), // ✅ Fixed button size
              ),
              child: Text(
                "View Cart",
                style: TextStyle(
                  color: Colors.white, // ✅ Green Text
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      )
          : null,



    );
  }
  void _showCartModal(BuildContext context) {
    if (userPhoneNumber == null) {
      print("User phone number is null, can't show cart modal");
      return;
    }
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('customers')
              .doc(userPhoneNumber)
              .collection('cart')
              .snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

            var cartData = snapshot.data!.docs;

            return Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🔹 Modal Header
                  Text("Your Cart", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Divider(),

                  // 🔹 Cart Items List
                  Expanded(
                    child: cartData.isNotEmpty
                        ? ListView.builder(
                      itemCount: cartData.length,
                      itemBuilder: (context, index) {
                        var cartItem = cartData[index];
                        return ListTile(
                          leading: Image.network(cartItem['imageURL'], width: 50),
                          title: Text(cartItem['name']),
                          subtitle: Text("₹${cartItem['price']} x ${cartItem['quantity']}"),
                          trailing: Text(
                            "₹${cartItem['price'] * cartItem['quantity']}",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        );
                      },
                    )
                        : Center(
                      child: Text("Your cart is empty", style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  SizedBox(height: 10),

                  // 🔹 Checkout Button
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // ✅ Close modal before navigating
                      // Implement Checkout Screen Navigation Here
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                      minimumSize: Size(double.infinity, 50), // ✅ Full-width button
                    ),
                    child: Text("Proceed to Checkout", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }





  Future<void> _updateCart(String productId, Map<String, dynamic> product, int totalQuantity, int baseGrams) async {
    if (userPhoneNumber == null) {
      print("❌ No userPhoneNumber found! Cart cannot be updated.");
      return;
    }

    // ✅ Update UI instantly before Firestore update
    setState(() {
      if (totalQuantity > 0) {
        cartItems[productId] = totalQuantity; // ✅ Update UI immediately
      } else {
        cartItems.remove(productId); // ✅ Remove from cart UI instantly
      }
    });

    DocumentReference cartRef = FirebaseFirestore.instance
        .collection('customers')
        .doc(userPhoneNumber)
        .collection('cart')
        .doc(productId);

    int totalGrams = totalQuantity * baseGrams; // 🔥 Convert quantity to grams

    if (totalQuantity > 0) {
      print("🛒 Updating ${product['name']} (Qty: $totalQuantity | Grams: $totalGrams) in Firestore...");
      await cartRef.set({
        'name': product['name'],
        'price': product['price'],
        'quantity': totalQuantity,
        'grams': totalGrams,
        'imageURL': product['imageURL'],
        'unit': product['unit'],
        'totalQuantity': totalQuantity, // ✅ Track total quantity
      }, SetOptions(merge: true));

      print("✅ Successfully updated Firestore!");
    } else {
      print("🗑 Removing ${product['name']} from Firestore...");
      await cartRef.delete();
      print("✅ Removed from Firestore!");
    }
  }




  void _addToCart(Map<String, dynamic> product) {
    if (userPhoneNumber == null) {
      print("❌ Waiting for userPhoneNumber... Retrying in 1 second");
      Future.delayed(Duration(seconds: 1), () => _addToCart(product)); // Retry after 1 sec
      return;
    }

    print("🛒 _addToCart() Triggered for ${product['name']} with userPhoneNumber: $userPhoneNumber");

    String productId = product['id'];
    int newQuantity = (cartItems[productId] ?? 0) + 1;

    print("📢 Adding product to Firestore: ID = $productId, New Qty = $newQuantity");
    int baseGrams = (product['unit'] == "Kg") ? 1000 : 1; // ✅ Determine grams per unit
    _updateCart(productId, product, newQuantity, baseGrams); // ✅ Pass all 4 arguments

  }














  void _showBottomSheet(BuildContext context, Map<String, dynamic> product) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // 🔹 Convert `quantity` to an integer and store in `totalQuantity`
            int totalQuantity = cartItems[product['id']] ?? 0;

            int baseGrams = (product['unit'] == "Kg") ? 1000 : 1; // 1 Kg = 1000g
            int grams = totalQuantity * baseGrams; // 🔥 Calculate grams

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 🔹 Favorite Button (Top Right)
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: Icon(
                        (product['isFavorite'] ?? false) ? Icons.favorite : Icons.favorite_border,
                        color: (product['isFavorite'] ?? false) ? Colors.red : Colors.grey,
                      ),
                      onPressed: () {
                        setModalState(() {
                          product['isFavorite'] = !(product['isFavorite'] ?? false);
                          _updateFavorite(product['id'], product['isFavorite']);
                        });
                      },
                    ),
                  ),

                  // 🔹 Product Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.network(
                      product['imageURL'],
                      height: 150,
                    ),
                  ),
                  SizedBox(height: 10),

                  // 🔹 Product Name & Price
                  Text(product['name'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  Text('₹${product['price']}', style: TextStyle(color: Colors.green, fontSize: 16)),
                  Text("${product['quantity']} ${product['unit']}",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),

                  SizedBox(height: 10),

                  // 🔹 Display Grams Based on Quantity
                  if (totalQuantity > 0)
                    Text(
                      "Total: ${grams}g",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue),
                    ),

                  SizedBox(height: 10),

                  // 🔹 Add to Cart & View Cart Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 🔹 View Cart Button (Appears if item is in cart)
                      if (totalQuantity > 0)
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context); // Close modal and go to cart screen
                              Navigator.push(context, MaterialPageRoute(builder: (context) => CartScreen()));
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9),
                                side: BorderSide(color: Colors.green),
                              ),
                              minimumSize: Size(double.infinity, 50), // Full-width button
                            ),
                            child: Text("View Cart", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          ),
                        ),

                      SizedBox(width: totalQuantity > 0 ? 10 : 0), // Space only if View Cart is visible

                      // 🔹 Add to Cart OR - 1 + Buttons
                      Expanded(
                        child: totalQuantity == 0
                            ? ElevatedButton(
                          onPressed: () {
                            setModalState(() {
                              product['cartQuantity'] = 1; // ✅ Set quantity to 1 when added
                              _updateCart(product['id'], product, 1, baseGrams); // ✅ Update Firestore
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9),
                            ),
                            minimumSize: Size(double.infinity, 50), // Full-width button
                          ),
                          child: Text("Add to Cart", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        )
                            : Container(
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              IconButton(
                                icon: Icon(Icons.remove, color: Colors.white),
                                onPressed: () {
                                  setModalState(() {
                                    if (product['cartQuantity'] > 1) {
                                      product['cartQuantity']--; // Decrease quantity
                                      _updateCart(product['id'], product, product['cartQuantity'], baseGrams);

                                    } else {
                                      product['cartQuantity'] = 0; // Remove from cart
                                      _removeFromCart(product);
                                    }
                                  });
                                },
                              ),
                              Text("${product['cartQuantity']}",
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                              IconButton(
                                icon: Icon(Icons.add, color: Colors.white),
                                onPressed: () {
                                  setModalState(() {
                                    product['cartQuantity']++; // Increase quantity
                                    _updateCart(product['id'], product, product['cartQuantity'], baseGrams);
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }





  Future<void> _updateFavorite(String productId, bool isFavorite) async {
    if (userPhoneNumber == null) return;

    DocumentReference productRef = FirebaseFirestore.instance
        .collection('customers')
        .doc(userPhoneNumber)
        .collection('cart')
        .doc(productId);

    try {
      await productRef.set({
        'isFavorite': isFavorite, // ✅ Save favorite status
      }, SetOptions(merge: true));

      print("❤️ Updated favorite status for $productId: $isFavorite");
    } catch (e) {
      print("❌ Error updating favorite: $e");
    }
  }

  void _removeFromCart(Map<String, dynamic> product) async {
    if (userPhoneNumber == null) return;

    String productId = product['id']; // Unique product ID

    // 🔹 Update UI immediately
    setState(() {
      cartItems.remove(productId);
    });

    try {
      await FirebaseFirestore.instance
          .collection('customers')
          .doc(userPhoneNumber)
          .collection('cart')
          .doc(productId)
          .delete(); // ✅ Remove item from Firestore

      print("🗑 Removed ${product['name']} from Firestore!");
    } catch (e) {
      print("❌ Error removing from cart: $e");
    }
  }


}
