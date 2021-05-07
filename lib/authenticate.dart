import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:wavemobileapp/app_bar.dart';
import 'package:wavemobileapp/database.dart';
import 'package:wavemobileapp/home.dart';
import 'package:wavemobileapp/onboarding.dart';
import 'package:wavemobileapp/shared_preferences_helper.dart';

class Authenticate extends StatefulWidget {
  FirebaseAuth auth;

  Authenticate(@required this.auth);

  @override
  State<StatefulWidget> createState() {
    return _AuthenticateState(auth);
  }
}

class _AuthenticateState extends State<Authenticate> {
  // initialising variables
  FirebaseAuth auth;

  // state control variables
  bool mobileFormState = true;
  bool showLoading = false;
  bool showMobileErrorMessage = false;
  bool showOTPErrorMessage = false;

  // helper variables
  final phoneController = TextEditingController();
  final otpController = TextEditingController();
  String verificationId;
  String mobileNumber;
  int resendingToken;

  _AuthenticateState(@required this.auth);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: showLoading
            ? Center(
                child: CircularProgressIndicator(),
              )
            : SafeArea(
                child: mobileFormState
                    ? getMobileNumberFormWidget(context)
                    : getOTPFormWidget(context)));
  }

  Widget getMobileNumberFormWidget(context) {
    return Column(
      children: <Widget>[
        SizedBox(height: 40),
        Container(
          constraints: BoxConstraints.expand(
            height: 150,
          ),
          alignment: Alignment.bottomLeft,
          padding: EdgeInsets.all(20),
          child: RichText(
              text: TextSpan(
                  text: "Hi, tell us your contact number to start ",
                  style:
                      TextStyle(fontSize: 28, height: 1.5, color: Colors.black),
                  children: <TextSpan>[
                TextSpan(
                    text: 'shouting!',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ])),
        ),
        Padding(
            padding: EdgeInsets.only(left: 20, right: 20, top: 20),
            child: Material(
              color: Color(0xFFF5F5F5),
              shape: ContinuousRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              child: Container(
                constraints: BoxConstraints.expand(
                  height: 50,
                ),
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      "+91",
                      style: TextStyle(fontSize: 16),
                    ),
                    Expanded(
                        child: Container(
                            alignment: Alignment.bottomCenter,
                            child: TextFormField(
                              controller: phoneController,
                              autofocus: true,
                              style: TextStyle(fontSize: 16),
                              onChanged: (value) {
                                setState(() {
                                  this.showMobileErrorMessage = false;
                                });
                              },
                              decoration: InputDecoration(
                                contentPadding: EdgeInsets.only(left: 15),
                                border: InputBorder.none,
                                counterText: "",
                              ),
                              keyboardType: TextInputType.number,
                              maxLength: 10,
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9]')),
                              ],
                            ))),
                  ],
                ),
              ),
            )),
        Padding(
          padding: EdgeInsets.only(left: 20, right: 20),
          child: Container(
              constraints: BoxConstraints.expand(
                height: 50,
              ),
              alignment: Alignment.topLeft,
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text(
                showMobileErrorMessage ? "Error occurred, try again." : "",
                style: TextStyle(fontSize: 14, color: Colors.red),
              )),
        ),
        Spacer(),
        Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Material(
                color: Colors.black,
                shape: ContinuousRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: Container(
                    constraints: BoxConstraints.expand(
                      height: 50,
                    ),
                    // padding: EdgeInsets.symmetric(horizontal: 20),
                    child: TextButton(
                      child: Text(
                        "Verify using security code",
                        style: TextStyle(fontSize: 20, color: Colors.white),
                      ),
                      onPressed: () async {
                        try {
                          await verifyMobileNumber(phoneController.text);
                        } catch (e) {
                          setState(() {
                            this.showMobileErrorMessage = true;
                            this.showLoading = false;
                          });
                        }
                      },
                    )))),
      ],
    );
  }

  String refactorMobileNumber(String mobileNumber) {
    String result = int.parse(mobileNumber).toString();
    if (result.length == 10) {
      return "+91" + result;
    } else {
      return null;
    }
  }

  Future verificationThroughServer(String mobileNumber, int resendingToken) {
    return auth.verifyPhoneNumber(
        phoneNumber: mobileNumber,
        timeout: Duration(seconds: 30),
        forceResendingToken: resendingToken,
        verificationCompleted: (phoneAuthCredential) async {
          // TODO: Here goes the automatic OTP handling
          // Check here: https://firebase.flutter.dev/docs/auth/phone/
        },
        verificationFailed: (verificationFailed) async {
          setState(() {
            this.showLoading = false;
            this.showMobileErrorMessage = true;
            this.mobileFormState = true;
          });
          this.mobileNumber = null;
        },
        codeSent: (verificationId, resendingToken) async {
          setState(() {
            this.showLoading = false;
            this.mobileFormState = false;
            this.verificationId = verificationId;
            this.resendingToken = resendingToken;
          });
        },
        codeAutoRetrievalTimeout: (verificationId) async {
          // Auto OTP Resolution timeout.
          // TODO: Automatic OTP Handling goes here
        });
  }

  verifyMobileNumber(String mobileNumber) async {
    String refactoredNumber = refactorMobileNumber(mobileNumber);
    if (refactoredNumber == null) {
      setState(() {
        this.showMobileErrorMessage = true;
      });
    } else {
      setState(() {
        this.showLoading = true;
      });
      this.mobileNumber = refactoredNumber;
      await verificationThroughServer(refactoredNumber, null);
    }
  }

  Widget getOTPFormWidget(context) {
    // TODO: Add re-enter number screen
    // TODO: Add option to automatically read OTP
    return Column(
      children: <Widget>[
        SizedBox(height: 40),
        Container(
          constraints: BoxConstraints.expand(
            height: 220,
          ),
          alignment: Alignment.bottomLeft,
          padding: EdgeInsets.all(20),
          child: RichText(
              text: TextSpan(
                  text: "A secret code was sent to ",
                  style:
                      TextStyle(fontSize: 28, height: 1.5, color: Colors.black),
                  children: <TextSpan>[
                TextSpan(
                    text: this.mobileNumber.substring(0, 3) +
                        '-' +
                        this.mobileNumber.substring(3) +
                        ".\n",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: "Please enter the code below to login."),
              ])),
        ),
        Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 10),
          child: Material(
              color: Color(0xFFF5F5F5),
              shape: ContinuousRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              child: Container(
                constraints: BoxConstraints.expand(
                  height: 50,
                ),
                // padding: EdgeInsets.symmetric(horizontal: 20),
                child: TextFormField(
                  controller: otpController,
                  autofocus: true,
                  style: TextStyle(fontSize: 16),
                  onChanged: (value) {
                    setState(() {
                      this.showOTPErrorMessage = false;
                    });
                  },
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.only(left: 15),
                    border: InputBorder.none,
                    counterText: "",
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                  ],
                ),
              )),
        ),
        Padding(
          padding: EdgeInsets.only(left: 20, right: 20),
          child: Container(
              constraints: BoxConstraints.expand(
                height: 50,
              ),
              alignment: Alignment.topLeft,
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text(
                showOTPErrorMessage ? "Invalid OTP, try again." : "",
                style: TextStyle(fontSize: 14, color: Colors.red),
              )),
        ),
        Spacer(),
        Padding(
            padding: EdgeInsets.only(left: 20, right: 20, bottom: 10),
            child: Container(
                constraints: BoxConstraints.expand(
                  height: 50,
                ),
                child: Material(
                  color: Colors.white,
                  shape: ContinuousRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                    side: BorderSide(color: Colors.black, width: 2),
                  ),
                  child: MaterialButton(
                    child: Text(
                      "Didn't receive? Resend code",
                      style: TextStyle(fontSize: 20, color: Colors.black),
                    ),
                    onPressed: () async {
                      setState(() {
                        this.showLoading = true;
                      });
                      await verificationThroughServer(
                          this.mobileNumber, this.resendingToken);
                    },
                  ),
                ))),
        Padding(
            padding: EdgeInsets.only(left: 20, right: 20, bottom: 10),
            child: Container(
                constraints: BoxConstraints.expand(
                  height: 50,
                ),
                child: Material(
                  color: Colors.black,
                  shape: ContinuousRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  child: MaterialButton(
                    child: Text(
                      "Login",
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    ),
                    onPressed: () async {
                      await verifyOTP(otpController.text);
                    },
                  ),
                ))),
      ],
    );
  }

  String refactorOTP(String otp) {
    if (otp == null || otp.length != 6) {
      return null;
    } else {
      return otp;
    }
  }

  verifyOTP(String otp) async {
    if (refactorOTP(otp) != null) {
      setState(() {
        this.showLoading = true;
      });
      await signInWithPhoneAuthCredential(verificationId, otp, context);
    } else {
      setState(() {
        this.showOTPErrorMessage = true;
      });
    }
  }

  Future saveToSharedPreferences(uid, phoneNumber) {
    SharedPreferenceHelper().saveUserId(uid);
    SharedPreferenceHelper().saveUserId(phoneNumber);
  }

  signInWithPhoneAuthCredential(
      String verification_id, String otp, context) async {
    try {
      PhoneAuthCredential phoneAuthCredential =
          await PhoneAuthProvider.credential(
              verificationId: verification_id, smsCode: otp);
      UserCredential auth_credential =
          await auth.signInWithCredential(phoneAuthCredential);

      if (auth_credential?.user != null) {
        String user_uid = await auth_credential.user.uid;
        String phone_number = await auth_credential.user.phoneNumber;
        saveToSharedPreferences(user_uid, phone_number);
        await DatabaseMethods()
            .fetchUserDetailFromDatabase(user_uid)
            .then((value) async {
          setState(() {
            showLoading = false;
          });
          if (value.exists) {
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => Home(auth_credential.user)));
          } else {
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => Onboarding(auth_credential)));
          }
        });
      } else {
        setState(() {
          this.showLoading = false;
          this.showOTPErrorMessage = true;
        });
      }
    } catch (e) {
      setState(() {
        this.showLoading = false;
        this.showOTPErrorMessage = true;
      });
      print(e);
    }
  }
}
