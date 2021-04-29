import 'package:flutter/material.dart';


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
    return Scaffold(
      
    );
  }

  getOTPWidget(context) {
    return ;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: currentState == MobileAuthenticationState.SHOW_MOBILE_FORM_STATE ? getFormWidget(context) : getOTPWidget(),
    );
  }
}
