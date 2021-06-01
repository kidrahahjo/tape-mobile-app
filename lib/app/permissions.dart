import 'package:permission_handler/permission_handler.dart';

Future<bool> getMicrophonePermission() async {
  PermissionStatus permission = await Permission.microphone.status;
  if (!permission.isGranted) {
    await Permission.microphone.request();
    permission = await Permission.microphone.status;
  }
  return permission.isGranted;
}

Future<bool> getStoragePermission() async {
  PermissionStatus permission = await Permission.storage.status;
  if (!permission.isGranted) {
    await Permission.storage.request();
    permission = await Permission.storage.status;
  }
  return permission.isGranted;
}

Future<bool> getContactPermission() async {
  PermissionStatus permission = await Permission.contacts.status;
  if (!permission.isGranted) {
    await Permission.contacts.request();
    permission = await Permission.contacts.status;
  }
  return permission.isGranted;
}
