import 'package:firebase_storage/firebase_storage.dart';

class FirebaseStorageService {
  final FirebaseStorage firebaseStorage = FirebaseStorage.instance;

  Reference getLocationReference(String chatUID, String shoutUID) {
    return firebaseStorage.ref("audio/$chatUID/$shoutUID.aac");
  }
}
