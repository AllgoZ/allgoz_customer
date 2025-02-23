import 'package:allgoz/Cart/cart.dart';
import 'package:flutter/material.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  _CategoryScreenState createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final List<Map<String, dynamic>> categories = [
    {
      "name": "Leafy Greens/இலை கீரைகள்",
      "image": "assets/product/fruits.png",
      "products": [
        {
          "name": "Spinach/பசலைக் கீரை",
          "image": "assets/product/Cabbage.jpg",
          "price": 30,
          "originalPrice": 50,
          "discount": "40% Off",
          "quantity": 0,
          "rating": 4.5,
          "reviews": "(150)",
          "isFavorite": false
        },
        {
          "name": "Mint/புதினா",
          "image": "assets/product/Cabbage.jpg",
          "price": 15,
          "originalPrice": 25,
          "discount": "30% Off",
          "quantity": 0,
          "rating": 4.3,
          "reviews": "(80)",
          "isFavorite": false
        }
      ]
    },
    {
      "name": "Cruciferous/உண்ணக்கூடிய தாவர தண்டு",
      "image": "assets/product/Broccoli.jpg",
      "products": [
        {
          "name": "Broccoli",
          "image": "assets/product/Broccoli.jpg",
          "price": 50,
          "originalPrice": 70,
          "discount": "28% Off",
          "quantity": 0,
          "rating": 4.7,
          "reviews": "(200)",
          "isFavorite": false
        },
        {
          "name": "Cabbage/முட்டைக்கோஸ்",
          "image": "assets/product/fruits.png",
          "price": 20,
          "originalPrice": 35,
          "discount": "43% Off",
          "quantity": 0,
          "rating": 4.0,
          "reviews": "(100)",
          "isFavorite": false
        }
      ]
    }
  ];

  List<Map<String, dynamic>> selectedProducts = [];
  List<Map<String, dynamic>> cartItems = [];  // ✅ Holds all items added to the cart

  int selectedCategory = 0;

  int cartItemCount = 0;
  double totalAmount = 0;


  @override
  void initState() {
    super.initState();
    selectedProducts = categories[0]['products'];  // ✅ Default products for the first category
  }

  void _updateCart() {
    setState(() {

      cartItemCount = cartItems.fold(0, (sum, item) => sum + (item['quantity'] as int));  // ✅ Sum from all categories
      totalAmount = cartItems.fold(0, (sum, item){
        double pricePerGram = item['price'] / 1000; // Price per gram
        int grams = item['grams'] ?? 1000; // Default 1kg if not set
        return sum + (pricePerGram * grams * item['quantity']);
      });
    });
  }
  void _showCart(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: cartItems.length,
                itemBuilder: (context, index) {
                  final item = cartItems[index];
                  return ListTile(
                    leading: Image.asset(item['image'], width: 50),
                    title: Text(item['name']),
                    subtitle: Text('₹${(item['price'] * item['quantity'])}'),
                    trailing: Text('Qty: ${item['quantity']}'),
                  );
                },
              ),
            ),

            // ✅ Move to Cart Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close the bottom sheet
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CartScreen()), // ✅ Navigate to CartScreen
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),  // ✅ Rounded corners
                  ),
                  minimumSize: Size(double.infinity, 50),  // ✅ Full-width button
                ),
                child: Text(
                  'Move to Cart',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );
      },
    );
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
            // ✅ Initialize grams if not set (default 1000g if quantity is 1)
            product['grams'] ??= product['quantity'] > 0 ? 1000 : 1000;

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
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
                        setState(() {});
                        _updateCart();
                      },
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.asset(
                      product['image'],
                      height: 150,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(product['name'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),

                  // ✅ Dynamic Price Based on Grams
                  Text(
                    '₹${((product['price'] / 1000) * product['grams']).toStringAsFixed(2)}',
                    style: TextStyle(color: Colors.green, fontSize: 16),
                  ),

                  Text('Rating: ⭐${product['rating']} ${product['reviews']}'),
                  SizedBox(height: 10),

                  // 🔢 Quantity in Grams Section
                  Text(
                    "Quantity in grams",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove_circle_outline),
                        onPressed: () {
                          setModalState(() {
                            if (product['grams'] > 100) {
                              product['grams'] -= 100; // Decrease by 100g
                            }
                          });
                          setState(() {});
                          _updateCart();
                        },
                      ),
                      Text(
                        '${product['grams']} g',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: Icon(Icons.add_circle_outline),
                        onPressed: () {
                          setModalState(() {
                            product['grams'] += 100; // Increase by 100g
                          });
                          setState(() {});
                          _updateCart();
                        },
                      ),
                    ],
                  ),

                  SizedBox(height: 10),

                  // ✅ Add to Cart Button
                  if (product['quantity'] == 0)
                    ElevatedButton(
                      onPressed: () {
                        setModalState(() {
                          product['quantity'] = 1;
                          if (!cartItems.contains(product)) {   // ✅ Prevent duplicate items
                            cartItems.add(product);
                          }

                        });
                        setState(() {});
                        _updateCart();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                      child: Text('Add to Cart'),
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(Icons.remove),
                          onPressed: () {
                            setModalState(() {
                              if (product['quantity'] > 1) {
                                product['quantity']--;
                              } else {
                                product['quantity'] = 0;
                              }
                            });
                            setState(() {});
                            _updateCart();
                          },
                        ),
                        Text('${product['quantity']}'),
                        IconButton(
                          icon: Icon(Icons.add),
                          onPressed: () {
                            setModalState(() {
                              product['quantity']++;
                            });
                            setState(() {});
                            _updateCart();
                          },
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF4A90E2),
        title: Text(
          'Vegetables',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.video_collection_rounded, color: Colors.white),
            onPressed: () {

            },
          ),
          Stack(
            children: [
              IconButton(icon: Icon(Icons.shopping_cart),color: Colors.white, onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => CartScreen()));
              }),
              if (cartItemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: CircleAvatar(
                    radius: 8,
                    backgroundColor: Colors.red,
                    child: Text(
                      '$cartItemCount',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Row(
        children: [
          Container(
            width: 100,
            color: Color(0xFFE3F2FD),
            child: ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedCategory = index;
                      selectedProducts = categories[index]['products'];  // ✅ Load selected category products
                    });
                  },

                  child: Container(
                    color: selectedCategory == index ? Colors.blue.shade100 : Colors.transparent,
                    padding: EdgeInsets.all(8),
                    child: Column(
                      children: [
                        Image.asset(categories[index]['image']!, height: 50),
                        Text(
                          categories[index]['name']!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.45,
              ),
              itemCount: selectedProducts.length,  // ✅ Dynamic product count

              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _showBottomSheet(context, selectedProducts[index]),  // ✅ Show correct product details

                  child: Container(
                    height: 600,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.asset(
                                selectedProducts[index]['image'],
                                height: 150,
                                 fit: BoxFit.contain,
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
                                  selectedProducts[index]['discount'],
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),

                        // ✅ Product Name and Details (Flexible Area)
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                selectedProducts[index]['name'],
                                style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                                textAlign: TextAlign.center,
                                maxLines: 2,  // ✅ Limit to 2 lines
                                overflow: TextOverflow.ellipsis,  // ✅ Prevent overflow
                              ),
                              Text(
                                '${selectedProducts[index]['grams'] ?? 1000} g',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '1 kg',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('₹${selectedProducts[index]['price']}', style: TextStyle(color: Colors.green)),
                                  SizedBox(width: 8),
                                  Text(
                                    '₹${selectedProducts[index]['originalPrice']}',
                                    style: TextStyle(
                                      decoration: TextDecoration.lineThrough,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        if (selectedProducts[index]['quantity'] == 0)
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                selectedProducts[index]['quantity'] = 1;
                                if (!cartItems.contains(selectedProducts[index])) {
                                  cartItems.add(selectedProducts[index]);
                                }

                              });
                              _updateCart();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9),
                              ),
                            ),
                            child: Text('Add to Cart'),
                          )
                        else
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: Icon(Icons.remove),
                                onPressed: () {
                                  setState(() {
                                    if (selectedProducts[index]['quantity'] > 1) {
                                      selectedProducts[index]['quantity']--;
                                    } else {
                                      selectedProducts[index]['quantity'] = 0;
                                    }
                                  });
                                  _updateCart();
                                },
                              ),
                              Text('${selectedProducts[index]['quantity']}'),
                              IconButton(
                                icon: Icon(Icons.add),
                                onPressed: () {
                                  setState(() {
                                    selectedProducts[index]['quantity']++;
                                  });
                                  _updateCart();
                                },
                              ),
                            ],
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
      bottomNavigationBar: cartItemCount > 0
          ? BottomAppBar(
        child: Container(
          height: 60,
          color: Colors.green,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(
                '$cartItemCount Item | ₹$totalAmount',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  _showCart(context);  // ✅ Open cart view
                },

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
                child: Text(
                  'View Cart',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      )
          : null,
    );
  }
}

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: CategoryScreen(),
  ));
}