import 'package:flutter/material.dart';

enum AppBarState {
  DEFAULT,
  HOME,
  CHAT
}


class CustomAppBar extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _AppBarState();
  }
}


class _AppBarState extends State<CustomAppBar> {

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text('Wave'),
      centerTitle: true,
    );
  }
}
