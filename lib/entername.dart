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

  /// Store user details in Firestore
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
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 100),
                const Center(
                  child: Text(
                    'Ready to Explore Your Town?',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, fontFamily: 'Majalla', color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 50),

                Container(
                  width: 312,
                  height: 47,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white.withOpacity(0.8),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, spreadRadius: 2, blurRadius: 8, offset: Offset(0, 4))
                    ],
                  ),
                  child: TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
                      hintText: 'Enter Your Name',
                      hintStyle: const TextStyle(fontFamily: 'Majalla', fontSize: 23, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.transparent,
                    ),
                    style: const TextStyle(fontFamily: 'Majalla', fontSize: 23, color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),

                const SizedBox(height: 20),

                GestureDetector(
                  onTap: () => setState(() => _showReferralInput = true),
                  child: const Text(
                    'Have a Referral Code?',
                    style: TextStyle(fontFamily: 'Majalla', fontSize: 21, color: Color(0xFF1C85EA), fontWeight: FontWeight.bold),
                  ),
                ),

                if (_showReferralInput)
                  Container(
                    width: 312,
                    height: 47,
                    margin: const EdgeInsets.only(top: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white.withOpacity(0.8),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, spreadRadius: 2, blurRadius: 8, offset: Offset(0, 4))
                      ],
                    ),
                    child: TextField(
                      controller: _referralController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        hintText: 'Enter Referral Code',
                        hintStyle: const TextStyle(fontFamily: 'Majalla', fontWeight: FontWeight.bold, fontSize: 22, color: Colors.grey),
                        filled: true,
                        fillColor: Colors.transparent,
                      ),
                      style: const TextStyle(fontFamily: 'Majalla', fontSize: 22, color: Colors.black),
                    ),
                  ),

                const SizedBox(height: 40),

                ElevatedButton(
                  onPressed: _isLoading ? null : () => _submitName(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1C85EA).withOpacity(0.9),
                    minimumSize: const Size(312, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    shadowColor: Colors.black.withOpacity(0.3),
                    elevation: 10,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
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
