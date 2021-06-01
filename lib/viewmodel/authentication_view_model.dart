import 'package:tapemobileapp/app/locator.dart';
import 'package:stacked/stacked.dart';
import 'package:tapemobileapp/services/navigation_service.dart';
import 'package:tapemobileapp/services/authentication_service.dart';
import 'package:tapemobileapp/app/routing_constants.dart' as routes;
import 'package:tapemobileapp/utils/phone_utils.dart';

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

  getOTP(String mobileNumber) async {
    String refactoredNumber = refactorPhoneNumber(mobileNumber);
    if (refactoredNumber == null) {
      setMobileVariables(mobileNumber, true);
    } else {
      await _authenticationService.sendOTP(refactoredNumber);
      setMobileVariables(mobileNumber, false);
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
