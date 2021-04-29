import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import './chatpage.dart';

void main() {
  runApp(Wrapper());
}

class Wrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      home: ChatPage(),
    );
  }
}
