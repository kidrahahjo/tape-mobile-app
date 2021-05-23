import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tapemobileapp/locator.dart';
import 'package:tapemobileapp/routing_constants.dart';
import 'package:tapemobileapp/services/navigation_service.dart';
import 'router.dart' as router;

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  setupLocator();
  final bgColor = Color(0xfff5f5f5);
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateRoute: router.generateRoute,
      initialRoute: StartupViewRoute,
      navigatorKey: locator<NavigationService>().navigatorKey,
      title: "Tape",
      darkTheme: ThemeData(
        primarySwatch: Colors.orange,
        primaryColorDark: Color(0xff444444),
        accentColor: Colors.orange,
        appBarTheme:
            AppBarTheme(backgroundColor: Colors.transparent, elevation: 0),
        brightness: Brightness.dark,
        fontFamily: GoogleFonts.dmSans().fontFamily,
        floatingActionButtonTheme: FloatingActionButtonThemeData(elevation: 0),
      ),
      theme: ThemeData(
        primarySwatch: Colors.orange,
        primaryColorLight: Color(0xffffffff),
        scaffoldBackgroundColor: bgColor,
        appBarTheme: AppBarTheme(backgroundColor: bgColor, elevation: 0),
        brightness: Brightness.light,
        fontFamily: GoogleFonts.dmSans().fontFamily,
        floatingActionButtonTheme: FloatingActionButtonThemeData(elevation: 0),
      ),
    ),
  );
}
