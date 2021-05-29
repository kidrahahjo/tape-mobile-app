import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tapemobileapp/app/locator.dart';
import 'package:tapemobileapp/app/routing_constants.dart';
import 'package:tapemobileapp/services/navigation_service.dart';
import 'package:tapemobileapp/app/router.dart' as router;

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  setupLocator();
  final bgColor = Color(0xffeeeeee);
  final bgDark = Color(0xff000000);
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateRoute: router.generateRoute,
      initialRoute: StartupViewRoute,
      navigatorKey: locator<NavigationService>().navigatorKey,
      title: "Tape",
      darkTheme: ThemeData(
        primarySwatch: Colors.deepPurple,
        primaryColorDark: Color(0xff444444),
        primaryColorLight: Color(0xff222222),
        scaffoldBackgroundColor: bgDark,
        backgroundColor: bgDark,
        bottomSheetTheme: BottomSheetThemeData(backgroundColor: bgDark),
        accentColor: Colors.deepPurpleAccent,
        appBarTheme: AppBarTheme(backgroundColor: bgDark, elevation: 0),
        brightness: Brightness.dark,
        fontFamily: 'DMSans',
        floatingActionButtonTheme: FloatingActionButtonThemeData(elevation: 0),
      ),
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        primaryColor: Colors.deepPurpleAccent,
        accentColor: Colors.deepPurpleAccent,
        primaryTextTheme:
            TextTheme(headline6: TextStyle(color: Color(0xff212121))),
        primaryIconTheme: IconThemeData(color: Color(0xff212121)),
        primaryColorLight: Color(0xffffffff),
        scaffoldBackgroundColor: bgColor,
        bottomSheetTheme: BottomSheetThemeData(backgroundColor: bgColor),
        appBarTheme: AppBarTheme(
          backgroundColor: bgColor,
          elevation: 0,
        ),
        brightness: Brightness.light,
        fontFamily: 'DMSans',
        floatingActionButtonTheme: FloatingActionButtonThemeData(elevation: 0),
      ),
    ),
  );
}
