import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wavemobileapp/locator.dart';
import 'package:wavemobileapp/routing_constants.dart';
import 'package:wavemobileapp/services/navigation_service.dart';
import 'package:wavemobileapp/ui/views/startup_view.dart';
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
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: GoogleFonts.dmSans().fontFamily,
        primaryColor: Color(0xff333333),
        accentColor: Color(0xffffa000),
      ),
    ),
  );
}
