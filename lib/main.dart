import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wavemobileapp/authenticate.dart';
import 'package:wavemobileapp/home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(Wrapper());
}

class Wrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Wave', debugShowCheckedModeBanner: false, home: Initialiser());
  }
}

class Initialiser extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _InitialiserState();
  }
}

class _InitialiserState extends State<Initialiser> {
  FirebaseAuth _auth;
  User _user;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _auth = FirebaseAuth.instance;
    _user = _auth.currentUser;
    isLoading = false;
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          )
        : _user == null
            ? Authenticate()
            : Home(_user);
  }
}
