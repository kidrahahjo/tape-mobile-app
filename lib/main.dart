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
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateRoute: router.generateRoute,
      initialRoute: StartupViewRoute,
      navigatorKey: locator<NavigationService>().navigatorKey,
      title: "shout",
      darkTheme: ThemeData(),
      theme: ThemeData(
        brightness: Brightness.light,
        fontFamily: GoogleFonts.dmSans().fontFamily,
        floatingActionButtonTheme: FloatingActionButtonThemeData(elevation: 0),
      ),
    ),
  );
}
