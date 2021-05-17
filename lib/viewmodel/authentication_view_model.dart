import 'package:wavemobileapp/locator.dart';
import 'package:wavemobileapp/services/navigation_service.dart';
import 'package:wavemobileapp/viewmodel/base_model.dart';
import 'package:wavemobileapp/services/authentication_service.dart';
import 'package:wavemobileapp/routing_constants.dart' as routes;

class AuthenticationViewModel extends BaseModel {
  final AuthenticationService _authenticationService =
      locator<AuthenticationService>();
  final NavigationService _navigationService = locator<NavigationService>();

  bool _hasMobileError = false;
  bool _hasOTPError = false;
  bool _showMobile = true;
  String _mobileNumber = "";
  String refactoredMobileNumber = "";

  bool get mobileError => _hasMobileError;

  bool get otpError => _hasOTPError;

  bool get mobileState => _showMobile;

  String get mobileNumber => _mobileNumber;

  String get refactoredNumber => "+91-$_mobileNumber";

  setMobileVariables(String mobileNumber, bool showMobile, bool mobileError) {
    this._mobileNumber = mobileNumber;
    this._showMobile = showMobile;
    this._hasMobileError = mobileError;
  }

  setOTPVariables(bool otpError) {
    this._hasOTPError = otpError;
  }

  String refactorMobileNumber(String mobileNumber) {
    try {
      if (mobileNumber.startsWith("+91")) {
        return mobileNumber;
      }
      String result = int.parse(mobileNumber).toString();
      if (result.length == 10) {
        return "+91" + result;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  getOTP(String mobileNumber, {int resendingToken}) async {
    setBusy(true);
    String refactoredNumber = refactorMobileNumber(mobileNumber);
    if (refactoredNumber == null) {
      setMobileVariables(mobileNumber, true, true);
    } else {
      await _authenticationService.sendOTP(refactoredNumber, resendingToken);
      setMobileVariables(mobileNumber, false, false);
    }
    setBusy(false);
  }

  String refactorOTP(String otp) {
    if (otp == null || otp.length != 6) {
      return null;
    } else {
      return otp;
    }
  }

  verifyOTP(String otp) async {
    setBusy(true);
    String refactoredOTP = refactorOTP(otp);
    if (refactoredOTP != null) {
      Map<String, dynamic> result =
          await _authenticationService.signInWithPhoneAuthCredential(otp);
      if (result['userVerified']) {
        Map<String, String> data = {
          'userUID': _authenticationService.currentUser.uid,
          'phoneNumber': _authenticationService.currentUser.phoneNumber,
        };
        if (result['userOnboarded']) {
          _navigationService.navigateReplacementTo(routes.HomeViewRoute,
              arguments: data);
        } else {
          _navigationService.navigateReplacementTo(routes.OnboardingViewRoute,
              arguments: data);
        }
      } else {
        setOTPVariables(true);
      }
      setBusy(false);
    } else {
      setOTPVariables(true);
      setBusy(false);
    }
  }

  resendOTP(String refactoredMobileNumber) async {
    setBusy(true);
    await _authenticationService.resendOTP(refactoredNumber);
    setOTPVariables(false);
    setBusy(false);
  }

  backToMobile() {
    this._showMobile = true;
    this._hasMobileError = false;
    this._hasOTPError = false;
    notifyListeners();
  }
}
