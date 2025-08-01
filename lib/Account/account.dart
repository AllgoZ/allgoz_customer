import 'package:allgoz/Account/Addresses/manage_adress.dart';
import 'package:allgoz/Account/Contact%20Support/contact_support.dart';
import 'package:allgoz/Account/Notification%20Settings/notification_settings.dart';
import 'package:allgoz/Account/Payment%20Method/payment_methods.dart';
import 'package:allgoz/Account/Privacy%20Settings/privacy_settings.dart';
import 'package:allgoz/Account/Profile/profile_edit.dart';
import 'package:allgoz/Cart/cart.dart';
import 'package:allgoz/Home/home.dart';
import 'package:allgoz/Orders/my_orders.dart';
import 'package:allgoz/login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ✅ Import LoginPage
import 'package:allgoz/main.dart';

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
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MyOrdersScreen()));
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
  }

  void _fetchUserInfo() async {
    final prefs = await SharedPreferences.getInstance();

    // Load from cache immediately
    setState(() {
      userName = prefs.getString('cachedUserName') ?? 'Loading...';
      userPhone = prefs.getString('cachedUserPhone') ?? 'Loading...';
    });

    // Then fetch from Firestore
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      final emailKey = user.email!.replaceAll('.', '_').replaceAll('@', '_');
      final customerId = 'google_$emailKey';

      final doc = await FirebaseFirestore.instance
          .collection('customers')
          .doc(customerId)
          .get();

      if (doc.exists) {
        final freshName = doc['name'] ?? 'No Name';
        final freshPhone = doc.data().toString().contains('phone') ? doc['phone'] : 'N/A';


        setState(() {
          userName = freshName;
          userPhone = freshPhone;
        });

        prefs.setString('cachedUserName', freshName);
        prefs.setString('cachedUserPhone', freshPhone);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final scaleFactor = width / 390;

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A90E2),
        title: Text('Account', style: TextStyle(fontSize: 20 * scaleFactor, color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop(); // Or replace if needed
          },
        ),
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
              title: Text(userName ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18 * scaleFactor)),
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
          SizedBox(height: 20 * scaleFactor),
          _buildSectionTitle('Account Settings', scaleFactor),
          _buildAccountOption(Icons.location_on, 'Manage Addresses', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => ManageAddressesScreen()));
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
          _buildAccountOption(Icons.logout, 'Logout', () async {
            await FirebaseAuth.instance.signOut();
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
            );
          }, scaleFactor, isLogout: true),
        ],
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
