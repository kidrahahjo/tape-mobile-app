import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:tapemobileapp/viewmodel/onboarding_view_model.dart';

class OnboardingView extends StatelessWidget {
  final String userUID;
  final String phoneNumber;

  OnboardingView(this.userUID, this.phoneNumber);

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<OnboardingViewModel>.reactive(
        viewModelBuilder: () =>
            OnboardingViewModel(this.userUID, this.phoneNumber),
        builder: (context, model, child) {
          return model.busy
              ? Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              : OnboardingForm(model);
        });
  }
}

class OnboardingForm extends StatefulWidget {
  final OnboardingViewModel model;

  OnboardingForm(this.model);

  @override
  State<StatefulWidget> createState() {
    return _OnboardingFormState();
  }
}

class _OnboardingFormState extends State<OnboardingForm> {
  TextEditingController nameController = new TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
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
                  maxLength: 10,
                ),
                Text(
                  widget.model.showError ? "Oops, try again." : "",
                  style: TextStyle(
                    fontSize: 14,
                  ),
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
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))),
                onPressed: () async {
                  widget.model.saveUserInfo(nameController.text);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
