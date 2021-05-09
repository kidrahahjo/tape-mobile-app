import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class DatabaseMethods {
  Stream<DocumentSnapshot> getUserNameFromDatabase(String userUID) {
    return FirebaseFirestore.instance
        .collection("users")
        .doc(userUID)
        .snapshots();
  }

  Future<DocumentSnapshot> fetchUserDetailFromDatabase(String user_uid) {
    return FirebaseFirestore.instance.doc("users/$user_uid").get();
  }

  setRecordingStateToDatabase(String chat_uid, bool state) {
    FirebaseFirestore.instance
        .collection("chats")
        .doc(chat_uid)
        .set({"isRecording": state}, SetOptions(merge: true));
  }

  setListeningStateToDatabase(String chat_uid, bool state) {
    FirebaseFirestore.instance
        .collection("chats")
        .doc(chat_uid)
        .set({"isListening": state}, SetOptions(merge: true));
  }

  Stream<DocumentSnapshot> getChatState(String chat_uid) {
    return FirebaseFirestore.instance
        .collection("chats")
        .doc(chat_uid)
        .snapshots();
  }

  Stream<QuerySnapshot> fetchEndToEndShoutsFromDatabase(String chat_uid) {
    return FirebaseFirestore.instance
        .collection("chats")
        .doc(chat_uid)
        .collection("messages")
        .where("isListened", isEqualTo: false)
        .orderBy("sendAt", descending: false)
        .snapshots();
  }

  Future sendShout(String myUID, String yourUID, String chatForYou,
      String audio_uid, DateTime currentTime) async {
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

  Future updateShoutState(String chatUID, String messageUID) async {
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
}
