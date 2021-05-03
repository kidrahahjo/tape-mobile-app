import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:wavemobileapp/app_bar.dart';
import 'package:wavemobileapp/database.dart';
import 'package:wavemobileapp/home.dart';
import 'package:wavemobileapp/shared_preferences_helper.dart';

class Onboarding extends StatefulWidget {
  dynamic auth_credential;

  Onboarding(@required this.auth_credential);

  @override
  State<StatefulWidget> createState() {
    return _OnboardingState(auth_credential);
  }
}

class _OnboardingState extends State<Onboarding> {
  UserCredential auth_credential;
  bool showLoading = false;

  _OnboardingState(this.auth_credential);

  final nameController = TextEditingController();

  Future<void> updateUserDisplayName(String name, context) async {
    setState(() {
      showLoading = true;
    });

    try {
      await auth_credential.user.updateProfile(displayName: name);
      await auth_credential.user.reload();
      // Instantiating the user again due to this
      // https://stackoverflow.com/questions/51709733/what-use-case-has-the-reload-function-of-a-firebaseuser-in-flutter
      User user = await FirebaseAuth.instance.currentUser;

      SharedPreferenceHelper().saveUserId(user.uid);
      SharedPreferenceHelper().saveDisplayName(user.displayName);
      SharedPreferenceHelper().saveUserPhoneNumber(user.phoneNumber);

      Map<String, String> data = {
        "displayName": user.displayName,
        "phoneNumber": user.phoneNumber,
      };

      DatabaseMethods().addUserInfoToDatabase(user.uid, data).then(
          (value) async {
            setState(() {
              showLoading = false;
            });

            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (context) => Home(user)));
          }
      );

    } catch (e) {
      setState(() {
        showLoading = false;
      });
      final ScaffoldMessengerState scaffoldMessenger =
          ScaffoldMessenger.of(context);
      scaffoldMessenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  onboardForm(context) {
    return Column(
      children: <Widget>[
        CustomAppBar(),
        Spacer(),
        TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'Display Name',
            contentPadding: EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
        TextButton(
            child: Text("Join the wave"),
            onPressed: () async {
              String name = nameController.text;
              if (name.length == 0) {
                final ScaffoldMessengerState scaffoldMessenger =
                    ScaffoldMessenger.of(context);
                scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text("Please enter a display name")));
              } else {
                updateUserDisplayName(name, context);
              }
            }),
        Spacer()
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: showLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : onboardForm(context),
    );
  }
}
