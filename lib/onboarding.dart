import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wavemobileapp/app_bar.dart';

class Onboarding extends StatefulWidget {
  dynamic auth_credential;

  Onboarding(@required this.auth_credential);

  @override
  State<StatefulWidget> createState() {
    return _OnboardingState(auth_credential);
  }
}

class _OnboardingState extends State<Onboarding> {
  dynamic auth_credential;

  _OnboardingState(this.auth_credential);

  final nameController = TextEditingController();

  onboardForm(context){
    return Column(
      children: <Widget>[
        CustomAppBar(),
        Spacer(),
        TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'Name',
            contentPadding: EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
        TextButton(
            child: Text("Join the wave"),
            onPressed: () {
              print(auth_credential);
            }
        ),
        Spacer()
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: onboardForm(context),
    );
  }
}