// import 'package:firebase_analytics/firebase_analytics.dart';
// import 'package:firebase_analytics/observer.dart';

// class FirebaseAnalyticsService {
//   final FirebaseAnalytics _firebaseAnalytics = FirebaseAnalytics();

//   FirebaseAnalyticsObserver getAnalyticsObserver () => FirebaseAnalyticsObserver(analytics: _firebaseAnalytics);

//   Future setUserProperties(String userUID) async {
//     await _firebaseAnalytics.setUserId(userUID);
//   }

//   Future logEvent(String eventName, {Map<String, dynamic> parameters = const {}}) async {
//     await _firebaseAnalytics.logEvent(name: eventName, parameters: parameters);
//   }
// }