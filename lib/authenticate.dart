import 'dart:html';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wavemobileapp/app_bar.dart';


enum MobileAuthenticationState {
  SHOW_MOBILE_FORM_STATE,
  SHOW_OTP_FORM_STATE
}


class Authenticate extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _AuthenticateState();
  }
}


class _AuthenticateState extends State<Authenticate> {

  final currentState = MobileAuthenticationState.SHOW_MOBILE_FORM_STATE;

  getFormWidget(context) {
    return Column(
      children: <Widget>[
        CustomAppBar(),
        Expanded(
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: TextFormField(
              expands: false,
              decoration: InputDecoration(
                labelText: 'Mobile Number',
                contentPadding: EdgeInsets.symmetric(horizontal: 20),
              ),
              keyboardType: TextInputType.number,
              maxLength: 10,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
              ],
            )
          )
        ),
      ],
    );
  }

  getOTPWidget(context) {
    return Scaffold(

    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: currentState == MobileAuthenticationState.SHOW_MOBILE_FORM_STATE ? getFormWidget(context) : getOTPWidget(context)
    );
  }
}
