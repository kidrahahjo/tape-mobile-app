import 'package:stacked/stacked.dart';
import 'package:tapemobileapp/locator.dart';
import 'package:tapemobileapp/services/navigation_service.dart';
import 'package:tapemobileapp/viewmodel/base_model.dart';
import 'package:tapemobileapp/services/authentication_service.dart';
import 'package:tapemobileapp/routing_constants.dart' as routes;

class AuthenticationViewModel extends ReactiveViewModel {
  final AuthenticationService _authenticationService =
      locator<AuthenticationService>();
  final NavigationService _navigationService = locator<NavigationService>();

  bool _hasMobileError = false;
  bool _hasOTPError = false;
  String _mobileNumber = "";
  String refactoredMobileNumber = "";


  @override
  List<ReactiveServiceMixin> get reactiveServices => [_authenticationService];


  bool get mobileError => _hasMobileError;

  bool get otpError => _hasOTPError;


  String get mobileNumber => _mobileNumber;

  String get refactoredNumber => "+91-$_mobileNumber";

  String get authState => _authenticationService.authState;


  setMobileVariables(String mobileNumber, bool mobileError) {
    this._mobileNumber = mobileNumber;
    this._hasMobileError = mobileError;
    notifyListeners();
  }


  setOTPVariables(bool otpError) {
    this._hasOTPError = otpError;
    notifyListeners();
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


  getOTP(String mobileNumber) async {
    String refactoredNumber = refactorMobileNumber(mobileNumber);
    if (refactoredNumber == null) {
      setMobileVariables(mobileNumber, true);
    } else {
      await _authenticationService.sendOTP(refactoredNumber);
      setMobileVariables(mobileNumber, false);
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
        _authenticationService.resetAuthState();
      } else {
        setOTPVariables(true);
      }
    } else {
      setOTPVariables(true);
    }
  }


  resendOTP() async {
    await _authenticationService.resendOTP();
    setOTPVariables(false);
  }


  backToMobile() {
    this._hasMobileError = false;
    this._hasOTPError = false;
    _authenticationService.resetAuthState();
  }
}
