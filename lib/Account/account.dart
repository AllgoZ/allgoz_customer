import 'package:allgoz/Account/Addresses/manage_adress.dart';
import 'package:allgoz/Account/Contact%20Support/contact_support.dart';
import 'package:allgoz/Account/Notification%20Settings/notification_settings.dart';
import 'package:allgoz/Account/Payment%20Method/payment_methods.dart';
import 'package:allgoz/Account/Privacy%20Settings/privacy_settings.dart';
import 'package:allgoz/Account/Profile/profile_edit.dart';

import 'package:allgoz/Cart/cart.dart';
import 'package:allgoz/Favorite/favorite.dart';
import 'package:allgoz/Home/home.dart';
import 'package:allgoz/Orders/my_orders.dart';
import 'package:allgoz/Orders/track_order.dart';
import 'package:flutter/material.dart';

class AccountScreen extends StatefulWidget {
  @override
  _AccountScreenState createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  int _selectedIndex = 3; // Default to Account

  // Navigation Function
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => HomePage()));
    } else if (index == 1) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => CartScreen()));
    } else if (index == 2) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => FavoritesScreen()));
    } else if (index == 3) {
      // Already on Account Screen
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Color(0xFF4A90E2),
        title: Text('Account'),
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // 👤 User Profile Section
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: ListTile(
              leading: CircleAvatar(
                radius: 30,
                backgroundImage: AssetImage('assets/profile.png'), // Placeholder image
              ),
              title: Text('John Doe', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              subtitle: Text('+91 98765 43210'),
              trailing: Icon(Icons.edit, color: Colors.blue),
              onTap: () {
                // Navigate to Edit Profile
                Navigator.push(context, MaterialPageRoute(builder: (context) =>  EditProfileScreen()));

              },
            ),
          ),

          SizedBox(height: 20),

          // 📦 Orders Section
          _buildSectionTitle('Orders'),
          _buildAccountOption(Icons.shopping_bag, 'My Orders', () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => MyOrdersScreen()));
          }),
          _buildAccountOption(Icons.local_shipping, 'Track Current Orders', () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => TrackCurrentOrderScreen()));
          }),

          SizedBox(height: 20),

          // ⚙️ Account Settings
          _buildSectionTitle('Account Settings'),
          _buildAccountOption(Icons.location_on, 'Manage Addresses', () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => ManageAddressesScreen()));
          }),
          _buildAccountOption(Icons.payment, 'Payment Methods', () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => PaymentMethodsScreen()));// Navigate to Payment Methods
          }),
          _buildAccountOption(Icons.favorite, 'Wishlist/Favorites', () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => FavoritesScreen()));
          }),

          SizedBox(height: 20),

          // ❓ Help Section
          _buildSectionTitle('Help & Support'),
          _buildAccountOption(Icons.help_outline, 'FAQ / Help Center', () {


          }),
          _buildAccountOption(Icons.support_agent, 'Contact Support', () {
            // Navigate to Contact Support
            Navigator.push(context, MaterialPageRoute(builder: (context) => ContactSupportScreen()));
          }),

          SizedBox(height: 20),

          // ⚙️ Settings Section
          _buildSectionTitle('Settings'),
          _buildAccountOption(Icons.notifications, 'Notification Settings', () {

            Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationSettingsScreen()));
            // Navigate to Notification Settings
          }),
          _buildAccountOption(Icons.privacy_tip, 'Privacy Settings', () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => PrivacySettingsScreen())); // Navigate to Privacy Settings

          }),
          _buildAccountOption(Icons.language, 'Language', () {
            // Navigate to Language Settings
          }),
          _buildAccountOption(Icons.dark_mode, 'Dark Mode', () {
            // Navigate to Dark Mode Toggle
          }),

          // 🚪 Logout Button inside Settings
          _buildAccountOption(Icons.logout, 'Logout', () {
            Navigator.pop(context);
          }, isLogout: true),
        ],
      ),

      // ✅ Bottom Navigation Bar
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
            label: 'Account',
          ),
        ],
        onTap: _onItemTapped,
      ),
    );
  }

  // 🔹 Helper to Build Account Options
  Widget _buildAccountOption(IconData icon, String title, VoidCallback onTap, {bool isLogout = false}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: isLogout ? Colors.red : Colors.blue),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            color: isLogout ? Colors.red : Colors.black,
            fontWeight: isLogout ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: isLogout ? null : Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  // 📋 Section Title Helper
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
    );
  }
}



void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: AccountScreen(),
  ));
}
