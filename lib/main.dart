import 'package:flutter/material.dart';
import 'package:wavemobileapp/authenticate.dart';

void main() {
  runApp(Wrapper());
}

class Wrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wave',
      debugShowCheckedModeBanner: false,
      home: Authenticate()
    );
  }
}
