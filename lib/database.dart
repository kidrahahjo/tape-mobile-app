import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseMethods {
  Future addUserInfoToDatabase(String userIdKey,
      Map<String, String> data) async {
    return FirebaseFirestore.instance
        .collection("users")
        .doc(userIdKey)
        .set(data);
  }

  Future addCollectionInUser(String myUID) async {
    return FirebaseFirestore.instance
        .collection("users")
        .doc(myUID)
        .collection("chats").add({
      "userUID": {
        "lastModifiedAt": DateTime.now(),
      }
    });
  }

  Future updateLastTimeStamp(String myUID, String userUID,
      Map<String, DateTime> data) async {
    try {
      return FirebaseFirestore.instance
          .collection("users")
          .doc(myUID)
          .collection("chats")
          .doc(userUID)
          .set(data);
    } catch (e) {
      return null;
    }
  }

}
