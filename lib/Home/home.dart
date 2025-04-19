import 'package:allgoz/Account/account.dart';
import 'package:allgoz/Cart/cart.dart';
import 'package:allgoz/Favorite/favorite.dart';
import 'package:allgoz/Home/Categories/category_list.dart';
import 'package:allgoz/Orders/my_orders.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart' as loc;
import 'package:flutter/services.dart'; // For SystemNavigator.pop
import 'dart:io'; // For Platform check


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String> bannerImages = [];
  int _currentPage = 0;
  String searchQuery = '';
  loc.Location location = loc.Location();
  List<Map<String, dynamic>> categories = [];

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkLocationStatus();
    _fetchCategories();
    _fetchBanners();
  }

  Future<void> _checkLocationStatus() async {
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      _showLocationBottomSheet();
    }
  }

  Future<void> _fetchCategories() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('categories').get();
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
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => FavoritesScreen()));
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
              Image.network(imagePath, height: width * 0.2, fit: BoxFit.cover),
              const SizedBox(height: 10),
              Text(
                displayTitle,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: width * 0.04, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
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
        SystemNavigator.pop(); // ✅ Just minimize the app
        return false;
      },

      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false, // Removes back button icon
          backgroundColor: const Color(0xFF4A90E2),
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
              icon: const Icon(Icons.video_collection_rounded, color: Colors.white),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.help_outline, color: Colors.white),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => MyOrdersScreen()));
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
                    childAspectRatio: 0.9,
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
