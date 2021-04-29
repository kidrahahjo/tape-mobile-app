import 'package:flutter/material.dart';

enum AppBarState {
  DEFAULT,
  HOME,
  CHAT
}


class AppBar extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _AppBarState();
  }
}


class _AppBarState extends State<AppBar> {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Container(
      height: 56.0,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(color: Colors.blue[500]),
      child: Text('Wave')
    );
  }
}
