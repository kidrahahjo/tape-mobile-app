import 'package:flutter_local_notifications/flutter_local_notifications.dart';

const List<String> notificationChannels = ["tapes", "waves", "silent"];

const Map<String, String> notificationChannelTypeNameMapping = {
  "tapes": "Tapes",
  "waves": "Waves",
  "silent": "Silent Notifications",
};

const Map<String, String> notificationChannelTypeDescriptionMapping = {
  "tapes": "Notification received when someone sends you a Tape",
  "waves": "Notification received when someone waves at you.",
  "silent": "Silent Notifications",
};

const Map<String, Importance> notificationChannelImportanceMapping = {
  "tapes": Importance.max,
  "waves": Importance.max,
  "silent": Importance.defaultImportance,
};

const Map<String, bool> notificationChannelPlaySoundMapping = {
  "tapes": true,
  "waves": true,
  "silent": false,
};
