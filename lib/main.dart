import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login.dart';
import 'entername.dart';
import 'package:allgoz/Home/home.dart';
import 'package:allgoz/Home/cards.dart';
import 'package:allgoz/Home/storedetails.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase before the app runs
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Widget> _getStartScreen() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const LoginPage();

    // 🔑 Format email for Firestore doc ID
    final emailKey = user.email!.replaceAll('.', '_').replaceAll('@', '_');
    final docId = 'google_$emailKey';

    final doc = await FirebaseFirestore.instance
        .collection('customers')
        .doc(docId)
        .get();

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

class BackgroundWidget extends StatelessWidget {
  const BackgroundWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Color(0xE8F6F6F6), // Background color
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
