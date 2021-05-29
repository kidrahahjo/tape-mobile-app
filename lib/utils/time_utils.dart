import 'package:cloud_firestore/cloud_firestore.dart';

String getTimeDifference(DateTime dateTime) {
  Duration difference = DateTime.now().difference(dateTime);
  int day = difference.inDays;
  int hours = difference.inHours;
  int minutes = difference.inMinutes;
  int seconds = difference.inSeconds;
  if (day != 0) {
    return day.toString() + 'd';
  } else if (hours > 0) {
    return hours.toString() + 'h';
  } else if (minutes > 0) {
    return minutes.toString() + 'm';
  } else if (seconds > 0) {
    return seconds.toString() + 's';
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
  if (d1 == null) {
    return 0;
  } else if (d2 == null) {
    return 1;
  }
  return d1.isAfter(d2) ? 1 : 0;
}
