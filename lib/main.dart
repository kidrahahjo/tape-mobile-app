import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tapemobileapp/app/locator.dart';
import 'package:tapemobileapp/app/routing_constants.dart';
import 'package:tapemobileapp/services/navigation_service.dart';
import 'package:tapemobileapp/app/router.dart' as router;
import 'package:tapemobileapp/utils/notification_utls.dart';

Future<void> _onBackgroundMessage(RemoteMessage message) async {
  await showNotification(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);
  setupLocator();
  final bgDark = Color(0xff000000);
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateRoute: router.generateRoute,
      initialRoute: StartupViewRoute,
      navigatorKey: locator<NavigationService>().navigatorKey,
      title: "Tape",
      theme: ThemeData(
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
    ),
  );
}
