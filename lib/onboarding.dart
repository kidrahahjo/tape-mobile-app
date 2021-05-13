import 'package:connectivity/connectivity.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:wavemobileapp/database.dart';
import 'package:wavemobileapp/home.dart';

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
    return showLoading
        ? Center(
            child: CircularProgressIndicator(),
          )
        : Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
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
                        "what do your friends call you?",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          height: 1.4,
                        ),
                      ),
                      TextField(
                        controller: nameController,
                        autofocus: true,
                        onChanged: (value) {
                          setState(() {
                            this.showError = false;
                            this.errorMessage = "";
                          });
                        },
                        maxLength: 10,
                      ),
                      Text(
                        showError ? errorMessage : "",
                        style: TextStyle(fontSize: 14, color: Colors.red),
                      ),
                    ],
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      child: Text(
                        "let's shout!",
                      ),
                      style: ElevatedButton.styleFrom(
                          elevation: 0,
                          textStyle: TextStyle(),
                          primary: Colors.white10,
                          onPrimary: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8))),
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
                  ),
                ],
              ),
            ),
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
