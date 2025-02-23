import 'package:allgoz/Account/account.dart';
import 'package:allgoz/Cart/cart.dart';
import 'package:allgoz/Home/home.dart';
import 'package:flutter/material.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Map<String, dynamic>> favoriteItems = [
    {
      "name": "Spinach/பசலைக் கீரை",
      "image": "assets/product/Cabbage.jpg",
      "price": 30,
      "originalPrice": 50,
      "discount": "40% Off",
      "quantity": 1,
      "grams": 1000,
      "rating": 4.5,
      "reviews": "(150)",
    },
    {
      "name": "Broccoli",
      "image": "assets/product/Broccoli.jpg",
      "price": 50,
      "originalPrice": 70,
      "discount": "28% Off",
      "quantity": 2,
      "grams": 500,
      "rating": 4.5,
      "reviews": "(150)",
    },
  ];

  List<Map<String, dynamic>> selectedProducts = [];
  List<Map<String, dynamic>> cartItems = [];  // ✅ Holds all items added to the cart

  int selectedCategory = 0;

  int cartItemCount = 0;
  double totalAmount = 0;


  void _removeFromFavorites(int index) {
    setState(() {
      favoriteItems.removeAt(index);
    });
  }
  int _selectedIndex = 2; // Default to Cart

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => HomePage()));
    }
    else if (index == 1) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => CartScreen()));
    } else if (index == 3) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => AccountScreen()));
    }
  }
  void _showBottomSheet(BuildContext context, Map<String, dynamic> product) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),

          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Product Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              Divider(thickness: 1),
              ListTile(
                leading: Image.asset(product['image'], width: 50),
                title: Text(product['name'], style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${product['grams']} g'),
                trailing: Text('₹${product['price']}'),
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                  minimumSize: Size(double.infinity, 50),
                ),
                child: Text('Add to Cart'),
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF4A90E2),
        title: Text('My Favorites'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.video_collection_rounded, color: Colors.white),
            onPressed: () {

            },
          ),
        ],
      ),
      body: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.59,
        ),
        itemCount: favoriteItems.length,
        itemBuilder: (context, index) {
          final item = favoriteItems[index];
          return GestureDetector(
            onTap: () => _showBottomSheet(context, item),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              child: SizedBox(
                height: 120, // 5.5 cm equivalent in logical pixels
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            item['image'],
                            height: 150,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              item['discount'],
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          left:110,
                          child: IconButton(
                            icon: Icon(Icons.favorite, color: Colors.red),
                            onPressed: () => _removeFromFavorites(index),
                          ),
                        ),
                      ],
                    ),

                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Text(item['name'], style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center,maxLines: 2,overflow: TextOverflow.ellipsis, ),
                          Text('${item['grams']} g'),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('₹${item['price']}'),
                          SizedBox(width:8),


                          Text(
                            '₹${item['originalPrice']}',
                            style: TextStyle(decoration: TextDecoration.lineThrough, color: Colors.green),
                          ),
                            ],
                          ),

                        ],

                      ),
                    ),

                    Spacer(),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                      ),
                      child: Text('Add to Cart'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Color(0xFF4A90E2),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        onTap: _onItemTapped,
      ),
    );
  }
}