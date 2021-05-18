import 'package:wavemobileapp/services/authentication_service.dart';
import 'package:wavemobileapp/services/firstore_service.dart';
import 'package:wavemobileapp/services/navigation_service.dart';
import 'package:wavemobileapp/viewmodel/base_model.dart';
import '../routing_constants.dart' as routes;

import '../locator.dart';

class StartupViewModel extends BaseModel {
  final AuthenticationService _authenticationService =
      locator<AuthenticationService>();
  final NavigationService _navigationService = locator<NavigationService>();
  final FirestoreService _firestoreService = locator<FirestoreService>();

  Future handleStartupLogic() async {
    bool hasLoggedIn = await _authenticationService.isUserLoggedIn();
    if (hasLoggedIn) {
      await _firestoreService
          .getUserData(_authenticationService.currentUser.uid)
          .then((value) {
        Map<String, String> data = {
          'userUID': _authenticationService.currentUser.uid,
          'phoneNumber': _authenticationService.currentUser.phoneNumber
        };
        if (value.exists) {
          _navigationService.navigateReplacementTo(routes.HomeViewRoute,
              arguments: data);
        } else {
          _navigationService.navigateReplacementTo(routes.OnboardingViewRoute,
              arguments: data);
        }
      });
    } else {
      _navigationService.navigateReplacementTo(routes.AuthenticationViewRoute);
    }
  }
}
