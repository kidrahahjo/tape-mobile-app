import 'package:firebase_auth/firebase_auth.dart';
import 'package:tapemobileapp/locator.dart';
import 'package:tapemobileapp/services/firestore_service.dart';

class AuthenticationService {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirestoreService firestoreService = locator<FirestoreService>();

  String _verificationID;
  int _resendingToken;

  String get verificationID => _verificationID;
  int get resendingToken => _resendingToken;

  User get currentUser => auth.currentUser;

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
    return null;
  }

  onVerificationFailed(FirebaseAuthException exception) {
    throw (exception);
  }

  onCodeSent(String verificationID, int resendingToken) {
    this._verificationID = verificationID;
    this._resendingToken = resendingToken;
  }

  onCodeAutoRetrievalTimeout(String verificationID) {
    return null;
  }

  Future sendOTP(String mobileNumber, int resendingToken) async {
    return auth.verifyPhoneNumber(
        phoneNumber: mobileNumber,
        forceResendingToken: resendingToken,
        timeout: Duration(seconds: 15),
        verificationCompleted: onVerificationCompleted,
        verificationFailed: onVerificationFailed,
        codeSent: onCodeSent,
        codeAutoRetrievalTimeout: onCodeAutoRetrievalTimeout);
  }

  Future resendOTP(String mobileNumber) async {
    return sendOTP(mobileNumber, this._resendingToken);
  }

  signInWithPhoneAuthCredential(String otp) async {
    try {
      PhoneAuthCredential phoneAuthCredential = PhoneAuthProvider.credential(
          verificationId: _verificationID, smsCode: otp);
      UserCredential authCredential =
          await auth.signInWithCredential(phoneAuthCredential);
      if (authCredential == null) {
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
      return {
        'userVerified': false,
        'error': e,
      };
    }
  }
}
