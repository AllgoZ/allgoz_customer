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
    _fetchTypes(); // Fetch left sidebar content
    _fetchCart();   // ✅ Start listening to Firestore cart updates
    _fetchUserPhoneNumber();
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
        updatedCart[doc.id] = doc['quantity'];
      }
      setState(() {
        cartItems = updatedCart; // ✅ UI updates whenever cart changes
      });
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




  Future<void> _updateCart(String productId, Map<String, dynamic> product, int quantity) async {
    if (userPhoneNumber == null) {
      print("❌ No userPhoneNumber found! Cart cannot be updated.");
      return;
    }

    DocumentReference cartRef = FirebaseFirestore.instance
        .collection('customers')
        .doc(userPhoneNumber)
        .collection('cart')
        .doc(productId);

    if (quantity > 0) {
      print("🛒 Adding ${product['name']} (Qty: $quantity) to Firestore...");
      await cartRef.set({
        'name': product['name'],
        'price': product['price'],
        'quantity': quantity,
        'grams': quantity * 100, // ✅ Convert to grams
        'imageURL': product['imageURL'],
        'unit': product['unit'],
      }, SetOptions(merge: true));
      print("✅ Successfully added to Firestore!");
    } else {
      print("🗑 Removing ${product['name']} from Firestore...");
      await cartRef.delete();
      print("✅ Removed from Firestore!");
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

          /// 🔹 Right Side (Products)
          Expanded(
            child: products.isEmpty
                ? Center(child: Text("No products found", style: TextStyle(fontSize: 18)))
                : GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.53, // 🔹 Adjusted aspect ratio to prevent overflow
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];

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

                        // 🔹 Product Name (Multi-line)
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

                        // 🔹 Weight / Quantity

                        Text(
                          "${product['quantity']} ${product['unit']}", // ✅ Show quantity & unit dynamically
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),

                        // 🔹 Price & Discounted Price
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "₹${product['price']}",
                              style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(width: 5),
                            if (product['originalPrice'] != null) // 🔹 Strike-through price if exists
                              Text(
                                "₹${product['originalPrice']}",
                                style: TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),

                        Spacer(), // 🔹 Push Add to Cart button to bottom

                        // 🔹 Add to Cart Button
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: ElevatedButton(
                            onPressed: () {
                              _addToCart(product);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9),
                              ),
                            ),
                            child: Text("Add to Cart"),
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
    );
  }

  /// ✅ Product Card UI
  /// ✅ Product Card UI
  Widget _buildProductCard(Map<String, dynamic> product) {
    return GestureDetector(
      onTap: () {
        print("🛒 Viewing Product: ${product['name']}"); // ✅ Debug product tap
        _showBottomSheet(context, product);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 5, vertical: 5), // ✅ Added padding
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                    child: Image.network(
                      product['imageURL'],
                      height: 110, // ✅ Adjusted height
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 5,
                    left: 5,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "${product['discount']}% Off",
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Column(
                  children: [
                    Text(
                      product['name'],
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis, // ✅ Prevent overflow
                    ),
                    SizedBox(height: 4),

                    // 🔹 Display Dynamic Quantity & Unit from Firestore
                    Text(
                      "${product['quantity']} ${product['unit']}", // ✅ Show quantity & unit dynamically
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),

                    SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "₹${product['price']}",
                          style: TextStyle(color: Colors.green, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 5),
                        Text(
                          "₹${product['originalPrice'] ?? 'null'}",
                          style: TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    ElevatedButton(
                      onPressed: () {
                        _addToCart(product); // ✅ Calls the updated function
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        minimumSize: Size(double.infinity, 38), // ✅ Full-width button
                      ),
                      child: Text(
                        "Add to Cart",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
    _updateCart(productId, product, newQuantity);
  }

















  /// ✅ Show Bottom Modal Sheet (Product Details)
  void _showBottomSheet(BuildContext context, Map<String, dynamic> product) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            product['grams'] ??= 1000; // Default to 1000g

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 🔹 Favorite Button
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: Icon(
                        (product['isFavorite'] ?? false)
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: (product['isFavorite'] ?? false)
                            ? Colors.red
                            : Colors.grey,
                      ),
                      onPressed: () {
                        setModalState(() {
                          product['isFavorite'] = !(product['isFavorite'] ?? false);
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
                  Text(product['name'],
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  Text('₹${product['price']}',
                      style: TextStyle(color: Colors.green, fontSize: 16)),
                  Text("${product['quantity']} ${product['unit']}",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),

                  // 🔹 Product Rating
                  if (product.containsKey('rating') && product.containsKey('reviews'))
                    Text('Rating: ⭐${product['rating']} ${product['reviews']}'),

                  SizedBox(height: 10),

                  // 🔹 Quantity Selection (100g increments)
                  Text("Quantity in grams", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove_circle_outline),
                        onPressed: () {
                          setModalState(() {
                            if (product['grams'] > 100) {
                              product['grams'] -= 100;
                            }
                          });
                        },
                      ),
                      Text('${product['grams']} g',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: Icon(Icons.add_circle_outline),
                        onPressed: () {
                          setModalState(() {
                            product['grams'] += 100;
                          });
                        },
                      ),
                    ],
                  ),

                  SizedBox(height: 10),

                  // 🔹 Add to Cart Button
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: ElevatedButton(
                      onPressed: () {
                        _addToCart(product); // ✅ Calls Firestore update
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                      child: Text("Add to Cart"),
                    ),
                  ),

                ],
              ),
            );
          },
        );
      },
    );
  }

}
