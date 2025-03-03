import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:allgoz/Home/home.dart';

class EnterNamePage extends StatefulWidget {
  const EnterNamePage({super.key});

  @override
  _EnterNamePageState createState() => _EnterNamePageState();
}

class _EnterNamePageState extends State<EnterNamePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _referralController = TextEditingController();
  bool _showReferralInput = false;
  bool _isLoading = false;
  String? _phoneNumber;

  @override
  void initState() {
    super.initState();
    _getPhoneNumber();
  }

  /// Fetch current authenticated phone number
  void _getPhoneNumber() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _phoneNumber = user.phoneNumber;
      });
    }
  }

  /// Store user details in Firestore
  Future<void> _submitName(BuildContext context) async {
    if (_nameController.text.isEmpty) {
      _showSnackbar('Please enter your name');
      return;
    }
    if (_phoneNumber == null) {
      _showSnackbar('Phone number not found. Try logging in again.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userRef = FirebaseFirestore.instance.collection('customers').doc(_phoneNumber);

      // Check if user already exists
      final userDoc = await userRef.get();
      if (userDoc.exists) {
        _showSnackbar('User already exists. Logging in...');
        _navigateToHome();
        return;
      }

      // Save user data
      await userRef.set({
        'name': _nameController.text,
        'phoneNumber': _phoneNumber,
        'referralCode': _showReferralInput ? _referralController.text : null,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _showSnackbar('Profile created successfully!');
      _navigateToHome();
    } catch (e) {
      _showSnackbar('Error: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Navigate to Home Page
  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomePage()),
    );
  }

  /// Show SnackBar message
  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 100),
                Center(
                  child: Text(
                    'Ready to Explore Your Town?',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, fontFamily: 'Majalla', color: Colors.grey),
                  ),
                ),
                SizedBox(height: 50),

                /// User Name Input
                Container(
                  width: 312,
                  height: 47,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white.withOpacity(0.8),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), spreadRadius: 2, blurRadius: 8, offset: Offset(0, 4))],
                  ),
                  child: TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
                      filled: true,
                      fillColor: Colors.transparent,
                      hintText: 'Enter Your Name',
                      hintStyle: TextStyle(fontFamily: 'Majalla', fontSize: 23, color: Colors.grey),
                    ),
                    style: TextStyle(fontFamily: 'Majalla', fontSize: 23, color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),

                SizedBox(height: 20),

                /// Referral Code Input
                GestureDetector(
                  onTap: () => setState(() => _showReferralInput = true),
                  child: Text(
                    'Have a Referral Code?',
                    style: TextStyle(fontFamily: 'Majalla', fontSize: 21, color: Color(0xFF1C85EA), fontWeight: FontWeight.bold),
                  ),
                ),
                if (_showReferralInput)
                  Container(
                    width: 312,
                    height: 47,
                    margin: EdgeInsets.only(top: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white.withOpacity(0.8),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), spreadRadius: 2, blurRadius: 8, offset: Offset(0, 4))],
                    ),
                    child: TextField(
                      controller: _referralController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: Colors.transparent,
                        hintText: 'Enter Referral Code',
                        hintStyle: TextStyle(fontFamily: 'Majalla', fontWeight: FontWeight.bold, fontSize: 22, color: Colors.grey),
                      ),
                      style: TextStyle(fontFamily: 'Majalla', fontSize: 22, color: Colors.black),
                    ),
                  ),

                SizedBox(height: 40),

                /// Submit Button
                ElevatedButton(
                  onPressed: _isLoading ? null : () => _submitName(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1C85EA).withOpacity(0.9),
                    minimumSize: Size(312, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    shadowColor: Colors.black.withOpacity(0.3),
                    elevation: 10,
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                    'Explore',
                    style: TextStyle(fontFamily: 'Majalla', fontSize: 30, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
