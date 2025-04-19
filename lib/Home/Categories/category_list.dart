import 'package:allgoz/Cart/Checkout/checkout.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:allgoz/Cart/cart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shimmer/shimmer.dart';


class CategoryScreen extends StatefulWidget {
  final String categoryName; // ✅ Passed from home.dart
  const CategoryScreen({super.key, required this.categoryName});

  @override
  _CategoryScreenState createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  bool _isLoading = true;

  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> products = [];
  String selectedType = ""; // Track selected type
  String? userCustomerId;

  Map<String, int> cartItems = {}; // ✅ Store productId and quantity

  @override
  void initState() {
    super.initState();
    _fetchUserCustomerId();
    _fetchCart();
    _fetchTypes(); // Fetch left sidebar content
    // ✅ Start listening to Firestore cart updates

  }

  void _fetchUserCustomerId() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      setState(() {
        userCustomerId = 'google_${user.email!.replaceAll('.', '_').replaceAll('@', '_')}';
      });
      print("📢 userCustomerId set from FirebaseAuth: $userCustomerId");
      _fetchCart(); // Move cart fetch here since ID is set
    } else {
      print("❌ User is not logged in or email is not available!");
    }
  }




  void _fetchCart() {
    if (userCustomerId == null) return;

    FirebaseFirestore.instance
        .collection('customers')
        .doc(userCustomerId)

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


  Widget _buildShimmerCard(double scaleFactor) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        margin: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        height: 200 * scaleFactor,
        width: double.infinity,
      ),
    );
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
    setState(() {
      _isLoading = true;
    });

    try {
      QuerySnapshot productSnapshot = await FirebaseFirestore.instance
          .collectionGroup('products')
          .where('category', isEqualTo: widget.categoryName)
          .where('available', isEqualTo: true)
          .get();

      List<Map<String, dynamic>> fetchedProducts = [];

      for (var doc in productSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;

        if (data == null || !data.containsKey('type')) continue;
        if (data['type'] == selectedType) {
          fetchedProducts.add({
            'id': doc.id,
            'name': data['name'],
            'price': data['price'],
            'imageURL': data['imageURL'],
            'discount': data['discount'] ?? 0,
            'quantity': int.tryParse(data['quantity'].toString()) ?? 1,
            'unit': data['unit'] ?? "N/A",
            'grams': int.tryParse(data['grams'].toString()) ?? 0,
            'cartQuantity': cartItems[doc.id] ?? 0,
          });
        }
      }

      setState(() {
        products = fetchedProducts;
        _isLoading = false;
      });
    } catch (e) {
      print("❌ Error fetching products: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }






  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final scaleFactor = screenWidth / 390; // Reference width (e.g., iPhone 12)

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.categoryName,
          style: TextStyle(fontSize: 18 * scaleFactor),
        ),
        backgroundColor: const Color(0xFF4A90E2),
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart, size: 24 * scaleFactor),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => CartScreen()));
            },
          ),
        ],
      ),
      body: Row(
        children: [
          /// 🔹 Left Sidebar
          Container(
            width: screenWidth * 0.25,
            color: const Color(0xFFE3F2FD),
            child: ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedType = categories[index]['name'];
                      _fetchProducts();
                    });
                  },
                  child: Container(
                    color: selectedType == categories[index]['name']
                        ? Colors.blue.shade100
                        : Colors.transparent,
                    padding: EdgeInsets.all(8 * scaleFactor),
                    child: Column(
                      children: [
                        Image.network(categories[index]['image'], height: 50 * scaleFactor),
                        SizedBox(height: 4 * scaleFactor),
                        Text(
                          categories[index]['name'],
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14 * scaleFactor),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          /// 🔹 Product Grid
          Expanded(
            child: _isLoading
                ? GridView.builder(
              padding: EdgeInsets.all(8 * scaleFactor),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: screenWidth < 500 ? 2 : 3,
                crossAxisSpacing: 10 * scaleFactor,
                mainAxisSpacing: 10 * scaleFactor,
                childAspectRatio: 0.46,
              ),
              itemCount: 6, // Number of shimmer cards
              itemBuilder: (context, index) => _buildShimmerCard(scaleFactor),
            )
                : products.isEmpty
                ? Center(child: Text("No products found"))
                : GridView.builder(
              padding: EdgeInsets.all(8 * scaleFactor),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: screenWidth < 500 ? 2 : 3,
                crossAxisSpacing: 10 * scaleFactor,
                mainAxisSpacing: 10 * scaleFactor,
                childAspectRatio: 0.46, // Adjusted to fix overflow
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                final productId = product['id'];
                final cartQuantity = cartItems[productId] ?? 0;

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
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(screenWidth * 0.025),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        /// Image with discount
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                              child: Image.network(
                                product['imageURL'],
                                height: screenHeight * 0.12,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            if (product['discount'] > 0)
                              Positioned(
                                top: 5,
                                left: 5,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "${product['discount']}% Off",
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12 * scaleFactor),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 6 * scaleFactor),

                        /// Product Name
                        Text(
                          product['name'],
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14 * scaleFactor),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4 * scaleFactor),

                        /// Quantity
                        Text(
                          "${product['quantity']} ${product['unit']}",
                          style: TextStyle(fontSize: 14 * scaleFactor, color: Colors.grey, fontWeight: FontWeight.bold,),
                        ),
                        SizedBox(height: 4 * scaleFactor),

                        /// Price
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "₹${product['price']}",
                              style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14 * scaleFactor),
                            ),
                            SizedBox(width: 5),
                            if (product['originalPrice'] != null)
                              Text(
                                "₹${product['originalPrice']}",
                                style: TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12 * scaleFactor,
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 6 * scaleFactor),

                        /// Add to Cart
                        cartQuantity == 0
                            ? ElevatedButton(
                          onPressed: () {
                            int baseGrams = (product['unit'] == "Kg") ? 1000 : int.tryParse(product['quantity'].toString()) ?? 100;
                            _updateCart(productId, product, 1, baseGrams);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9),
                              side: const BorderSide(color: Colors.green,),
                            ),
                            minimumSize: Size(screenWidth * 0.4, screenHeight * 0.049),
                          ),
                          child: Text("ADD",
                              style: TextStyle(color: Colors.green, fontSize: 15 * scaleFactor, fontWeight: FontWeight.bold)),
                        )
                            : Container(
                          height: screenHeight * 0.049,
                          width: screenWidth * 0.38,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(color: Colors.green, width: 2),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 4 * scaleFactor), // optional
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove, color: Colors.green),
                                  iconSize: 25 * scaleFactor,
                                  onPressed: () {
                                    int baseGrams = (product['unit'] == "Kg")
                                        ? 1000
                                        : int.tryParse(product['quantity'].toString()) ?? 100;
                                    if (cartQuantity > 1) {
                                      _updateCart(productId, product, cartQuantity - 1, baseGrams);
                                    } else {
                                      _removeFromCart(product);
                                    }
                                  },
                                ),
                                Text(
                                  "$cartQuantity",
                                  style: TextStyle(
                                    fontSize: 25 * scaleFactor,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add, color: Colors.green),
                                  iconSize: 25 * scaleFactor,
                                  onPressed: () {
                                    int baseGrams = (product['unit'] == "Kg")
                                        ? 1000
                                        : int.tryParse(product['quantity'].toString()) ?? 100;
                                    _updateCart(productId, product, cartQuantity + 1, baseGrams);
                                  },
                                ),
                              ],
                            ),
                          ),
                        )

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
          ? SafeArea(
        child: Container(
          height: 70 * scaleFactor,
          padding: EdgeInsets.symmetric(horizontal: 16 * scaleFactor),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${cartItems.values.fold(0, (sum, item) => sum + item)} Items",
                style: TextStyle(fontSize: 16 * scaleFactor, fontWeight: FontWeight.bold),
              ),
              ElevatedButton(
                onPressed: () {
                  _showCartModal(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text("View Items", style: TextStyle(fontSize: 14 * scaleFactor,color: Colors.white)),
              ),
            ],
          ),
        ),
      )
          : null,
    );
  }


  void _showCartModal(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final scaleFactor = screenWidth / 390; // iPhone 12 baseline

    if (userCustomerId == null) {
      print("User phone number is null, can't show cart modal");
      return;
    }

    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20 * scaleFactor)),
      ),
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.6,
          child: StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection('customers')
                .doc(userCustomerId)

                .collection('cart')
                .snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              var cartData = snapshot.data!.docs;

              return Padding(
                padding: EdgeInsets.all(16.0 * scaleFactor),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔹 Header Row with Close Icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Your Items",
                          style: TextStyle(
                              fontSize: 22 * scaleFactor,
                              fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, size: 24 * scaleFactor),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    Divider(),

                    // 🔹 Cart List
                    Expanded(
                      child: cartData.isNotEmpty
                          ? ListView.builder(
                        itemCount: cartData.length,
                        itemBuilder: (context, index) {
                          var cartItem = cartData[index];
                          return ListTile(
                            leading: Image.network(
                              cartItem['imageURL'],
                              width: 50 * scaleFactor,
                              height: 50 * scaleFactor,
                              fit: BoxFit.cover,
                            ),
                            title: Text(
                              cartItem['name'],
                              style: TextStyle(fontSize: 16 * scaleFactor),
                            ),
                            subtitle: Text(
                              "₹${cartItem['price']} x ${cartItem['quantity']}",
                              style: TextStyle(fontSize: 14 * scaleFactor),
                            ),
                            trailing: Text(
                              "₹${cartItem['price'] * cartItem['quantity']}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16 * scaleFactor,
                              ),
                            ),
                          );
                        },
                      )
                          : Center(
                        child: Text(
                          "Your cart is empty",
                          style: TextStyle(fontSize: 16 * scaleFactor),
                        ),
                      ),
                    ),
                    SizedBox(height: 10 * scaleFactor),

                    // 🔹 Checkout Button
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => CartScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9 * scaleFactor),
                        ),
                        minimumSize: Size(double.infinity, 50 * scaleFactor),
                      ),
                      child: Text(
                        "View Cart",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18 * scaleFactor,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }






  Future<void> _updateCart(String productId, Map<String, dynamic> product, int totalQuantity, int baseGrams) async {
    if (userCustomerId == null) {
      print("❌ No userPhoneNumber found! Cart cannot be updated.");
      return;
    }

    int totalGrams = totalQuantity * baseGrams;

    setState(() {
      if (totalQuantity > 0) {
        cartItems[productId] = totalQuantity; // ✅ Update UI
      } else {
        cartItems.remove(productId); // ✅ Remove from UI when qty reaches 0
      }
    });

    DocumentReference cartRef = FirebaseFirestore.instance
        .collection('customers')
        .doc(userCustomerId)
        .collection('cart')
        .doc(productId);

    try {
      if (totalQuantity > 0) {
        print("🛒 Updating ${product['name']} (Qty: $totalQuantity | Grams: $totalGrams) in Firestore...");
        await cartRef.set({
          'name': product['name'],
          'price': product['price'],
          'quantity': totalQuantity,
          'grams': totalGrams, // ✅ Store correct grams
          'imageURL': product['imageURL'],
          'unit': product['unit'],
          'totalQuantity': totalQuantity,
        }, SetOptions(merge: true));
      } else {
        print("🗑 Removing ${product['name']} from Firestore...");
        await cartRef.delete(); // ✅ Remove from Firestore when qty reaches 0
      }
    } catch (e) {
      print("❌ Error updating Firestore: $e");
    }
  }





  void _addToCart(Map<String, dynamic> product) {
    if (userCustomerId == null) {
      print("❌ Waiting for userPhoneNumber... Retrying in 1 second");
      Future.delayed(Duration(seconds: 1), () => _addToCart(product)); // Retry after 1 sec
      return;
    }

    print("🛒 _addToCart() Triggered for ${product['name']} with userPhoneNumber: $userCustomerId");

    String productId = product['id'];
    int newQuantity = (cartItems[productId] ?? 0) + 1;

    print("📢 Adding product to Firestore: ID = $productId, New Qty = $newQuantity");
    int baseGrams = (product['unit'] == "Kg") ? 1000 : 1; // ✅ Determine grams per unit
    _updateCart(productId, product, newQuantity,baseGrams); // ✅ Pass all 4 arguments

  }













  void _showBottomSheet(BuildContext context, Map<String, dynamic> product) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = screenWidth / 390; // iPhone 12 width baseline

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20 * scaleFactor)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            int totalQuantity = cartItems[product['id']] ?? 0;
            int baseGrams = (product['unit'] == "Kg")
                ? 1000
                : int.tryParse(product['quantity'].toString()) ?? 100;
            int totalGrams = totalQuantity * baseGrams;

            return Padding(
              padding: EdgeInsets.all(16.0 * scaleFactor),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 🔸 Close Icon
                  Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(Icons.close, size: 24 * scaleFactor),
                    ),
                  ),
                  SizedBox(height: 10 * scaleFactor),

                  // 🔹 Product Name & Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15 * scaleFactor),
                    child: Image.network(
                      product['imageURL'],
                      height: 150 * scaleFactor,
                    ),
                  ),
                  SizedBox(height: 10 * scaleFactor),
                  Text(product['name'],
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20 * scaleFactor)),
                  Text('₹${product['price']}',
                      style: TextStyle(color: Colors.green, fontSize: 16 * scaleFactor)),
                  Text("${product['quantity']} ${product['unit']}",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16 * scaleFactor,
                          color: Colors.grey)),
                  SizedBox(height: 10 * scaleFactor),

                  if (totalQuantity > 0)
                    Text("Total: ${totalGrams}g",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16 * scaleFactor,
                            color: Colors.blue)),
                  SizedBox(height: 10 * scaleFactor),

                  // 🔹 Add to Cart or Quantity Controller
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (totalQuantity > 0)
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => CartScreen()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9 * scaleFactor),
                                side: BorderSide(color: Colors.green),
                              ),
                              minimumSize: Size(double.infinity, 50 * scaleFactor),
                            ),
                            child: Text("View Cart",
                                style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16 * scaleFactor)),
                          ),
                        ),
                      SizedBox(width: totalQuantity > 0 ? 10 * scaleFactor : 0),
                      Expanded(
                        child: totalQuantity == 0
                            ? ElevatedButton(
                          onPressed: () {
                            setModalState(() {
                              product['cartQuantity'] = 1;
                              _updateCart(
                                  product['id'], product, 1, baseGrams);
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9 * scaleFactor),
                            ),
                            minimumSize: Size(double.infinity, 50 * scaleFactor),
                          ),
                          child: Text("Add to Cart",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16 * scaleFactor)),
                        )
                            : Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(9 * scaleFactor),
                            border: Border.all(color: Colors.green, width: 2),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              IconButton(
                                icon: Icon(Icons.remove,
                                    color: Colors.green, size: 20 * scaleFactor),
                                onPressed: () {
                                  setModalState(() {
                                    if (totalQuantity > 1) {
                                      _updateCart(product['id'], product,
                                          totalQuantity - 1, baseGrams);
                                    } else {
                                      _removeFromCart(product);
                                    }
                                  });
                                },
                              ),
                              Text("$totalQuantity",
                                  style: TextStyle(
                                      fontSize: 18 * scaleFactor,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green)),
                              IconButton(
                                icon: Icon(Icons.add,
                                    color: Colors.green, size: 20 * scaleFactor),
                                onPressed: () {
                                  setModalState(() {
                                    _updateCart(product['id'], product,
                                        totalQuantity + 1, baseGrams);
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
    if (userCustomerId == null) return;

    DocumentReference productRef = FirebaseFirestore.instance
        .collection('customers')
        .doc(userCustomerId)
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
    if (userCustomerId == null) return;

    String productId = product['id']; // Unique product ID

    // 🔹 Update UI immediately
    setState(() {
      cartItems.remove(productId);
    });

    try {
      await FirebaseFirestore.instance
          .collection('customers')
          .doc(userCustomerId)

          .collection('cart')
          .doc(productId)
          .delete(); // ✅ Remove item from Firestore

      print("🗑 Removed ${product['name']} from Firestore!");
    } catch (e) {
      print("❌ Error removing from cart: $e");
    }
  }


}