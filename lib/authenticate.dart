import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wavemobileapp/app_bar.dart';
import 'package:wavemobileapp/home.dart';
import 'package:wavemobileapp/onboarding.dart';

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

  MobileAuthenticationState currentState = MobileAuthenticationState.SHOW_MOBILE_FORM_STATE;

  final phoneController = TextEditingController();
  final otpController = TextEditingController();

  String verificationId;

  FirebaseAuth _auth = FirebaseAuth.instance;

  bool showLoading = false;


  Future<void> signInWithPhoneAuthCredential(phoneAuthCredential, context) async {
    setState(() {
      this.showLoading = true;
    });

    try {
      UserCredential auth_credential = await _auth.signInWithCredential(phoneAuthCredential);
      setState(() {
        this.showLoading = false;
      });

      if (auth_credential?.user != null) {
        if (auth_credential?.user?.displayName == null) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Onboarding(auth_credential)));
        }else{
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Home(auth_credential.user)));
        }
      }

    } on FirebaseAuthException catch (e) {
      setState(() {
        this.showLoading = true;
      });

      final ScaffoldMessengerState scaffoldMessenger = ScaffoldMessenger.of(context);
      scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(e.message))
      );
    }
  }



  getFormWidget(context) {
    return Column(
      children: <Widget>[
        CustomAppBar(),
        Spacer(),
        TextField(
          controller: phoneController,
          decoration: InputDecoration(
            labelText: 'Mobile Number',
            contentPadding: EdgeInsets.symmetric(horizontal: 16),
          ),
          keyboardType: TextInputType.number,
          maxLength: 10,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
          ],
        ),
        TextButton(
          child: Text("Verify"),
          onPressed: () async {

            setState(() {
              this.showLoading = true;
            });

            await _auth.verifyPhoneNumber(
              phoneNumber: "+91" + phoneController.text,
              verificationCompleted: (phoneAuthCredential) async {
                setState(() {
                  this.showLoading = false;
                });
              },
              verificationFailed: (verificationFailed) async {
                setState(() {
                  this.showLoading = false;
                });

                final ScaffoldMessengerState scaffoldMessenger = ScaffoldMessenger.of(context);
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text(verificationFailed.message))
                );
              },
              codeSent: (verificationId, resendingToken) async {
                setState(() {
                  this.showLoading = false;
                  currentState = MobileAuthenticationState.SHOW_OTP_FORM_STATE;
                  this.verificationId = verificationId;
                });
              },
              codeAutoRetrievalTimeout: (verificationId) async {

              }
            );
          },

        ),
        Spacer(),
      ],
    );
  }

  getOTPWidget(context) {
    return Column(
      children: <Widget>[
        Spacer(),
        TextField(
          controller: otpController,
          decoration: InputDecoration(
            labelText: 'Enter OTP',
            contentPadding: EdgeInsets.symmetric(horizontal: 16),
          ),
          keyboardType: TextInputType.number,
          maxLength: 6,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
          ],
        ),
        TextButton(
          child: Text("Submit"),
          onPressed: () async {
            PhoneAuthCredential phoneAuthCredential = PhoneAuthProvider.credential(verificationId: verificationId, smsCode: otpController.text);
            signInWithPhoneAuthCredential(phoneAuthCredential, context);
          }
        ),
        Spacer(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: showLoading ? Center(child: CircularProgressIndicator(),) : currentState == MobileAuthenticationState.SHOW_MOBILE_FORM_STATE ? getFormWidget(context) : getOTPWidget(context)
    );
  }
}
