import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:tapemobileapp/app/locator.dart';
import 'package:tapemobileapp/services/firestore_service.dart';
import 'package:tapemobileapp/utils/notification_utls.dart';

class PushNotification {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirestoreService _firestoreService = locator<FirestoreService>();

  initialise(String userUID) async {
    NotificationSettings setting = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: true,
      provisional: true,
      sound: true,
    );

    if (Platform.isAndroid) {
      await initialiseChannels();
    }

    if (setting.authorizationStatus == AuthorizationStatus.authorized) {
      _firebaseMessaging.getToken().then((token) {
        _firestoreService.saveUserInfo(userUID, {"fcmToken": token});
      }).onError((error, stackTrace) => null);
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        showNotification(message);
      });
    }
  }
}
