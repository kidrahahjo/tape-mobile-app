import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wavemobileapp/authenticate.dart';
import 'home.dart';
import 'package:wavemobileapp/shared_preferences_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Wave",
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: GoogleFonts.dmSans().fontFamily,
        primaryColor: Color(0xff333333),
        accentColor: Color(0xffffa000),
      ),
      home: Scaffold(body: Initialiser()),
    ),
  );
}

class Initialiser extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _InitialiserState();
  }
}

class _InitialiserState extends State<Initialiser> {
  FirebaseAuth auth;
  User user;

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(),
    );
  }

  Future getCurrentUser() async {
    auth = FirebaseAuth.instance;
    user = auth.currentUser;
    if (user != null) {
      // user == null means that no user is logged in currently
      SharedPreferenceHelper().saveUserId(user.uid);
      SharedPreferenceHelper().saveUserPhoneNumber(user.phoneNumber);
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => Home(user)));
    } else {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => Authenticate(auth)));
    }
  }
}
