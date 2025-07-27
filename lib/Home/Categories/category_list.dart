import 'package:allgoz/Cart/Checkout/checkout.dart';
import 'package:allgoz/services/youtube_player_widget.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:allgoz/Cart/cart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shimmer/shimmer.dart';
import 'package:allgoz/services/sales_service.dart';
import 'dart:async';

class CategoryScreen extends StatefulWidget {
  final String categoryName; // ✅ Passed from home.dart
  const CategoryScreen({super.key, required this.categoryName});

  @override
  _CategoryScreenState createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  TextEditingController _searchController = TextEditingController();
  String searchText = "";
  List<String> rollingHints = [
    'Search for "Tomato"',
    'Search for "Beetroot"',
    'Search for "Apple"',
    'Search for "Onion"',
    'Search for "Milk"',
  ];

  int _currentHintIndex = 0;
  Timer? _hintTimer;

  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();
  bool _isFetchingMore = false;
  bool _hasMoreProducts = true;
  DocumentSnapshot? _lastDocument;
  double _cartTotal = 0.0;
  final double freeDeliveryThreshold = 99.0;

  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> products = [];
  String selectedType = ""; // Track selected type
  String? userCustomerId;
  DocumentSnapshot? lastVisibleProduct;
  bool isLoadingMore = false;
  bool hasMore = true;
  final int perPage = 10;

  Map<String, int> cartItems = {}; // ✅ Store productId and quantity

  @override
  void initState() {
    super.initState();
    _fetchUserCustomerId();
    _fetchCart();
    _fetchTypes();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
        if (!_isFetchingMore && _hasMoreProducts) {
          _fetchMoreProducts();
        }
      }
    });
    _startHintRoller();
  }

  void _startHintRoller() {
    _hintTimer = Timer.periodic(Duration(seconds: 2), (timer) {
      setState(() {
        _currentHintIndex = (_currentHintIndex + 1) % rollingHints.length;
      });
    });
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    _searchController.dispose();
    super.dispose();


  }

  Future<void> _fetchMoreProducts() async {
    if (_lastDocument == null || !_hasMoreProducts) return;

    setState(() {
      _isFetchingMore = true;
    });

    try {
      Query query = FirebaseFirestore.instance
          .collectionGroup('products')
          .where('category', isEqualTo: widget.categoryName)
          .where('type', isEqualTo: selectedType)
          .startAfterDocument(_lastDocument!)
          .limit(10);

      final querySnapshot = await query.get();

      if (querySnapshot.docs.isNotEmpty) {
        _lastDocument = querySnapshot.docs.last;
      } else {
        _hasMoreProducts = false;
      }

      List<Map<String, dynamic>> newProducts = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'name': data['name'],
          'price': data['price'],
          'imageURL': data['imageURL'],
          'discount': data['discount'] ?? 0,
          'quantity': int.tryParse(data['quantity'].toString()) ?? 1,
          'unit': data['unit'] ?? "N/A",
          'grams': int.tryParse(data['grams'].toString()) ?? 0,
          'cartQuantity': cartItems[doc.id] ?? 0,
          'available': data['available'] ?? true,
          'description': data['description'] ?? '',
          'brand': data['brand'] ?? '',
          'quantityInKg' : data['quantityInKg'] ??'',

        };
      }).toList();

      // ✅ Ensure sales count map is cached
      _cachedSalesMap ??= await SalesService.fetchTopSellingCounts();

      // ✅ Sort: Available first, then by sales count
      newProducts.sort((a, b) {
        if (a['available'] != b['available']) return a['available'] ? -1 : 1;
        final salesA = _cachedSalesMap![a['id']] ?? 0;
        final salesB = _cachedSalesMap![b['id']] ?? 0;
        return salesB.compareTo(salesA);
      });

      setState(() {
        products.addAll(newProducts);
        _isFetchingMore = false;
      });
    } catch (e) {
      print("❌ Error fetching more products: $e");
      setState(() {
        _isFetchingMore = false;
      });
    }
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
      double updatedTotal = 0.0;

      for (var doc in snapshot.docs) {
        int quantity = doc['quantity'] ?? 0;
        double price = (doc['price'] ?? 0).toDouble();

        updatedCart[doc.id] = quantity;
        updatedTotal += quantity * price;
      }

      setState(() {
        cartItems = updatedCart;
        _cartTotal = updatedTotal;

        // 🔥 Update product quantities in the UI if they exist in the cart
        for (var product in products) {
          if (cartItems.containsKey(product['id'])) {
            product['cartQuantity'] = cartItems[product['id']];
          }
        }
      });

      print("📢 Updated cart from Firestore: $cartItems");
      print("💰 Cart Total: ₹$_cartTotal");
    });
  }






  Widget _buildFreeDeliveryProgressBar() {
    double progress = (_cartTotal / freeDeliveryThreshold).clamp(0.0, 1.0);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Row(
            children: [

              Icon(Icons.lock, size: 13, color: Colors.orange),

              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _cartTotal >= freeDeliveryThreshold
                      ? "Free delivery unlocked!"
                      : "Add items worth ₹${(freeDeliveryThreshold - _cartTotal).toStringAsFixed(0)} to unlock free delivery",
                  style: TextStyle(fontWeight: FontWeight.w500),

                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A90E2)),
            ),
          ),
        ),
      ],
    );
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

  Map<String, int>? _cachedSalesMap; // 🔒 Cache to avoid reloading sales count

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      products = [];
      _lastDocument = null;
      _hasMoreProducts = true;
    });

    try {
      // Step 1: Fetch products from Firestore (first batch)
      Query query = FirebaseFirestore.instance
          .collectionGroup('products')
          .where('category', isEqualTo: widget.categoryName)
          .where('type', isEqualTo: selectedType)
          .limit(20); // Fast initial load

      final querySnapshot = await query.get();

      if (querySnapshot.docs.isNotEmpty) {
        _lastDocument = querySnapshot.docs.last;
      } else {
        _hasMoreProducts = false;
      }

      // Step 2: Parse Firestore products into list
      final initialProducts = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'name': data['name'],
          'price': data['price'],
          'imageURL': data['imageURL'],
          'discount': data['discount'] ?? 0,
          'quantity': int.tryParse(data['quantity'].toString()) ?? 1,
          'unit': data['unit'] ?? "N/A",
          'grams': int.tryParse(data['grams'].toString()) ?? 0,
          'cartQuantity': cartItems[doc.id] ?? 0,
          'available': data['available'] ?? true,
          'description': data['description'] ?? '',
          'brand': data['brand'] ?? '',
          'quantityInKg' : data['quantityInKg'] ??'',
        };
      }).toList();

      // Step 3: Sort by availability first (show in-stock first)
      initialProducts.sort((a, b) {
        if (a['available'] == b['available']) return 0;
        return a['available'] ? -1 : 1;
      });

      setState(() {
        products = initialProducts;
        _isLoading = false;
      });

      // Step 4: Fetch and cache sales count map (once)
      if (_cachedSalesMap == null) {
        _cachedSalesMap = await SalesService.fetchTopSellingCounts(); // From your product_sales/sales_count doc
      }

      // Step 5: Apply sales-based sorting
      final reSorted = List<Map<String, dynamic>>.from(products);

      reSorted.sort((a, b) {
        if (a['available'] != b['available']) return a['available'] ? -1 : 1;

        final salesA = _cachedSalesMap![a['id']] ?? 0;
        final salesB = _cachedSalesMap![b['id']] ?? 0;

        return salesB.compareTo(salesA); // More sold = higher
      });

      setState(() {
        products = reSorted;
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
    final filteredProducts = products.where((product) {
      return product['name'].toString().toLowerCase().contains(searchText.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A90E2),
        elevation: 4,
        automaticallyImplyLeading: true,
        title: Builder(
          builder: (context) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 1),
              child: PhysicalModel(
                elevation: 5,
                color: Colors.white,
                shadowColor: Colors.black26,
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        searchText = value;
                      });
                    },
                    style: TextStyle(fontSize: 16 * scaleFactor),
                    decoration: InputDecoration(
                      hintText: rollingHints[_currentHintIndex],
                      hintStyle: TextStyle(color: Colors.grey),
                      prefixIcon: Icon(Icons.search, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.video_collection_rounded, color: Colors.white),
            onPressed: () {
              showDialog(
                context: context,
                barrierColor: Colors.transparent,
                builder: (_) => const YoutubePlayerOverlay(fieldName: 'category'),
              );
            },
          ),
          // Uncomment when needed
          // IconButton(
          //   icon: Icon(Icons.shopping_cart, color: Colors.white),
          //   onPressed: () {
          //     Navigator.push(context, MaterialPageRoute(builder: (context) => CartScreen()));
          //   },
          // ),
        ],
      ),

      body: Row(
        children: [

          /// 🔹 Left Sidebar
          Container(
            width: screenWidth * 0.22,
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
                    padding: EdgeInsets.all(4 * scaleFactor),
                    child: Column(
                      children: [
                        Image.network(categories[index]['image'], height: 50 * scaleFactor),
                        SizedBox(height: 4 * scaleFactor),
                        Text(
                          categories[index]['name'],
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13 * scaleFactor),
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
            child: Column(
              children: [

                // 🛒 Product Grid
                Expanded(
                  child: _isLoading
                      ? GridView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(8 * scaleFactor),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: screenWidth < 500 ? 2 : 3,
                      crossAxisSpacing: 10 * scaleFactor,
                      mainAxisSpacing: 10 * scaleFactor,
                      childAspectRatio: 0.46,
                    ),
                    itemCount: 6,
                    itemBuilder: (context, index) => _buildShimmerCard(scaleFactor),
                  )
                      : filteredProducts.isEmpty
                      ? Center(child: Text("No products found"))
                      : GridView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(8 * scaleFactor),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: screenWidth < 500 ? 2 : 3,
                      crossAxisSpacing: 10 * scaleFactor,
                      mainAxisSpacing: 10 * scaleFactor,
                      childAspectRatio: 0.46,
                    ),
                    itemCount: filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = filteredProducts[index];
                        final productId = product['id'];
                        final cartQuantity = cartItems[productId] ?? 0;
                        final isAvailable = product['available'] ?? true;
// Calculate base quantity and price
                        final int baseQuantity = int.tryParse(product['quantity'].toString()) ?? 100;
                        final String unit = product['unit'] ?? 'Gram';
                        final double basePrice = (product['price'] as num).toDouble();
                        final double totalPrice = cartQuantity > 0 ? basePrice * cartQuantity : basePrice;
                        final int totalQuantity = cartQuantity > 0 ? baseQuantity * cartQuantity : baseQuantity;
                        final double quantityInKg = unit == "Kg" ? totalQuantity.toDouble() : totalQuantity / 1000;
                        final String quantityDisplay = unit == "Gram"
                            ? "$totalQuantity Gram"
                            : unit == "Kg"
                            ? "${quantityInKg.toStringAsFixed(2)} Kg"
                            : "$totalQuantity $unit";

                        return GestureDetector(
                          onTap: isAvailable ? () => _showBottomSheet(context, product) : null,
                          child: Stack(
                            children: [
                              Opacity(
                                opacity: isAvailable ? 1.0 : 0.5,
                                child: Material(
                                  elevation: 6,
                                  borderRadius: BorderRadius.circular(15),
                                  shadowColor: Colors.black.withOpacity(0.2),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    padding: EdgeInsets.all(screenWidth * 0.025),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        // Product image + discount
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
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 12 * scaleFactor,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        SizedBox(height: 6 * scaleFactor),

                                        // Name
                                        Text(
                                          product['name'],
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13 * scaleFactor,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: 4 * scaleFactor),

                                        // Quantity
                                        Text(
                                          quantityDisplay,
                                          style: TextStyle(
                                            fontSize: 14 * scaleFactor,
                                            color: Colors.grey,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),

                                        SizedBox(height: 4 * scaleFactor),

                                        // quantityInKg (visual kg format)
                                        if (product['quantityInKg'] != null && product['quantityInKg'].toString().trim().isNotEmpty)
                                          Text(
                                            product['quantityInKg'],
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14 * scaleFactor,
                                            ),
                                          ),

                                        SizedBox(height: 4 * scaleFactor),

                                        // Price
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              "₹${totalPrice.toStringAsFixed(0)}",
                                              style: TextStyle(
                                                color: Colors.green,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14 * scaleFactor,
                                              ),
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

                                        Spacer(), // 🔻 Pushes ADD/UPDATE button to bottom

                                        // Add/Update Cart
                                        isAvailable
                                            ? cartQuantity == 0
                                            ? ElevatedButton(
                                          onPressed: () {
                                            int quantity = int.tryParse(product['quantity'].toString()) ?? 1;
                                            int baseGrams = (product['unit'] == "Kg")
                                                ? 1000 * quantity
                                                : quantity;


                                            _updateCart(productId, product, 1, baseGrams);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(9),
                                              side: const BorderSide(color: Colors.green),
                                            ),
                                            minimumSize: Size(screenWidth * 0.4, screenHeight * 0.047),
                                          ),
                                          child: Text(
                                            "ADD",
                                            style: TextStyle(
                                              color: Colors.green,
                                              fontSize: 15 * scaleFactor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        )
                                            : Container(
                                          height: screenHeight * 0.047,
                                          width: screenWidth * 0.38,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(9),
                                            border: Border.all(color: Colors.green, width: 2),
                                          ),
                                          padding: EdgeInsets.symmetric(horizontal: 4 * scaleFactor),
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.remove, color: Colors.green),
                                                  iconSize: 25 * scaleFactor,
                                                  onPressed: () {
                                                    int quantity = int.tryParse(product['quantity'].toString()) ?? 1;
                                                    int baseGrams = (product['unit'] == "Kg")
                                                        ? 1000 * quantity
                                                        : quantity;

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
                                                    int quantity = int.tryParse(product['quantity'].toString()) ?? 1;
                                                    int baseGrams = (product['unit'] == "Kg")
                                                        ? 1000 * quantity
                                                        : quantity;


                                                    _updateCart(productId, product, cartQuantity + 1, baseGrams);
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                            : const SizedBox(),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              if (!isAvailable)
                                Positioned(
                                  top: 10,
                                  left: -30,
                                  child: Transform.rotate(
                                    angle: -0.785398,
                                    child: Container(
                                      width: 120,
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      color: Colors.grey,
                                      child: Center(
                                        child: Text(
                                          "OUT OF STOCK",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10 * scaleFactor,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }

                  ),
                ),
              ],
            ),
          ),

        ],
      ),

      bottomNavigationBar: cartItems.isNotEmpty
          ? Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SafeArea(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 16 * scaleFactor,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ✅ Show only if total is less than threshold
                  if (_cartTotal < freeDeliveryThreshold) ...[
                    Row(
                      children: [
                        Icon(Icons.lock, size: 13, color: Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Add items worth ₹${(freeDeliveryThreshold - _cartTotal).toStringAsFixed(0)} to unlock free delivery",
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: (_cartTotal / freeDeliveryThreshold).clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A90E2)),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // 🛒 View Items bar (always shown if cart is not empty)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${cartItems.values.fold(0, (sum, item) => sum + item)} Items",
                        style: TextStyle(
                          fontSize: 16 * scaleFactor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          _showCartModal(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: EdgeInsets.symmetric(
                            horizontal: 30 * scaleFactor,
                            vertical: 12 * scaleFactor,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          "View Items",
                          style: TextStyle(
                            fontSize: 13 * scaleFactor,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
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
                    // _buildFreeDeliveryProgressBar(),
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
                    Divider(thickness: 1 * scaleFactor),

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
    int quantity = int.tryParse(product['quantity'].toString()) ?? 1;
    int baseGrams = (product['unit'] == "Kg")
        ? 1000 * quantity
        : quantity;
// ✅ Determine grams per unit
    _updateCart(productId, product, newQuantity,baseGrams); // ✅ Pass all 4 arguments

  }













  void _showBottomSheet(BuildContext context, Map<String, dynamic> product) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = screenWidth / 390; // iPhone 12 baseline

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20 * scaleFactor)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            int totalQuantity = cartItems[product['id']] ?? 0;
            int quantity = int.tryParse(product['quantity'].toString()) ?? 1;
            int baseGrams = (product['unit'] == "Kg")
                ? 1000 * quantity
                : quantity;

            int totalGrams = totalQuantity * baseGrams;

            return Padding(
              padding: EdgeInsets.all(16.0 * scaleFactor),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🔄 Scrollable content
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Align(
                            alignment: Alignment.topRight,
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Icon(Icons.close, size: 24 * scaleFactor),
                            ),
                          ),
                          SizedBox(height: 10 * scaleFactor),

                          ClipRRect(
                            borderRadius: BorderRadius.circular(15 * scaleFactor),
                            child: Image.network(
                              product['imageURL'],
                              height: 150 * scaleFactor,
                            ),
                          ),
                          SizedBox(height: 10 * scaleFactor),
                          Text(product['name'],
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20 * scaleFactor)),
                          Text('₹${product['price']}',
                              style: TextStyle(
                                  color: Colors.green, fontSize: 16 * scaleFactor)),
                          Text("${product['quantity']} ${product['unit']}",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16 * scaleFactor,
                                  color: Colors.grey)),
                          if (totalQuantity > 0)
                            Padding(
                              padding: EdgeInsets.only(top: 10 * scaleFactor),
                              child: Text("Total: ${totalGrams}g",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16 * scaleFactor,
                                      color: Colors.blue)),
                            ),

                          // 🌟 Info Card
                          if ((product['brand'] != null && product['brand'].toString().isNotEmpty) ||
                              (product['description'] != null && product['description'].toString().isNotEmpty))
                            Container(
                              width: double.infinity,
                              margin: EdgeInsets.only(top: 20 * scaleFactor),
                              padding: EdgeInsets.all(16 * scaleFactor),
                              decoration: BoxDecoration(
                                color: Color(0xFFF6F8FA),
                                borderRadius: BorderRadius.circular(16 * scaleFactor),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  )
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (product['brand'] != null && product['brand'].toString().isNotEmpty)
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("Brand",
                                            style: TextStyle(
                                              fontSize: 14 * scaleFactor,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey[700],
                                            )),
                                        SizedBox(height: 4),
                                        Text(product['brand'],
                                            style: TextStyle(
                                                fontSize: 15 * scaleFactor,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black)),
                                        SizedBox(height: 16),
                                      ],
                                    ),

                                  if (product['description'] != null && product['description'].toString().isNotEmpty)
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("Highlights",
                                            style: TextStyle(
                                              fontSize: 14 * scaleFactor,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey[700],
                                            )),
                                        SizedBox(height: 6),
                                        ...product['description']
                                            .toString()
                                            .split('•')
                                            .where((line) => line.trim().isNotEmpty)
                                            .map((point) => Padding(
                                          padding: EdgeInsets.symmetric(vertical: 4),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text("• ",
                                                  style: TextStyle(
                                                      fontSize: 14 * scaleFactor,
                                                      color: Colors.black)),
                                              Expanded(
                                                child: Text(
                                                  point.trim(),
                                                  style: TextStyle(
                                                      fontSize: 14 * scaleFactor,
                                                      color: Colors.black),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 10 * scaleFactor),

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
                              _updateCart(product['id'], product, 1, baseGrams);
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9 * scaleFactor),
                            ),
                            minimumSize: Size(double.infinity, 48 * scaleFactor),
                          ),
                          child: Text("Add to Cart",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18 * scaleFactor)),
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
                                    color: Colors.green, size: 18 * scaleFactor),
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