import 'package:flutter/material.dart';

class StoreDetailsPage extends StatefulWidget {
  final String storeName;

  const StoreDetailsPage({super.key, required this.storeName});

  @override
  _StoreDetailsPageState createState() => _StoreDetailsPageState();
}

class _StoreDetailsPageState extends State<StoreDetailsPage> {
  bool isCustomer = false;
  bool isFavorite = false;
  int quantity = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF1C85EA),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          width: 333,
          height: 39,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey),
          ),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search...',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 143,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                image: DecorationImage(
                  image: AssetImage('assets/banner/banner5.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // CircleAvatar(
            //   radius: 75,
            //   backgroundColor: Colors.white,
            //   child: Icon(Icons.store, size: 100, color: Colors.blue),
            // ),
            Padding(
              padding: EdgeInsets.only(left: 16, right: 16, top: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStoreDetails(),
                  _buildCustomerAndFavoritesButtons(),
                  if (isCustomer) _buildFooterButtons(),
                  _buildProductSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.storeName, style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
        Text("Address: Sample Address"),
        Text("Contact: 1234567890"),
        Text("Alternative Contact: 9876543210"),
        Text("Location: Google Map Link"),
        Text("Customers Count: 120"),
      ],
    );
  }

  Widget _buildCustomerAndFavoritesButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(isCustomer ? 'Customer' : 'New Customer', () {
          setState(() => isCustomer = !isCustomer);
        }, isCustomer),
        _buildActionButton(isFavorite ? 'Added ✓' : 'Favorites/பிடித்த கடை', () {
          setState(() => isFavorite = !isFavorite);
        }, isFavorite),
      ],
    );
  }

  Widget _buildFooterButtons() {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton('Add Photo', () {}),
          _buildActionButton('Message', () {}),
          // _buildActionButton('Send Voice', () {}),
        ],
      ),
    );
  }

  Widget _buildActionButton(String text, VoidCallback onPressed, [bool isSelected = false]) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.green : Colors.blue[400],
        foregroundColor: isSelected ? Colors.white : Colors.black,minimumSize: Size(150, 40),shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),

      ),
      onPressed: onPressed,
      child: Text(text),
    );
  }

  Widget _buildProductSection() {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 150 / 230,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Color(0xFFD7F0FF),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/product/fruits.png', height: 100),
              Text('Product Name'),
              Text('Brand'),
              Text('4.5 ⭐'),
              Text('₹100'),
              ElevatedButton(
                onPressed: () {
                  _showQuantityCounter();
                },
                child: Text('Add to Cart'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showQuantityCounter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Quantity'),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.remove),
              onPressed: () => setState(() => quantity = (quantity > 1) ? quantity - 1 : 1),
            ),
            Text('$quantity'),
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () => setState(() => quantity++),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Add'),
          ),
        ],
      ),
    );
  }
}
