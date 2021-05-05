import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wavemobileapp/authenticate.dart';
import 'package:wavemobileapp/chatpage.dart';
import 'package:wavemobileapp/contacts.dart';
import 'package:wavemobileapp/database.dart';

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

  Stream chatsStream;
  String _now;

  final _auth = FirebaseAuth.instance;

  Timer timer;

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

  @override
  void initState() {
    print(_user.displayName);
    getChats();
    timer = Timer.periodic(Duration(seconds: 5), (Timer t) => checkForNewWaves());
    super.initState();
  }

  checkForNewWaves() {
    setState(() {
      _now = DateTime.now().second.toString();
    });
  }
  getChats() async {
    chatsStream = await DatabaseMethods().fetchTotalChats(_user.uid);
    setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
  }

  //Check contacts permission
  Future<PermissionStatus> _getPermission() async {
    PermissionStatus permission = await Permission.contacts.status;
    if (!permission.isGranted) {
      await Permission.contacts.request();
    }
    permission = await Permission.contacts.status;
    return permission;
  }

  Widget Chats() {
    return StreamBuilder(
      stream: chatsStream,
      builder: (context, snapshot) {
        return snapshot.hasData
            ? ListView.builder(
            itemCount: snapshot.data.docs.length,
            shrinkWrap: true,
            itemBuilder: (context, index) {
              DocumentSnapshot ds = snapshot.data.docs[index];
              String user_uid = ds.id;
              String user_name = ds.data()['userName'].toString();
              return InkWell(
                onTap: () {
                  Navigator.push(
                      context, MaterialPageRoute(builder: (context) => ChatPage(_user.uid, user_uid, user_name, _user.displayName)));
                },
                child: Container(
                  alignment: Alignment.centerLeft,
                  margin: EdgeInsets.symmetric(horizontal: 10),
                  padding: EdgeInsets.symmetric(horizontal: 25),
                  decoration:
                  BoxDecoration(border: Border(bottom: BorderSide(width: 1))),
                  height: 64,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        user_name,
                        textAlign: TextAlign.left,
                        style: TextStyle(fontSize: 20),
                      ),
                    ],
                  ),
                ),
              );
            })
            : Center(child: Text("No waves yet!"));
      },
    );
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
      body: Chats(),
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

