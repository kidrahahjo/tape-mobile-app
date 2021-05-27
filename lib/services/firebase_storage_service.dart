import 'package:firebase_storage/firebase_storage.dart';

class FirebaseStorageService {
  final FirebaseStorage firebaseStorage = FirebaseStorage.instance;

  Reference getLocationReference(String chatUID, String shoutUID) {
    return firebaseStorage.ref("audio/$chatUID/$shoutUID.aac");
  }

  Reference getProfilePicLocationReference(String myUID) {
    return firebaseStorage.ref("profile-pic/$myUID.jpg");
  }
}
