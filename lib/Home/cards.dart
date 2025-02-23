import 'package:flutter/material.dart';
import 'package:allgoz/main.dart';

class CardsPage extends StatelessWidget {
  final String categoryName;

  const CardsPage({super.key, required this.categoryName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF1C85EA),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Center(
          child: Text(
            categoryName,
            style: TextStyle(fontFamily: 'Majalla', fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 360,
              height: 39,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey),
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Icon(Icons.search),
                  ),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.mic),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCategorySection('Departmental Store', 2),
                    _buildCategorySection('Fruits Store', 2),
                    _buildCategorySection('Vegetable Store', 2),
                    _buildCategorySection('Vegetable Store', 2),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Color(0xFF1C85EA),
        unselectedItemColor: Colors.black,
        backgroundColor: Colors.white,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.location_on_outlined), label: 'Location'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: 'Favorites'),
          BottomNavigationBarItem(icon: Icon(Icons.camera_alt_outlined), label: 'Camera'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Account'),
        ],
      ),
    );
  }

  Widget _buildCategorySection(String title, int columns) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontFamily: 'Majalla', fontSize: 25, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 150 / 230,
          ),
          itemCount: 6,
          itemBuilder: (context, index) {
            bool isAddedToFavorites = false;
            return StatefulBuilder(
              builder: (context, setState) {
                return GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/Home/storedetails');
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(0xFFD7F0FF),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child: Image.asset('assets/product/fruits.png', height: 100, fit: BoxFit.cover),
                        ),
                        SizedBox(height: 8),
                        Text('Store Name', style: TextStyle(fontFamily: 'Majalla', fontSize: 30)),
                        Text('Periyakarattupatti', style: TextStyle(fontFamily: 'Majalla', fontSize: 25, color: Colors.grey)),
                        SizedBox(height: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isAddedToFavorites ? Colors.green[500]: Color(0xFF1C85EA),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                            minimumSize: Size(117, 34),
                          ),
                          onPressed: () {
                            setState(() {
                              isAddedToFavorites = !isAddedToFavorites;
                            });
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isAddedToFavorites ? 'Added' : 'Add to Favourites',
                                style: TextStyle(fontFamily: 'Majalla', fontSize: 20, color: Colors.white),
                              ),
                              if (isAddedToFavorites)
                                Icon(Icons.check, color: Colors.white, size: 20),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
