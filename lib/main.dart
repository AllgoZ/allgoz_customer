import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:allgoz/Home/home.dart';
import 'package:allgoz/Home/cards.dart';
import 'package:allgoz/Home/storedetails.dart';
import 'package:allgoz/login.dart';
import 'package:allgoz/entername.dart';
import 'package:allgoz/utility/update_checker.dart';
import 'package:allgoz/services/notification_service.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('🔕 BG Message: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // ✅ Initialize notification service
    NotificationService.initialize(context);

    // ✅ Setup FCM permissions
    _setupFCM();
  }

  void _setupFCM() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Notification permission granted');

      String? token = await messaging.getToken();
      print('📱 FCM Token: $token');

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('📩 Foreground: ${message.notification?.title}');
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('🚀 Notification opened: ${message.notification?.title}');
      });
    } else {
      print('❌ Notification permission denied');
    }
  }

  Future<Widget> _getStartScreen() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const LoginPage();

    final emailKey = user.email!.replaceAll('.', '_').replaceAll('@', '_');
    final docId = 'google_$emailKey';

    final doc = await FirebaseFirestore.instance
        .collection('customers')
        .doc(docId)
        .get();

    return doc.exists ? const HomePage() : const EnterNamePage();
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
          home: Builder(
            builder: (context) {
              // ✅ This ensures MaterialLocalizations are available
              WidgetsBinding.instance.addPostFrameCallback((_) {
                UpdateChecker.checkForUpdate(context);
              });

              return snapshot.data!;
            },
          ),
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
