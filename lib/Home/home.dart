import 'package:allgoz/Account/Contact%20Support/contact_support.dart';
import 'package:allgoz/Account/account.dart';
import 'package:allgoz/Cart/cart.dart';
import 'package:allgoz/Favorite/favorite.dart';
import 'package:allgoz/Home/Categories/category_list.dart';
import 'package:allgoz/Home/search_product_card.dart';
import 'package:allgoz/Orders/my_orders.dart';
import 'package:allgoz/services/youtube_player_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart' as loc;
import 'package:flutter/services.dart'; // For SystemNavigator.pop
import 'dart:io'; // For Platform check
import 'dart:async';
import 'dart:ui'; // for ImageFilter (blur)
import 'package:shared_preferences/shared_preferences.dart';
import 'package:allgoz/services/tutorial_service.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {


  GlobalKey videoIconKey = GlobalKey();

  List<String> bannerImages = [];
  int _currentPage = 0;
  String searchQuery = '';
  loc.Location location = loc.Location();
  List<Map<String, dynamic>> categories = [];
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Map<String, dynamic>> allProducts = [];
  List<Map<String, dynamic>> searchResults = [];
  String? userCustomerId;
  Map<String, int> cartItems = {};
  late PageController _pageController;
  Timer? _bannerTimer;
  Timer? _searchDebounce;
  final TutorialService tutorialService = TutorialService();
  List<TargetFocus> tutorialTargets = [];
  TutorialCoachMark? tutorialCoachMark;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _startTutorialFlow(); // 👈 custom method
    _fetchCategories();
    _fetchUserCustomerId();
    _fetchAllProducts();
    _fetchBanners();
    _bannerTimer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (bannerImages.isNotEmpty && _pageController.hasClients) {
        int nextPage = (_currentPage + 1) % bannerImages.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });

  }




  @override
  void dispose() {
    _pageController.dispose();
    _bannerTimer?.cancel();
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }



  void _addUserToPromotion() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return;

    final String docId = 'google_${user.email!.replaceAll('.', '_').replaceAll('@', '_')}';
    final firestore = FirebaseFirestore.instance;

    try {
      final offerDoc = await firestore.collection('offers').doc('first50Users').get();
      if (!offerDoc.exists || !(offerDoc['isActive'] ?? false)) return;

      final promoDoc = await firestore.collection('promotions').doc(docId).get();
      if (promoDoc.exists) return;

      final totalPromoUsers = await firestore.collection('promotions').get();
      if (totalPromoUsers.docs.length >= (offerDoc['maxUsers'] ?? 50)) return;

      await firestore.collection('promotions').doc(docId).set({
        'joinedAt': FieldValue.serverTimestamp(),
        'discountUsedCount': 0,
        'totalDiscountedAmount': 0,
      });

      print("✅ Added to promotions");
    } catch (e) {
      print("❌ Error adding to promotions: $e");
    }
  }





  void _startTutorialFlow() async {
    final prefs = await SharedPreferences.getInstance();

    bool tutorialDone = prefs.getBool('tutorial_shown') ?? false;

    if (!tutorialDone) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showTutorial(prefs);
      });
    } else {
      _checkLocationStatus(); // ✅ Skip tutorial, go to location
      _addUserToPromotion();
    }
  }

  void _showTutorial(SharedPreferences prefs) {
    tutorialTargets = [
      TargetFocus(
        identify: "video_icon",
        keyTarget: videoIconKey,
        alignSkip: Alignment.topRight,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    "Tap here to watch the intro video!,\n"
                        "Appஐ எப்படி பயன்படுத்துவது என்று தெரிந்து கொள்ள இந்த வீடியோ பட்டனை அழுத்தவும்",

                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),

                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    tutorialCoachMark?.skip();
                  },
                  child: const Text(
                    "SKIP",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ];

    tutorialCoachMark = TutorialCoachMark(
      targets: tutorialTargets,
      colorShadow: Colors.black,
      paddingFocus: 10,
      onClickTarget: (_) async {
        tutorialCoachMark?.finish();
        final prefs = await SharedPreferences.getInstance();
        prefs.setBool('tutorial_shown', true);

        await showDialog(
          context: context,
          barrierColor: Colors.transparent,
          builder: (_) => const YoutubePlayerOverlay(fieldName: 'homepage'),
        );

        _checkLocationStatus();
      },
      onSkip: () {
        prefs.setBool('tutorial_shown', true);
        _checkLocationStatus();
        return true;
      },
      onFinish: () {
        prefs.setBool('tutorial_shown', true);
        return true;
      },
    )..show(context: context);
  }


  Future<void> _checkLocationStatus() async {
    final prefs = await SharedPreferences.getInstance();
    bool locationShown = prefs.getBool('location_shown') ?? false;

    if (locationShown) return;

    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      _showLocationBottomSheet();
      prefs.setBool('location_shown', true);
    }
  }


  Future<void> _fetchCategories() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('categories')
          .orderBy('order')
          .get(); // ✅ New line with orderBy

      setState(() {
        categories = snapshot.docs.map((doc) => {
          'id': doc.id,
          'name': doc['name'],
          'image': doc['image'],
        }).toList();
      });
    } catch (e) {
      print("Error fetching categories: $e");
    }
  }

  Future<void> _fetchBanners() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('banners').get();
      setState(() {
        bannerImages = snapshot.docs
            .map((doc) => doc['image_url'] as String)
            .where((url) => url.isNotEmpty)
            .toList();
      });

      print("✅ Loaded banners: $bannerImages");
    } catch (e) {
      print("❌ Error fetching banners: $e");
    }
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return; // prevent reload if tapped on current page
    setState(() => _selectedIndex = index);

    if (index == 1) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => CartScreen()));
    } else if (index == 2) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MyOrdersScreen()));
    } else if (index == 3) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AccountScreen()));
    }
  }

  void _showLocationBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_off, size: 50, color: Colors.red),
            const SizedBox(height: 10),
            const Text(
              'Your device location is off',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Please enable location permission for better delivery experience',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              onPressed: () async {
                bool serviceEnabled = await location.requestService();
                if (serviceEnabled) {
                  Navigator.pop(context);
                  _checkLocationStatus();
                }
              },
              child: const Text('Continue', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Search your Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(String displayTitle, String imagePath, String categoryId, BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: () {
        String categoryKey = displayTitle.split('/')[0].trim();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryScreen(categoryName: categoryKey),
          ),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 12,
        shadowColor: Colors.black45,
        child: Container(
          width: width * 0.42,
          height: width * 0.42,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 6))],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.network(imagePath, height: width * 0.23, fit: BoxFit.cover),
              const SizedBox(height: 10),
              Text(
                displayTitle,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: width * 0.038, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _fetchUserCustomerId() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      setState(() {
        userCustomerId =
        'google_${user.email!.replaceAll('.', '_').replaceAll('@', '_')}';
      });
      _fetchCart();
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
        int quantity = doc['quantity'] ?? 0;
        updatedCart[doc.id] = quantity;
      }

      setState(() {
        cartItems = updatedCart;
      });
    });
  }

  Future<void> _fetchAllProducts() async {
    try {
      QuerySnapshot snapshot =
      await FirebaseFirestore.instance.collectionGroup('products').get();
      setState(() {
        allProducts = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'name': data['name'],
            'price': data['price'],
            'imageURL': data['imageURL'],
            'discount': data['discount'] ?? 0,
            'quantity': int.tryParse(data['quantity'].toString()) ?? 1,
            'unit': data['unit'] ?? 'N/A',
            'grams': int.tryParse(data['grams'].toString()) ?? 0,
            'available': data['available'] ?? true,
            'description': data['description'] ?? '',
            'brand': data['brand'] ?? '',
            'tags': List<String>.from(data['tags'] ?? []),
            'quantityInKg': data['quantityInKg'] ?? '',
          };
        }).toList();
      });
    } catch (e) {
      print('❌ Error fetching products: $e');
    }
  }

  void _performSearch(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        searchQuery = query;
        final lowerQuery = query.toLowerCase();
        searchResults = allProducts.where((p) {
          final name = p['name'].toString().toLowerCase();
          final brand = p['brand'].toString().toLowerCase();
          final tags = (p['tags'] as List<dynamic>)
              .map((tag) => tag.toString().toLowerCase())
              .toList();
          return name.contains(lowerQuery) ||
              brand.contains(lowerQuery) ||
              tags.any((tag) => tag.contains(lowerQuery));
        }).toList();
      });
    });
  }

  Future<void> _updateCart(String productId, Map<String, dynamic> product,
      int totalQuantity, int baseGrams) async {
    if (userCustomerId == null) return;

    int totalGrams = totalQuantity * baseGrams;

    setState(() {
      if (totalQuantity > 0) {
        cartItems[productId] = totalQuantity;
      } else {
        cartItems.remove(productId);
      }
    });

    DocumentReference cartRef = FirebaseFirestore.instance
        .collection('customers')
        .doc(userCustomerId)
        .collection('cart')
        .doc(productId);

    try {
      if (totalQuantity > 0) {
        await cartRef.set({
          'name': product['name'],
          'price': product['price'],
          'quantity': totalQuantity,
          'grams': totalGrams,
          'imageURL': product['imageURL'],
          'unit': product['unit'],
          'totalQuantity': totalQuantity,
        }, SetOptions(merge: true));
      } else {
        await cartRef.delete();
      }
    } catch (e) {
      print('❌ Error updating cart: $e');
    }
  }

  void _removeFromCart(Map<String, dynamic> product) async {
    if (userCustomerId == null) return;

    String productId = product['id'];

    setState(() {
      cartItems.remove(productId);
    });

    try {
      await FirebaseFirestore.instance
          .collection('customers')
          .doc(userCustomerId)
          .collection('cart')
          .doc(productId)
          .delete();
    } catch (e) {
      print('❌ Error removing from cart: $e');
    }
  }

  void _addToCart(Map<String, dynamic> product) {
    if (userCustomerId == null) return;
    String productId = product['id'];
    int newQuantity = (cartItems[productId] ?? 0) + 1;
    int baseGrams = (product['unit'] == "Kg") ? 1000 : 1;
    _updateCart(productId, product, newQuantity, baseGrams);
  }

  void _showBottomSheet(BuildContext context, Map<String, dynamic> product) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = screenWidth / 390;

    // Hide keyboard when opening the bottom sheet
    _searchFocusNode.unfocus();

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
                children: [
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
                                  color: Colors.green,
                                  fontSize: 16 * scaleFactor)),
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
                          if ((product['brand'] != null &&
                              product['brand'].toString().isNotEmpty) ||
                              (product['description'] != null &&
                                  product['description'].toString().isNotEmpty))
                            Container(
                              width: double.infinity,
                              margin: EdgeInsets.only(top: 20 * scaleFactor),
                              padding: EdgeInsets.all(16 * scaleFactor),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF6F8FA),
                                borderRadius:
                                BorderRadius.circular(16 * scaleFactor),
                                boxShadow: const [
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
                                  if (product['brand'] != null &&
                                      product['brand'].toString().isNotEmpty)
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("Brand",
                                            style: TextStyle(
                                              fontSize: 14 * scaleFactor,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey[700],
                                            )),
                                        const SizedBox(height: 4),
                                        Text(product['brand'],
                                            style: TextStyle(
                                                fontSize: 15 * scaleFactor,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black)),
                                        const SizedBox(height: 16),
                                      ],
                                    ),
                                  if (product['description'] != null &&
                                      product['description'].toString().isNotEmpty)
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("Highlights",
                                            style: TextStyle(
                                              fontSize: 14 * scaleFactor,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey[700],
                                            )),
                                        const SizedBox(height: 6),
                                        ...product['description']
                                            .toString()
                                            .split('•')
                                            .where((line) => line.trim().isNotEmpty)
                                            .map((point) => Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 4),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text("• ",
                                                  style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.black)),
                                              Expanded(
                                                child: Text(
                                                  point.trim(),
                                                  style: const TextStyle(
                                                      fontSize: 14,
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
                  const SizedBox(height: 10),
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
                                MaterialPageRoute(
                                    builder: (context) => CartScreen()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9 * scaleFactor),
                                side: const BorderSide(color: Colors.green),
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
                              borderRadius:
                              BorderRadius.circular(9 * scaleFactor),
                            ),
                            minimumSize:
                            Size(double.infinity, 48 * scaleFactor),
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
                            borderRadius:
                            BorderRadius.circular(9 * scaleFactor),
                            border:
                            Border.all(color: Colors.green, width: 2),
                          ),
                          child: Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceEvenly,
                            children: [
                              IconButton(
                                icon: Icon(Icons.remove,
                                    color: Colors.green,
                                    size: 18 * scaleFactor),
                                onPressed: () {
                                  setModalState(() {
                                    if (totalQuantity > 1) {
                                      _updateCart(
                                          product['id'],
                                          product,
                                          totalQuantity - 1,
                                          baseGrams);
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
                                    color: Colors.green,
                                    size: 20 * scaleFactor),
                                onPressed: () {
                                  setModalState(() {
                                    _updateCart(
                                        product['id'],
                                        product,
                                        totalQuantity + 1,
                                        baseGrams);
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

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final int cartCount =
        cartItems.values.fold(0, (sum, item) => sum + item);

    return WillPopScope(
      onWillPop: () async {
        // If searching or the search field has focus, clear search instead of exiting
        if (searchQuery.isNotEmpty || _searchFocusNode.hasFocus) {
          setState(() {
            searchQuery = '';
            _searchController.clear();
          });
          _searchFocusNode.unfocus();
          return false;
        }

        SystemNavigator.pop();
        return false; // ✅ must return a bool
      },

      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false, // Removes default back button
          backgroundColor: const Color(0xFF4A90E2),
          leading: IconButton(
            icon: const Icon(Icons.account_circle, color: Colors.white),
            onPressed: () {
              Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => AccountScreen(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    const begin = Offset(1.0, 0.0); // from right to left
                    const end = Offset.zero;
                    const curve = Curves.easeInOut;

                    final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                    final offsetAnimation = animation.drive(tween);

                    return SlideTransition(position: offsetAnimation, child: child);
                  },
                ),
              );
            },
          ),
          title: Text(
            'AllgoZ',
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width * 0.06,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              key: videoIconKey,
              icon: const Icon(Icons.video_collection_rounded, color: Colors.white),
              onPressed: () {
                showDialog(
                  context: context,
                  barrierColor: Colors.transparent,
                  builder: (_) => const YoutubePlayerOverlay(fieldName: 'homepage'),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.help_outline, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ContactSupportScreen()),
                );
              },
            ),
          ],
        ),
        body: Padding(
          padding: EdgeInsets.all(width * 0.04),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: width * 0.04),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: _performSearch,
                  decoration: const InputDecoration(
                      hintText: 'Search...',
                      border: InputBorder.none,
                      icon: Icon(Icons.search)),
                ),
              ),
              SizedBox(height: height * 0.02),
              if (searchQuery.isEmpty) ...[
                Container(
                  height: height * 0.23,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFB0B1B4), width: 2),
                    color: Colors.grey[300],
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))
                    ],
                  ),
                  child: bannerImages.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : PageView.builder(
                    controller: _pageController,
                    itemCount: bannerImages.length,
                    onPageChanged: (index) => setState(() => _currentPage = index),
                    itemBuilder: (context, index) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          bannerImages[index],
                          fit: BoxFit.cover,
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: height * 0.01),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    bannerImages.length,
                        (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentPage == index ? Colors.black : Colors.grey,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: height * 0.02),
              ],
              Expanded(
                child: searchQuery.isNotEmpty
                    ? GridView.builder(
                  itemCount: searchResults.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: width * 0.03,
                    mainAxisSpacing: width * 0.03,
                    childAspectRatio: 0.64,
                  ),
                  itemBuilder: (context, index) {
                    final product = searchResults[index];
                    final productId = product['id'];
                    final cartQuantity = cartItems[productId] ?? 0;
                    final isAvailable = product['available'] ?? true;
                    final int baseQuantity =
                        int.tryParse(product['quantity'].toString()) ?? 1;
                    return SearchProductCard(
                      product: product,
                      cartQuantity: cartQuantity,
                      onAdd: () {
                        int baseGrams =
                        (product['unit'] == "Kg") ? 1000 : baseQuantity;
                        _updateCart(
                            productId, product, cartQuantity + 1, baseGrams);
                      },
                      onRemove: () {
                        int baseGrams =
                        (product['unit'] == "Kg") ? 1000 : baseQuantity;
                        if (cartQuantity > 1) {
                          _updateCart(productId, product,
                              cartQuantity - 1, baseGrams);
                        } else {
                          _removeFromCart(product);
                        }
                      },
                      onTap: isAvailable
                          ? () => _showBottomSheet(context, product)
                          : null,
                    );
                  },
                )
                    : GridView.builder(
                  itemCount: categories.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: width * 0.03,
                    mainAxisSpacing: width * 0.03,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    return _buildCategoryCard(
                      categories[index]['name'],
                      categories[index]['image'],
                      categories[index]['id'],
                      context,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          selectedItemColor: const Color(0xFF4A90E2),
          unselectedItemColor: Colors.grey,
          onTap: _onItemTapped,
          items: [
            const BottomNavigationBarItem(
                icon: Icon(Icons.shopping_bag), label: 'Home'),
            BottomNavigationBarItem(
              icon: Stack(
                children: [
                  const Icon(Icons.shopping_cart),
                  if (cartCount > 0)
                    Positioned(
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                            color: Colors.red, shape: BoxShape.circle),
                        constraints: const BoxConstraints(
                            minWidth: 16, minHeight: 16),
                        child: Text(
                          '$cartCount',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 10),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              label: 'Cart',
            ),
            const BottomNavigationBarItem(
                icon: Icon(Icons.delivery_dining), label: 'My Order'),
          ],
        ),
      ),

    );
  }
}