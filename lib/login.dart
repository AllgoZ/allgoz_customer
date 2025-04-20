// 📦 Required packages:
// Add these to pubspec.yaml
// firebase_auth, google_sign_in, cloud_firestore

import 'package:allgoz/Home/cards.dart';
import 'package:allgoz/Home/storedetails.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:allgoz/Home/home.dart';
import 'entername.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}
class BackgroundWidget extends StatelessWidget {
  const BackgroundWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: const Color(0xE8F6F6F6),
        child: ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.5),
            BlendMode.darken,
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Widget> _getStartScreen() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const LoginPage();

    final doc = await FirebaseFirestore.instance.collection('customers').doc(user.uid).get();
    if (doc.exists) {
      return const HomePage();
    } else {
      return const EnterNamePage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _getStartScreen(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: snapshot.data,
          onGenerateRoute: (settings) {
            if (settings.name == '/Home/cards') {
              final args = settings.arguments as String?;
              return MaterialPageRoute(
                builder: (context) => CardsPage(categoryName: args ?? 'Default Category'),
              );
            } else if (settings.name == '/Home/storedetails') {
              final args = settings.arguments as String?;
              return MaterialPageRoute(
                builder: (context) => StoreDetailsPage(storeName: args ?? 'Default Store'),
              );
            }
            return null;
          },
        );
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isSigningIn = false;

  Future<void> _signInWithGoogle(BuildContext context) async {
    setState(() => _isSigningIn = true);

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _isSigningIn = false);
        return; // Sign-in cancelled
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) {
        setState(() => _isSigningIn = false);
        return;
      }

      final doc = await FirebaseFirestore.instance.collection('customers').doc(user.uid).get();
      setState(() => _isSigningIn = false);

      if (doc.exists) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const EnterNamePage()));
      }
    } catch (e) {
      setState(() => _isSigningIn = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Sign-in failed: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = screenWidth / 390;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const BackgroundWidget(),
          Padding(
            padding: EdgeInsets.all(20.0 * scaleFactor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 100 * scaleFactor),
                Image.asset(
                  'assets/icons/5.png',
                  height: 250 * scaleFactor,
                ),
                Text(
                  'Explore Your Town',
                  style: TextStyle(
                    fontSize: 30 * scaleFactor,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 100 * scaleFactor),
                _isSigningIn
                    ? const CircularProgressIndicator(color: Colors.green)
                    : ElevatedButton.icon(
                  icon: Icon(Icons.login, color: Colors.white, size: 24 * scaleFactor),
                  label: Text(
                    "Continue with Google",
                    style: TextStyle(
                      fontSize: 21 * scaleFactor,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: Size(312 * scaleFactor, 50 * scaleFactor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12 * scaleFactor),
                    ),
                  ),
                  onPressed: () => _signInWithGoogle(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
