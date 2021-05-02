import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wavemobileapp/authenticate.dart';
import 'package:wavemobileapp/contacts.dart';

class Home extends StatefulWidget {
  User user;

  Home(@required this.user);

  @override
  State<StatefulWidget> createState() {
    return _HomeState(user);
  }
}


class _HomeState extends State<Home> {
  User _user;

  bool showLoading = false;

  final _auth = FirebaseAuth.instance;

  Future<void> signOut(auth) async {
    setState(() {
      showLoading = true;
    });
    await auth.signOut();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.clear();
    setState(() {
      showLoading = false;
    });
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => Authenticate()));

  }

  _HomeState(@required this._user);

  //Check contacts permission
  Future<PermissionStatus> _getPermission() async {
    final PermissionStatus permission = await Permission.contacts.status;
    if (!permission.isGranted) {
      await Permission.contacts.request();
    }
    return permission;
  }

  @override
  Widget build(BuildContext context) {
    return showLoading ? Scaffold(body: Center(child: CircularProgressIndicator(),),) : Scaffold(
      appBar: AppBar(
        title: Text('Wave'),
        centerTitle: true,
        actions: <Widget>[
          IconButton(
            onPressed: () async {
              await signOut(_auth);
            },
            icon: Icon(
              Icons.logout,
              color: Colors.white,
            ),
          )
        ],
      ),
      body: HomeScreen(_user),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.contacts),
        onPressed: () async {
          final PermissionStatus permissionStatus = await _getPermission();
          if (permissionStatus == PermissionStatus.granted) {
            Navigator.push(
                context, MaterialPageRoute(builder: (context) => ContactsPage())
            );
          }
          else {
            final ScaffoldMessengerState scaffoldMessenger =
            ScaffoldMessenger.of(context);
            scaffoldMessenger.showSnackBar(SnackBar(content: Text("Please grant contact permission")));
          }
        },
      ),
    );
  }
}


class HomeScreen extends StatefulWidget{
  User user;

  HomeScreen(@required this.user);

  @override
  State<StatefulWidget> createState() {
    return _HomeScreenState(user);
  }
}

class _HomeScreenState extends State<HomeScreen> {
  User user;

  _HomeScreenState(@required this.user);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
          children: <Widget>[
            Expanded(
            child:  Center(
                child: Text("Chats goes here"),
              )
            )
          ]
      ),
    );
  }
}
