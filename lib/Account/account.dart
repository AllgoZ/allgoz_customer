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
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AccountScreen extends StatefulWidget {
  @override
  _AccountScreenState createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  int _selectedIndex = 3;
  String? userName;
  String? userPhone;

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    setState(() => _selectedIndex = index);
    if (index == 0) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
    } else if (index == 1) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const CartScreen()));
    } else if (index == 2) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const FavoritesScreen()));
    }
  }
  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
  }

  void _fetchUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      String emailKey = user.email!.replaceAll('.', '_').replaceAll('@', '_');
      String userCustomerId = 'google_$emailKey';

      final doc = await FirebaseFirestore.instance
          .collection('customers')
          .doc(userCustomerId)
          .get();

      if (doc.exists) {
        setState(() {
          userName = doc['name'] ?? 'No Name';
          userPhone = doc['phone'] ?? 'N/A';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final scaleFactor = width / 390;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.grey[200],
        appBar: AppBar(
          backgroundColor: const Color(0xFF4A90E2),
          title: Text('Account', style: TextStyle(fontSize: 20 * scaleFactor,color:Colors.white,fontWeight: FontWeight.bold)),
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: ListView(
          padding: EdgeInsets.all(16 * scaleFactor),
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: ListTile(
                leading: CircleAvatar(
                  radius: 30 * scaleFactor,
                  backgroundImage: AssetImage('assets/profile.png'),
                ),
                title: Text(userName ?? 'Loading...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18 * scaleFactor)),
                subtitle: Text(userPhone ?? ''),

                trailing: Icon(Icons.edit, color: Colors.blue),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfileScreen()));
                },
              ),
            ),
            SizedBox(height: 20 * scaleFactor),
            _buildSectionTitle('Orders', scaleFactor),
            _buildAccountOption(Icons.shopping_bag, 'My Orders', () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => MyOrdersScreen()));
            }, scaleFactor),
            _buildAccountOption(Icons.local_shipping, 'Track Current Orders', () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => TrackCurrentOrderScreen()));
            }, scaleFactor),
            SizedBox(height: 20 * scaleFactor),
            _buildSectionTitle('Account Settings', scaleFactor),
            _buildAccountOption(Icons.location_on, 'Manage Addresses', () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => ManageAddressesScreen()));
            }, scaleFactor),
            _buildAccountOption(Icons.payment, 'Payment Methods', () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentMethodsScreen()));
            }, scaleFactor),
            _buildAccountOption(Icons.favorite, 'Wishlist/Favorites', () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => FavoritesScreen()));
            }, scaleFactor),
            SizedBox(height: 20 * scaleFactor),
            _buildSectionTitle('Help & Support', scaleFactor),
            _buildAccountOption(Icons.help_outline, 'FAQ / Help Center', () {}, scaleFactor),
            _buildAccountOption(Icons.support_agent, 'Contact Support', () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => ContactSupportScreen()));
            }, scaleFactor),
            SizedBox(height: 20 * scaleFactor),
            _buildSectionTitle('Settings', scaleFactor),
            _buildAccountOption(Icons.notifications, 'Notification Settings', () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => NotificationSettingsScreen()));
            }, scaleFactor),
            _buildAccountOption(Icons.privacy_tip, 'Privacy Settings', () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => PrivacySettingsScreen()));
            }, scaleFactor),
            _buildAccountOption(Icons.language, 'Language', () {}, scaleFactor),
            _buildAccountOption(Icons.dark_mode, 'Dark Mode', () {}, scaleFactor),
            _buildAccountOption(Icons.logout, 'Logout', () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
            }, scaleFactor, isLogout: true),
          ],
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
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountOption(IconData icon, String title, VoidCallback onTap, double scaleFactor, {bool isLogout = false}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: isLogout ? Colors.red : Colors.blue, size: 24 * scaleFactor),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16 * scaleFactor,
            color: isLogout ? Colors.red : Colors.black,
            fontWeight: isLogout ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: isLogout ? null : Icon(Icons.arrow_forward_ios, size: 16 * scaleFactor, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSectionTitle(String title, double scaleFactor) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8 * scaleFactor),
      child: Text(
        title,
        style: TextStyle(fontSize: 18 * scaleFactor, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
    );
  }
}
