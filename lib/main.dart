import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:wavemobileapp/authenticate.dart';
import 'package:wavemobileapp/home.dart';
import 'package:wavemobileapp/shared_preferences_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MaterialApp(title: "Wave", home: Scaffold(body: Initialiser())));
}

class Initialiser extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _InitialiserState();
  }
}

class _InitialiserState extends State<Initialiser> {
  FirebaseAuth auth = null;
  User user = null;

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    return Center(child: CircularProgressIndicator(),);
  }

  Future getCurrentUser() async {
    auth = await FirebaseAuth.instance;
    user = await auth.currentUser;
    if (user != null) {
      // user == null means that no user is logged in currently
      SharedPreferenceHelper().saveUserId(await user.uid);
      SharedPreferenceHelper().saveUserPhoneNumber(await user.phoneNumber);
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Home(user)));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Authenticate(auth)));
    }
  }
}
