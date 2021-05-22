import 'package:get_it/get_it.dart';
import 'package:wavemobileapp/services/authentication_service.dart';
import 'package:wavemobileapp/services/chat_service.dart';
import 'package:wavemobileapp/services/firebase_storage_service.dart';
import 'package:wavemobileapp/services/firstore_service.dart';
import 'package:wavemobileapp/services/navigation_service.dart';

GetIt locator = GetIt.instance;

void setupLocator() {
  locator.registerLazySingleton(() => AuthenticationService());
  locator.registerLazySingleton(() => NavigationService());
  locator.registerLazySingleton(() => FirestoreService());
  locator.registerLazySingleton(() => ChatService());
  locator.registerLazySingleton(() => FirebaseStorageService());
}
