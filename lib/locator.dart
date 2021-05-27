import 'package:get_it/get_it.dart';
import 'package:tapemobileapp/services/authentication_service.dart';
import 'package:tapemobileapp/services/chat_service.dart';
import 'package:tapemobileapp/services/firebase_storage_service.dart';
import 'package:tapemobileapp/services/firestore_service.dart';
import 'package:tapemobileapp/services/navigation_service.dart';
import 'package:tapemobileapp/services/push_notification_service.dart';

GetIt locator = GetIt.instance;

void setupLocator() {
  locator.registerLazySingleton(() => AuthenticationService());
  locator.registerLazySingleton(() => NavigationService());
  locator.registerLazySingleton(() => FirestoreService());
  locator.registerLazySingleton(() => ChatService());
  locator.registerLazySingleton(() => FirebaseStorageService());
  locator.registerLazySingleton(() => PushNotification());
}
