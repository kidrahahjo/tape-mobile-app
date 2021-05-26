import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:stacked/stacked.dart';
import 'package:tapemobileapp/viewmodel/authentication_view_model.dart';

class AuthenticationView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<AuthenticationViewModel>.reactive(
        viewModelBuilder: () => AuthenticationViewModel(),
        builder: (context, model, child) {
          return model.busy
              ? Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              : model.mobileState
                  ? MobileFormWidget(model)
                  : OTPFormWidget(model);
        });
  }
}

class MobileFormWidget extends StatelessWidget {
  final AuthenticationViewModel model;
  final TextEditingController phoneController = TextEditingController();

  MobileFormWidget(this.model) {
    phoneController.text = model.mobileNumber;
    phoneController.selection = TextSelection.fromPosition(
        TextPosition(offset: phoneController.text.length));
  }

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
                  "Enter your phone number to start Taping!",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    height: 1.4,
                  ),
                ),
                TextField(
                  controller: phoneController,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  maxLength: 10,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                  ],
                ),
                Text(
                  model.mobileError ? "Oops, try again." : "",
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
                  "Get secret code",
                ),
                style: ElevatedButton.styleFrom(
                    elevation: 0,
                    textStyle: TextStyle(),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))),
                onPressed: () {
                  model.getOTP(phoneController.text);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OTPFormWidget extends StatelessWidget {
  final AuthenticationViewModel model;
  final TextEditingController otpController = TextEditingController();

  OTPFormWidget(this.model);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(PhosphorIcons.arrowLeft),
          onPressed: () {
            model.backToMobile();
          },
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
                    "Shh... we sent a secret code to ${model.refactoredNumber}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      height: 1.4,
                    ),
                  ),
                  TextField(
                    controller: otpController,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                    ],
                  ),
                  Text(
                    model.otpError ? "Invalid OTP, try again." : "",
                    style: TextStyle(
                      fontSize: 14,
                    ),
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
                        "Didn't receive? Resend code",
                      ),
                      style: ElevatedButton.styleFrom(
                          elevation: 0,
                          textStyle: TextStyle(),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8))),
                      onPressed: () {},
                    ),
                  ),
                  SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      child: Text(
                        "Login",
                      ),
                      style: ElevatedButton.styleFrom(
                          elevation: 0,
                          textStyle: TextStyle(),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8))),
                      onPressed: () {
                        model.verifyOTP(otpController.text);
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
