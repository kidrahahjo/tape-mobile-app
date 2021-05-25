import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:tapemobileapp/locator.dart';
import 'package:tapemobileapp/services/firstore_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class PushNotification {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirestoreService _firestoreService = locator<FirestoreService>();
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  void configLocalNotification() {
    var initializationSettingsAndroid =
        new AndroidInitializationSettings("@mipmap/launcher_icon");
    var initializationSettingsIOS = new IOSInitializationSettings();
    var initializationSettings = new InitializationSettings(
        android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
    _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  initialise(String userUID) async {
    await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: true,
      provisional: true,
      sound: true,
    );

    _firebaseMessaging.getToken().then((token) {
      _firestoreService.saveUserInfo(userUID, {"fcmToken": token});
    }).onError((error, stackTrace) => null);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      configLocalNotification();
      RemoteNotification notification = message.notification;
      AndroidNotification android = notification?.android;
      bool isTape = message.data['type'] == 'Tape';
      var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
        'com.jointape.app',
        'Tapes',
        'Notification for Tapes',
        playSound: true,
        enableVibration: !isTape,
      );
      var iOSPlatformChannelSpecifics = new IOSNotificationDetails();
      var platformChannelSpecifics = new NotificationDetails(
          android: androidPlatformChannelSpecifics,
          iOS: iOSPlatformChannelSpecifics);
      if (notification != null && android != null) {
        _flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          platformChannelSpecifics,
        );
      }
    });
  }
}
