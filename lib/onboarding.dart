import 'package:connectivity/connectivity.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:wavemobileapp/app_bar.dart';
import 'package:wavemobileapp/database.dart';
import 'package:wavemobileapp/home.dart';
import 'package:wavemobileapp/shared_preferences_helper.dart';

class Onboarding extends StatefulWidget {
  UserCredential auth_credential;

  Onboarding(@required this.auth_credential);

  @override
  State<StatefulWidget> createState() {
    return _OnboardingState(auth_credential);
  }
}

class _OnboardingState extends State<Onboarding> {
  // initialising variables
  UserCredential auth_credential;

  // state control variables
  bool showLoading = false;
  bool showError = false;
  String errorMessage = "";

  // helper variables
  final nameController = TextEditingController();

  _OnboardingState(this.auth_credential);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: showLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : SafeArea(child: onboardForm(context)),
    );
  }

  Widget onboardForm(context) {
    return Column(
      children: <Widget>[
        SizedBox(height: 40),
        Container(
            constraints: BoxConstraints.expand(
              height: 220,
            ),
            alignment: Alignment.bottomLeft,
            padding: EdgeInsets.all(20),
            child: Text(
              "What do your friends call you?",
              style: TextStyle(fontSize: 28, height: 1.5, color: Colors.black),
            )),
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
                  controller: nameController,
                  autofocus: true,
                  style: TextStyle(fontSize: 16),
                  onChanged: (value) {
                    setState(() {
                      this.showError = false;
                      this.errorMessage = "";
                    });
                  },
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.only(left: 15),
                    border: InputBorder.none,
                    counterText: "",
                    hintText: "Your nickname",
                  ),
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
                showError ? errorMessage : "",
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
                  color: Colors.black,
                  shape: ContinuousRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  child: MaterialButton(
                    child: Text(
                      "Start Shouting!",
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    ),
                    onPressed: () async {
                      String name = nameController.text;
                      if (name.length == 0) {
                        setState(() {
                          this.errorMessage = "You must have some name?";
                          this.showError = true;
                        });
                      } else {
                        setState(() {
                          showLoading = true;
                        });
                        await updateUserDisplayName(name, context);
                      }
                    },
                  ),
                ))),
      ],
    );
  }

  Future<void> updateUserDisplayName(String name, context) async {
    try {
      Map<String, String> data = {
        "displayName": name,
        "phoneNumber": await auth_credential.user.phoneNumber,
      };
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult == ConnectivityResult.none) {
        setState(() {
          showLoading = false;
          showError = true;
          errorMessage = "Internet issues, try again.";
        });
      } else {
        await DatabaseMethods()
            .addUserInfoToDatabase(await auth_credential.user.uid, data)
            .then((value) async {
          setState(() {
            showLoading = false;
          });

          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => Home(auth_credential.user)));
        });
      }
    } catch (e) {
      setState(() {
        showLoading = false;
        showError = true;
        errorMessage = "Error occurred, try again.";
      });
    }
  }
}
