import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:wavemobileapp/authenticate.dart';
import 'package:wavemobileapp/home.dart';
import 'package:wavemobileapp/shared_preferences_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(Initialiser());
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
  bool isLoading = true;

  void getCurrentUser() async {
    auth = await FirebaseAuth.instance;
    user = await auth.currentUser;

    if (user != null) {
      // user == null means that no  user is logged in currently
      // Store data for persistance
      // This helps in avoiding multiple callbacks to server
      SharedPreferenceHelper().saveUserId(await user.uid);
      SharedPreferenceHelper().saveDisplayName(await user.displayName);
      SharedPreferenceHelper().saveUserPhoneNumber(await user.phoneNumber);
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          )
        : user == null
            ? Authenticate()
            : Home();
  }
}
