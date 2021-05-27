import 'package:tapemobileapp/services/authentication_service.dart';
import 'package:tapemobileapp/services/firestore_service.dart';
import 'package:tapemobileapp/services/navigation_service.dart';
import 'package:tapemobileapp/viewmodel/base_model.dart';
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
        bool hasOnboarded = false;
        if (value.exists) {
          Map<String, dynamic> metadata = value.data();
          hasOnboarded = metadata['hasOnboarded'] == null
              ? false
              : metadata['hasOnboarded'];
        }
        if (hasOnboarded) {
          _navigationService.navigateReplacementTo(routes.HomeViewRoute,
              arguments: data);
        } else {
          _navigationService.navigateReplacementTo(routes.HomeViewRoute,
              arguments: data);
        }
      });
    } else {
      _navigationService.navigateReplacementTo(routes.AuthenticationViewRoute);
    }
  }
}
