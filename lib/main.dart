import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wavemobileapp/locator.dart';
import 'package:wavemobileapp/routing_constants.dart';
import 'package:wavemobileapp/services/navigation_service.dart';
import 'router.dart' as router;

void main() async {
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  setupLocator();
  final bgColor = Color(0xfff5f5f5);
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateRoute: router.generateRoute,
      initialRoute: StartupViewRoute,
      navigatorKey: locator<NavigationService>().navigatorKey,
      title: "shout",
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
