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
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
  }

  Future<void> _submitName(BuildContext context) async {
    if (_nameController.text.trim().isEmpty) {
      _showSnackbar('Please enter your name');
      return;
    }

    if (_user == null || _user!.email == null) {
      _showSnackbar('User not found. Please try signing in again.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final safeEmail = _user!.email!.replaceAll('.', '_').replaceAll('@', '_');
      final customerId = 'google_$safeEmail';
      final userRef = FirebaseFirestore.instance.collection('customers').doc(customerId);

      final userDoc = await userRef.get();
      if (userDoc.exists) {
        _showSnackbar('User already exists. Logging in...');
        _navigateToHome();
        return;
      }

      await userRef.set({
        'customerId': customerId,
        'name': _nameController.text.trim(),
        'email': _user!.email,
        'uid': _user!.uid,
        'referralCode': _showReferralInput ? _referralController.text.trim() : null,
        'createdAt': FieldValue.serverTimestamp(),
        'cart': [],
        'favorites': [],
        'orders': [],
      });

      _showSnackbar('Profile created successfully!');
      _navigateToHome();
    } catch (e) {
      _showSnackbar('Error: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final scaleFactor = MediaQuery.of(context).size.width / 390;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Padding(
            padding: EdgeInsets.all(20.0 * scaleFactor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 100 * scaleFactor),
                Center(
                  child: Text(
                    'Ready to Explore Your Town?',
                    style: TextStyle(
                      fontSize: 28 * scaleFactor,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Majalla',
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 50 * scaleFactor),

                // ✅ Name Field
                Container(
                  width: double.infinity,
                  height: 50 * scaleFactor,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12 * scaleFactor),
                    color: Colors.white.withOpacity(0.8),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        spreadRadius: 2,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _nameController,
                    maxLines: 1,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 12 * scaleFactor, vertical: 10 * scaleFactor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9 * scaleFactor),
                      ),
                      hintText: 'Enter Your Name',
                      hintStyle: TextStyle(
                        fontFamily: 'Majalla',
                        fontSize: 20 * scaleFactor,
                        color: Colors.grey,
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                    ),
                    style: TextStyle(
                      fontFamily: 'Majalla',
                      fontSize: 20 * scaleFactor,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                SizedBox(height: 20 * scaleFactor),

                GestureDetector(
                  onTap: () => setState(() => _showReferralInput = true),
                  child: Text(
                    'Have a Referral Code?',
                    style: TextStyle(
                      fontFamily: 'Majalla',
                      fontSize: 18 * scaleFactor,
                      color: const Color(0xFF1C85EA),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                if (_showReferralInput)
                  Container(
                    width: double.infinity,
                    height: 50 * scaleFactor,
                    margin: EdgeInsets.only(top: 20 * scaleFactor),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12 * scaleFactor),
                      color: Colors.white.withOpacity(0.8),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          spreadRadius: 2,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _referralController,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 12 * scaleFactor, vertical: 10 * scaleFactor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12 * scaleFactor),
                          borderSide: BorderSide.none,
                        ),
                        hintText: 'Enter Referral Code',
                        hintStyle: TextStyle(
                          fontFamily: 'Majalla',
                          fontWeight: FontWeight.bold,
                          fontSize: 18 * scaleFactor,
                          color: Colors.grey,
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                      ),
                      style: TextStyle(
                        fontFamily: 'Majalla',
                        fontSize: 18 * scaleFactor,
                        color: Colors.black,
                      ),
                    ),
                  ),

                SizedBox(height: 40 * scaleFactor),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _submitName(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50).withOpacity(0.9),
                      minimumSize: Size(double.infinity, 50 * scaleFactor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12 * scaleFactor),
                      ),
                      shadowColor: Colors.black.withOpacity(0.3),
                      elevation: 10,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                      'Explore',
                      style: TextStyle(
                        fontFamily: 'Majalla',
                        fontSize: 24 * scaleFactor,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
