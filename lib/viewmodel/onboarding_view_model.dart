import 'package:wavemobileapp/locator.dart';
import 'package:wavemobileapp/services/firstore_service.dart';
import 'package:wavemobileapp/services/navigation_service.dart';
import 'package:wavemobileapp/viewmodel/base_model.dart';
import 'package:wavemobileapp/routing_constants.dart' as routes;

class OnboardingViewModel extends BaseModel {
  final String userUID;
  final String phoneNumber;
  final FirestoreService _firestoreService = locator<FirestoreService>();
  final NavigationService _navigationService = locator<NavigationService>();
  bool showError = false;

  OnboardingViewModel(this.userUID, this.phoneNumber);

  saveUserInfo(String displayName) async {
    setBusy(true);
    if (displayName.length == 0) {
      showError = true;
      setBusy(false);
      notifyListeners();
    } else {
      Map<String, dynamic> data = {
        'displayName': displayName,
        'phoneNumber': phoneNumber,
        'hasOnboarded': true,
      };
      _firestoreService.saveUserInfo(userUID, data)
      .onError((error, stackTrace) {
        showError = true;
        setBusy(false);
      })
      .then((value) {
        setBusy(false);
        _navigationService
            .navigateReplacementTo(routes.HomeViewRoute, arguments: {
          'userUID': userUID,
          'phoneNumber': phoneNumber,
        });
      });
    }
  }
}
