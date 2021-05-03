import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseMethods {
  Future<Stream<QuerySnapshot>> fetchChatFromDatabase (String myUID, userUID) async {
    return FirebaseFirestore.instance
        .collection("users")
        .doc(userUID)
        .collection("chats")
        .doc(myUID)
        .collection("messages")
        .where("isRead", isEqualTo: false)
        .orderBy("sentAt", descending: true)
        .snapshots();
  }

  Future addUserInfoToDatabase(String userIdKey,
      Map<String, String> data) async {
    return FirebaseFirestore.instance
        .collection("users")
        .doc(userIdKey)
        .set(data);
  }

  Future updateSentMessage(String myUID, String userUID, String messageUID,
      DateTime current_time) async {
    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(myUID)
          .collection("chats")
          .doc(userUID)
          .collection("messages")
          .doc(messageUID)
          .set({
            "sentAt": DateTime.now(),
            "isRead": false,
          });
      await FirebaseFirestore.instance
          .collection("users")
          .doc(userUID)
          .collection("chats")
          .doc(myUID)
          .set({
        "lastModifiedAt": current_time,
      });
      return FirebaseFirestore.instance
          .collection("users")
          .doc(myUID)
          .collection("chats")
          .doc(userUID)
          .set({
        "lastModifiedAt": current_time,
      });
    } catch (e) {
      return null;
    }
  }

  Future updateChatMessageState(String myUID, String userUID, String messageUID) async {
    return FirebaseFirestore.instance
        .collection("users")
        .doc(userUID)
        .collection("chats")
        .doc(myUID)
        .collection("messages")
        .doc(messageUID)
        .update({
      "isRead": true,
    });
  }
}
