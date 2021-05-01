import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseMethods {
  Future addUserInfoToDatabase(
      String userIdKey, Map<String, String> data) async {
    return FirebaseFirestore.instance
        .collection("users")
        .doc(userIdKey)
        .set(data);
  }
}
