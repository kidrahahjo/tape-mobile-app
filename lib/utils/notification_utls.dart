import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:tapemobileapp/app/notification_constants.dart';
import 'package:flutter_cache/flutter_cache.dart' as cache;
import 'dart:convert';

initialiseChannels() async {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final List<AndroidNotificationChannel> channels =
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          .getNotificationChannels();

  List<String> channelIDs = [];
  List<String> channelsToDelete = [];
  for (AndroidNotificationChannel channel in channels) {
    if (notificationChannels.contains(channel.id)) {
      channelIDs.add(channel.id);
    } else {
      channelsToDelete.add(channel.id);
    }
  }

  for (String channelID in channelsToDelete) {
    await deleteNotificationChannel(channelID);
  }
  List<String> myChannels = notificationChannels;
  for (String channelID in myChannels) {
    if (!channelIDs.contains(channelID)) {
      AndroidNotificationChannel androidNotificationChannel =
          AndroidNotificationChannel(
        channelID,
        notificationChannelTypeNameMapping[channelID],
        notificationChannelTypeDescriptionMapping[channelID],
        importance: notificationChannelImportanceMapping[channelID] == null
            ? Importance.defaultImportance
            : notificationChannelImportanceMapping[channelID],
        showBadge: true,
        playSound: notificationChannelPlaySoundMapping[channelID] == null
            ? false
            : notificationChannelPlaySoundMapping[channelID],
      );
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidNotificationChannel);
    }
  }
}

deleteNotificationChannel(String channelID) async {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.deleteNotificationChannel(channelID);
}

Future<void> showNotification(RemoteMessage message) async {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Initialise Notification Settings
  AndroidInitializationSettings initializationSettingsAndroid =
      new AndroidInitializationSettings("@mipmap/ic_stat_icon");
  IOSInitializationSettings initializationSettingsIOS =
      new IOSInitializationSettings();
  InitializationSettings initializationSettings = new InitializationSettings(
      android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
  _flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
  );

  // Code to send notification
  String channel_id = message.data['notificationChannelID'];
  String tag = message.data['notificationTag'];
  String phoneNumber = message.data['phoneNumber'];
  String displayName = message.data['displayName'];
  String userName;

  try {
    Map<String, String> data = Map<String, String>.from(
        await cache.load('userNumberContactNameMapping'));
    if (data != null && data[phoneNumber] != null) {
      userName = data[phoneNumber];
    }
  } catch (err) {
    print("Some error occured");
    print(err);
  }

  // Setup notification details.
  AndroidNotificationDetails androidNotificationDetails =
      new AndroidNotificationDetails(
          channel_id,
          notificationChannelTypeNameMapping[channel_id],
          notificationChannelTypeDescriptionMapping[channel_id],
          priority: Priority.max,
          tag: tag,
          visibility: NotificationVisibility.public,
          groupKey: message.data['notificationTitle'].contains("Tape")
              ? "Tapes"
              : "Waves",
          channelAction: AndroidNotificationChannelAction.createIfNotExists);
  IOSNotificationDetails iosNotificationDetails = new IOSNotificationDetails();
  NotificationDetails notificationDetails = new NotificationDetails(
      android: androidNotificationDetails, iOS: iosNotificationDetails);

  // define payload
  Map<String, dynamic> payload = {
    "sendTo": "chat",
    "data": {
      "userUID": tag,
    }
  };
  if (userName == null) {
    userName = displayName;
  }

  if (userName != null) {
    userName = userName.split(" ")[0];
  }
  // push notification
  try {
    _flutterLocalNotificationsPlugin.show(
      message.data['notificationTitle'].contains("Tape") ? 0 : 1,
      userName + " " + message.data['notificationTitle'],
      message.data['notificationBody'],
      notificationDetails,
      payload: json.encode(payload),
    );
  } catch (err) {
    print("Some error occured");
    print(err);
  }
}
