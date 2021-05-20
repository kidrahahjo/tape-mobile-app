import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wavemobileapp/locator.dart';
import 'package:wavemobileapp/routing_constants.dart';
import 'package:wavemobileapp/services/navigation_service.dart';
import 'router.dart' as router;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  setupLocator();
  final bgColor = Color(0xffeeeeee);
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateRoute: router.generateRoute,
      initialRoute: StartupViewRoute,
      navigatorKey: locator<NavigationService>().navigatorKey,
      title: "shout",
      darkTheme: ThemeData(),
      theme: ThemeData(
        primarySwatch: Colors.orange,
        primaryColorLight: Color(0xfffafafa),
        scaffoldBackgroundColor: bgColor,
        appBarTheme: AppBarTheme(backgroundColor: bgColor, elevation: 0),
        brightness: Brightness.light,
        fontFamily: GoogleFonts.dmSans().fontFamily,
        floatingActionButtonTheme: FloatingActionButtonThemeData(elevation: 0),
      ),
    ),
  );
}
