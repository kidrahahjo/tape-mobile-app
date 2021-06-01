import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:tapemobileapp/app/locator.dart';
import 'package:tapemobileapp/services/authentication_service.dart';

class FirebaseAnalyticsService {
  final FirebaseAnalytics _firebaseAnalytics = FirebaseAnalytics();
  final AuthenticationService _authenticationService =
      locator<AuthenticationService>();

  FirebaseAnalyticsService() {
    if (_authenticationService.currentUser.uid != null) {
      setUserProperties(_authenticationService.currentUser.uid);
    }
  }

  FirebaseAnalyticsObserver getAnalyticsObserver() =>
      FirebaseAnalyticsObserver(analytics: _firebaseAnalytics);

  Future setUserProperties(String userUID) async {
    await _firebaseAnalytics.setUserId(userUID);
  }

  Future logEvent(String eventName,
      {Map<String, dynamic> parameters = const {}}) async {
    print(eventName);
    if (_authenticationService.currentUser.uid != null) {
      print('loggin');
      await _firebaseAnalytics.logEvent(
          name: eventName, parameters: parameters);
    }
  }
}
