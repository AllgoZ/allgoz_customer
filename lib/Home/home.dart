import 'package:allgoz/Account/account.dart';
import 'package:allgoz/Cart/cart.dart';
import 'package:allgoz/Favorite/favorite.dart';
import 'package:allgoz/Home/Categories/category_list.dart';
import 'package:allgoz/Orders/my_orders.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart' as loc;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final int _currentIndex = 0;
  int _currentPage = 0;
  String searchQuery = '';
  loc.Location location = loc.Location();
  List<Map<String, dynamic>> categories = [];

  @override
  void initState() {
    super.initState();
    _checkLocationStatus();
    _fetchCategories();
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
          'id': doc.id, // ✅ Store categoryId for navigation
          'name': doc['name'],
          'image': doc['image'],
        }).toList();
      });
    } catch (e) {
      print("Error fetching categories: $e");
    }
  }


  int _selectedIndex = 0;
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 1) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => CartScreen()));
    } else if (index == 2) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => FavoritesScreen()));
    } else if (index == 3) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => AccountScreen()));
    }
  }

  void _showLocationBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_off, size: 50, color: Colors.red),
            SizedBox(height: 10),
            Text(
              'Your device location is off',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              'Please enable location permission for better delivery experience',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: Size(double.infinity, 50),
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
              child: Text('Continue', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Search your Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildCategoryCard(String displayTitle, String imagePath, String categoryId, BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Extract only the English part (before the "/")
        String categoryKey = displayTitle.split('/')[0].trim();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryScreen(categoryName: categoryKey), // ✅ Pass only English name
          ),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 12,
        shadowColor: Colors.black45,
        child: Container(
          width: 170,
          height: 180,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.network(imagePath, height: 80, fit: BoxFit.cover), // ✅ Use Network Image
              SizedBox(height: 10),
              Text(
                displayTitle, // ✅ Display full name with Tamil text
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF4A90E2),
        title: Text(
          'AllGoZ',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Poppins', color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          IconButton(icon: Icon(Icons.video_collection_rounded, color: Colors.white), onPressed: () {}),
          IconButton(icon: Icon(Icons.help_outline, color: Colors.white), onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => MyOrdersScreen()));
          }),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
                ],
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
                decoration: InputDecoration(hintText: 'Search...', border: InputBorder.none, icon: Icon(Icons.search)),
              ),
            ),
            SizedBox(height: 16),
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Color(0xFFB0B1B4), width: 2),
                color: Colors.grey[300],
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
                ],
              ),
              child: PageView(
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.asset('assets/banner/banner5.png', fit: BoxFit.cover)),
                  ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.asset('assets/banner/banner5.png', fit: BoxFit.cover)),
                  ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.asset('assets/banner/banner5.png', fit: BoxFit.cover)),
                ],
              ),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                    (index) => Container(
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: _currentPage == index ? Colors.black : Colors.grey),
                ),
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                itemCount: categories.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 13,
                  mainAxisSpacing: 13,
                  childAspectRatio: 0.9,
                ),
                itemBuilder: (context, index) {
                  return _buildCategoryCard(
                    categories[index]['name'],
                    categories[index]['image'],
                    categories[index]['id'], // ✅ Pass categoryId
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
        selectedItemColor: Color(0xFF4A90E2),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Cart'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favorites'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        onTap: _onItemTapped,
      ),
    );
  }
}
