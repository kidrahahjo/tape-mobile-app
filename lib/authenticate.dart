import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:wavemobileapp/database.dart';
import 'package:wavemobileapp/home.dart';
import 'package:wavemobileapp/onboarding.dart';
import 'package:wavemobileapp/shared_preferences_helper.dart';

class Authenticate extends StatefulWidget {
  FirebaseAuth auth;

  Authenticate(this.auth);

  @override
  State<StatefulWidget> createState() {
    return _AuthenticateState();
  }
}

class _AuthenticateState extends State<Authenticate> {
  // initialising variables

  // state control variables
  bool showLoading = false;

  // helper variables

  @override
  Widget build(BuildContext context) {
    return showLoading
        ? Center(
            child: CircularProgressIndicator(),
          )
        : MobileForm(widget.auth);
  }
}

class MobileForm extends StatefulWidget {
  final FirebaseAuth auth;
  MobileForm(
    this.auth,
  );
  @override
  _MobileFormState createState() => _MobileFormState();
}

class _MobileFormState extends State<MobileForm> {
  bool showLoading;
  bool showMobileErrorMessage = false;
  String mobileNumber;
  bool mobileFormState = true;
  String verificationId;
  int resendingToken;
  final phoneController = TextEditingController();

  Future verificationThroughServer(String mobileNumber, int resendingToken) {
    return widget.auth.verifyPhoneNumber(
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
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => OtpForm(
                      widget.auth,
                      this.mobileNumber,
                      this.verificationId,
                      this.resendingToken,
                      verificationThroughServer)));
        },
        codeAutoRetrievalTimeout: (verificationId) async {
          // Auto OTP Resolution timeout.
          // TODO: Automatic OTP Handling goes here
        });
  }

  String refactorMobileNumber(String mobileNumber) {
    String result = int.parse(mobileNumber).toString();
    if (result.length == 10) {
      return "+91" + result;
    } else {
      return null;
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(PhosphorIcons.arrowLeft),
          onPressed: () => Navigator.of(context).pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "enter your phone number to start shouting!",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    height: 1.4,
                  ),
                ),
                TextField(
                  controller: phoneController,
                  autofocus: true,
                  onChanged: (value) {
                    setState(() {
                      this.showMobileErrorMessage = false;
                    });
                  },
                  keyboardType: TextInputType.number,
                  maxLength: 10,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                  ],
                ),
                Text(
                  showMobileErrorMessage ? "Error occurred, try again." : "",
                  style: TextStyle(fontSize: 14, color: Colors.red),
                ),
              ],
            ),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                child: Text(
                  "get secret code",
                ),
                style: ElevatedButton.styleFrom(
                    elevation: 0,
                    textStyle: TextStyle(),
                    primary: Colors.white10,
                    onPrimary: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OtpForm extends StatefulWidget {
  FirebaseAuth auth;
  String mobileNumber;
  String verificationId;
  int resendingToken;
  var verificationThroughServer;
  OtpForm(this.auth, this.mobileNumber, this.verificationId,
      this.resendingToken, this.verificationThroughServer);
  @override
  _OtpFormState createState() => _OtpFormState();
}

class _OtpFormState extends State<OtpForm> {
  bool showOTPErrorMessage = false;
  bool showLoading = false;
  final otpController = TextEditingController();

  Future saveToSharedPreferences(uid, phoneNumber) {
    SharedPreferenceHelper().saveUserId(uid);
    SharedPreferenceHelper().saveUserId(phoneNumber);
  }

  signInWithPhoneAuthCredential(
      String verificationId, String otp, context) async {
    try {
      PhoneAuthCredential phoneAuthCredential =
          await PhoneAuthProvider.credential(
              verificationId: verificationId, smsCode: otp);
      UserCredential authCredential =
          await widget.auth.signInWithCredential(phoneAuthCredential);

      if (authCredential?.user != null) {
        String userUid = await authCredential.user.uid;
        String phoneNumber = await authCredential.user.phoneNumber;
        saveToSharedPreferences(userUid, phoneNumber);
        await DatabaseMethods()
            .fetchUserDetailFromDatabase(userUid)
            .then((value) async {
          setState(() {
            showLoading = false;
          });
          if (value.exists) {
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => Home(authCredential.user)));
          } else {
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => Onboarding(authCredential)));
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
      await signInWithPhoneAuthCredential(widget.verificationId, otp, context);
    } else {
      setState(() {
        this.showOTPErrorMessage = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(PhosphorIcons.arrowLeft),
          onPressed: () => Navigator.of(context).pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "shh.. we sent a secret code to ${widget.mobileNumber.substring(0, 3)}-${widget.mobileNumber.substring(3)}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      height: 1.4,
                    ),
                  ),
                  TextField(
                    controller: otpController,
                    autofocus: true,
                    onChanged: (value) {
                      setState(() {
                        this.showOTPErrorMessage = false;
                      });
                    },
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                    ],
                  ),
                  Text(
                    showOTPErrorMessage ? "Invalid OTP, try again." : "",
                    style: TextStyle(fontSize: 14, color: Colors.red),
                  ),
                ],
              ),
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      child: Text(
                        "didn't receive? resend code",
                      ),
                      style: ElevatedButton.styleFrom(
                          elevation: 0,
                          textStyle: TextStyle(),
                          primary: Colors.white10,
                          onPrimary: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8))),
                      onPressed: () async {
                        setState(() {
                          this.showLoading = true;
                        });
                        await widget.verificationThroughServer(
                            widget.mobileNumber, widget.resendingToken);
                      },
                    ),
                  ),
                  SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      child: Text(
                        "login",
                      ),
                      style: ElevatedButton.styleFrom(
                          elevation: 0,
                          textStyle: TextStyle(),
                          primary: Colors.white10,
                          onPrimary: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8))),
                      onPressed: () async {
                        await verifyOTP(otpController.text);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
