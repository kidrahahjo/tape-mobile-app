import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class DatabaseMethods {
  Stream<DocumentSnapshot> getUserNameFromDatabase(String userUID) {
    // remove this method
    return FirebaseFirestore.instance
        .collection("users")
        .doc(userUID)
        .snapshots();
  }

  Stream<QuerySnapshot> getTotalChats(String myUID) {
    // fetch all the chats by the current user show it according to chronology
    return FirebaseFirestore.instance
        .collection("users")
        .doc(myUID)
        .collection("chats")
        .orderBy("lastModifiedAt", descending: true)
        .snapshots();
  }

  Future<DocumentSnapshot> fetchUserDetailFromDatabase(String user_uid) {
    // get users from the database
    return FirebaseFirestore.instance.doc("users/$user_uid").get();
  }

  setRecordingStateToDatabase(String chatUID, bool state) {
    // if current user is recording, update the database regarding that
    FirebaseFirestore.instance.collection("chats").doc(chatUID).set(
        {"isRecording": state, "isListening": false}, SetOptions(merge: true));
  }

  setListeningStateToDatabase(String chatUID, bool state) {
    // if current user is listening, update the database regarding that
    FirebaseFirestore.instance.collection("chats").doc(chatUID).set(
        {"isListening": state, "isRecording": false}, SetOptions(merge: true));
  }

  Stream<DocumentSnapshot> getChatState(String chatUID) {
    // Get the current state of chat to see what the other
    // person is doing
    return FirebaseFirestore.instance
        .collection("chats")
        .doc(chatUID)
        .snapshots();
  }

  Stream<QuerySnapshot> fetchEndToEndShoutsFromDatabase(String chatUID) {
    // Get the messages in the current chat
    return FirebaseFirestore.instance
        .collection("chats")
        .doc(chatUID)
        .collection("messages")
        .where("isListened", isEqualTo: false)
        .orderBy("sendAt", descending: false)
        .snapshots();
  }

  Future sendShout(String myUID, String yourUID, String chatForYou,
      String audio_uid, DateTime currentTime) async {
    // update the shout in the database
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
    // if a shout is listened, update it in the database.
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

  updateChatState(String chatUID, Map<String, dynamic> data) {
    FirebaseFirestore.instance
        .collection("chats")
        .doc(chatUID)
        .set(data, SetOptions(merge: true));
  }

  Future addUserInfoToDatabase(
      String userIdKey, Map<String, String> data) async {
    return FirebaseFirestore.instance
        .collection("users")
        .doc(userIdKey)
        .set(data);
  }
}
