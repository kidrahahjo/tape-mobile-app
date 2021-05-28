import 'package:cloud_firestore/cloud_firestore.dart';

String getTimeDifference(DateTime dateTime) {
  Duration difference = DateTime.now().difference(dateTime);
  int day = difference.inDays;
  int hours = difference.inHours;
  int minutes = difference.inMinutes;
  int seconds = difference.inSeconds;
  if (day != 0) {
    return day.toString() + 'd ago';
  } else if (hours != 0) {
    return hours.toString() + 'h ago';
  } else if (minutes != 0) {
    return minutes.toString() + 'm ago';
  } else if (seconds >= 20) {
    return seconds.toString() + 's ago';
  } else {
    return 'Just now';
  }
}

convertTimestampToDateTime(Timestamp time) {
  if (time == null) {
    return null;
  } else {
    return DateTime.fromMicrosecondsSinceEpoch(time.microsecondsSinceEpoch);
  }
}

int compareDateTimeGreaterThan(DateTime d1, DateTime d2) {
  return d1.isAfter(d2) ? 1 : 0;
}
