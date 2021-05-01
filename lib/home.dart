import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:wavemobileapp/app_bar.dart';

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

  _HomeState(@required this._user);

  homeScreen(context){
  return Column(
    children: <Widget>[
      CustomAppBar(),
      Spacer(),
      Text("Welcome ${_user.displayName}"),
      Spacer(),
    ],
  );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: homeScreen(context),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          print(_user);
        },
        child: Icon(Icons.contacts),
      ),
    );
  }
}
