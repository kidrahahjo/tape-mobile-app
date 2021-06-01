import 'package:firebase_auth/firebase_auth.dart';
import 'package:tapemobileapp/app/locator.dart';
import 'package:stacked/stacked.dart';
import 'package:tapemobileapp/services/firestore_service.dart';

class AuthenticationService with ReactiveServiceMixin {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirestoreService firestoreService = locator<FirestoreService>();

  String _verificationID;
  int _resendingToken;
  String _refactoredNumber;

  ReactiveValue<String> _authState = ReactiveValue<String>("Mobile");

  AuthenticationService() {
    listenToReactiveValues([_authState]);
  }

  String get verificationID => _verificationID;

  int get resendingToken => _resendingToken;

  User get currentUser => auth.currentUser;

  String get authState => _authState.value;

  Future<bool> isUserLoggedIn() async {
    User user = auth.currentUser;
    return user != null;
  }

  signOutUser() async {
    try {
      await auth.signOut();
      return auth.currentUser == null;
    } catch (e) {
      return false;
    }
  }

  onVerificationCompleted(PhoneAuthCredential phoneAuthCredential) {
    _authState.value = "OTP Sent";
  }

  onVerificationFailed(FirebaseAuthException exception) {
    _authState.value = "Mobile";
  }

  onCodeSent(String verificationID, int resendingToken) {
    _authState.value = "OTP Sent";
    this._verificationID = verificationID;
    this._resendingToken = resendingToken;
  }

  onCodeAutoRetrievalTimeout(String verificationID) {
    return null;
  }

  resetAuthState() {
    _authState.value = "Mobile";
  }

  Future sendOTP(String mobileNumber) async {
    _authState.value = "Loading";
    if (this._refactoredNumber != mobileNumber) {
      this._verificationID = null;
      this._resendingToken = null;
      this._refactoredNumber = mobileNumber;
    }
    return auth.verifyPhoneNumber(
        phoneNumber: mobileNumber,
        forceResendingToken: resendingToken,
        timeout: Duration(seconds: 15),
        verificationCompleted: onVerificationCompleted,
        verificationFailed: onVerificationFailed,
        codeSent: onCodeSent,
        codeAutoRetrievalTimeout: onCodeAutoRetrievalTimeout);
  }

  Future resendOTP() async {
    return sendOTP(_refactoredNumber);
  }

  signInWithPhoneAuthCredential(String otp) async {
    _authState.value = "Loading";
    try {
      PhoneAuthCredential phoneAuthCredential = PhoneAuthProvider.credential(
          verificationId: _verificationID, smsCode: otp);
      UserCredential authCredential =
          await auth.signInWithCredential(phoneAuthCredential);
      if (authCredential == null) {
        _authState.value = "OTP Sent";
        return {
          'userVerified': false,
        };
      } else {
        return await firestoreService
            .getUserData(authCredential.user.uid)
            .then((value) {
          if (value.exists) {
            Map<String, dynamic> data = value.data();
            return {
              'userVerified': true,
              'userOnboarded':
                  data['hasOnboarded'] == null ? false : data['hasOnboarded'],
              'userUID': authCredential.user.uid,
            };
          } else {
            return {
              'userVerified': true,
              'userOnboarded': false,
              'userUID': authCredential.user.uid,
            };
          }
        });
      }
    } catch (e) {
      _authState.value = "OTP Sent";
      return {
        'userVerified': false,
        'error': e,
      };
    }
  }
}
