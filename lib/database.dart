import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class DatabaseMethods {
  Future<Stream<QuerySnapshot>> fetchEndToEndShoutsFromDatabase(
      String chat_uid) async {
    return FirebaseFirestore.instance
        .collection("chats")
        .doc(chat_uid)
        .collection("messages")
        .where("isListened", isEqualTo: false)
        .orderBy("sendAt", descending: false)
        .snapshots();
  }

  Future sendShout(
      String myUID, String yourUID, String chatForYou, String audio_uid, DateTime currentTime) async {
    await FirebaseFirestore.instance
        .collection("chats")
        .doc(chatForYou)
        .collection("messages")
        .doc(audio_uid)
        .set({
      "isListened": false,
      "sendAt": currentTime,
      "listenedAt": null,
    });
    await FirebaseFirestore.instance
        .collection("users")
        .doc(yourUID)
        .collection("chats")
        .doc(myUID)
        .set({
      "lastModifiedAt": currentTime,
    });
    await FirebaseFirestore.instance
        .collection("users")
        .doc(myUID)
        .collection("chats")
        .doc(yourUID)
        .set({
      "lastModifiedAt": currentTime,
    });
  }

  Future updateShoutState(
      String chatUID, String messageUID) async {
    return FirebaseFirestore.instance
        .collection("chats")
        .doc(chatUID)
        .collection("messages")
        .doc(messageUID)
        .update({
      "isListened": true,
      "listenedAt": DateTime.now(),
    });
  }

  Future<Stream<QuerySnapshot>> fetchTotalChats(String myUID) async {
    return FirebaseFirestore.instance
        .collection("users")
        .doc(myUID)
        .collection("chats")
        .orderBy("lastModifiedAt", descending: true)
        .snapshots();
  }

  Future addUserInfoToDatabase(
      String userIdKey, Map<String, String> data) async {
    return FirebaseFirestore.instance
        .collection("users")
        .doc(userIdKey)
        .set(data);
  }

  Future updateSentMessage(String myUID, String userUID, String messageUID,
      String myName, String user_name, DateTime current_time) async {
    try {
      print(myName);
      print(user_name);
      await FirebaseFirestore.instance
          .collection("users")
          .doc(myUID)
          .collection("chats")
          .doc(userUID)
          .collection("messages")
          .doc(messageUID)
          .set({
        "sentAt": current_time,
        "isRead": false,
      });
      await FirebaseFirestore.instance
          .collection("users")
          .doc(userUID)
          .collection("chats")
          .doc(myUID)
          .set({
        "userName": myName,
        "lastModifiedAt": current_time,
      });
      return FirebaseFirestore.instance
          .collection("users")
          .doc(myUID)
          .collection("chats")
          .doc(userUID)
          .set({
        "userName": user_name,
        "lastModifiedAt": current_time,
      });
    } catch (e) {
      return null;
    }
  }

  Future<Stream<DocumentSnapshot>> getUserName(String user_uid) async {
    return FirebaseFirestore.instance
        .collection("users")
        .doc(user_uid)
        .snapshots();
  }

  Future<DocumentSnapshot> fetchUserDetailFromDatabase(String user_uid) {
    return FirebaseFirestore.instance.doc("users/$user_uid").get();
  }
}
