import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'login.dart';
import 'entername.dart';
import 'package:allgoz/Home/home.dart';
import 'package:allgoz/Home/cards.dart';
import 'package:allgoz/Home/storedetails.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => LoginPage(),
        '/entername': (context) => EnterNamePage(),
        '/Home/home': (context) => HomePage(),
      },
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
  }
}

class BackgroundWidget extends StatelessWidget {
  const BackgroundWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Color(0xE8F6F6F6), // Set your desired background color here
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
