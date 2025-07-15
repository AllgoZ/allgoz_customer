import 'package:allgoz/Account/Contact%20Support/contact_support.dart';
import 'package:allgoz/Account/account.dart';
import 'package:allgoz/Cart/cart.dart';
import 'package:allgoz/Favorite/favorite.dart';
import 'package:allgoz/Home/Categories/category_list.dart';
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
  late PageController _pageController;
  Timer? _bannerTimer;
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

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return WillPopScope(
      onWillPop: () async {
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
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
                ),
                child: TextField(
                  onChanged: (value) => setState(() => searchQuery = value),
                  decoration: const InputDecoration(hintText: 'Search...', border: InputBorder.none, icon: Icon(Icons.search)),
                ),
              ),
              SizedBox(height: height * 0.02),
              Container(
                height: height * 0.23,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFB0B1B4), width: 2),
                  color: Colors.grey[300],
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
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
              Expanded(
                child: GridView.builder(
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
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Cart'),
            BottomNavigationBarItem(icon: Icon(Icons.delivery_dining), label: 'My Order'),
          ],
        ),
      ),

    );
  }
}
