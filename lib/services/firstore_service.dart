import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final CollectionReference _userCollectionReference =
      FirebaseFirestore.instance.collection("users");
  final CollectionReference _chatsCollectionReference =
      FirebaseFirestore.instance.collection("chats");

  Future<DocumentSnapshot> getUserData(String userUID) {
    return _userCollectionReference.doc(userUID).get();
  }

  saveUserInfo(String userUID, Map<String, dynamic> data) async {
    await _userCollectionReference
        .doc(userUID)
        .set(data, SetOptions(merge: true));
  }

  Stream<QuerySnapshot> getUserChats(String userUID) {
    return _userCollectionReference
        .doc(userUID)
        .collection("chats")
        .orderBy("lastModifiedAt", descending: true)
        .snapshots();
  }

  Future<QuerySnapshot> getUserFromPhone(String phoneNumber) {
    return _userCollectionReference
        .where("phoneNumber", isEqualTo: phoneNumber)
        .get();
  }

  Stream<QuerySnapshot> fetchEndToEndShoutsFromDatabase(String chatUID) {
    // Get the shouts in the current chat
    return _chatsCollectionReference
        .doc(chatUID)
        .collection("messages")
        .where("isListened", isEqualTo: false)
        .orderBy("sendAt", descending: false)
        .snapshots();
  }

  Stream<DocumentSnapshot> getChatState(String chatUID) {
    // Get the current state of chat to see what the other
    // person is doing
    return _chatsCollectionReference.doc(chatUID).snapshots();
  }

  setRecordingStateToDatabase(String chatUID, bool state) {
    // if current user is recording, update the database regarding that
    _chatsCollectionReference
        .doc(chatUID)
        .set({"isRecording": state}, SetOptions(merge: true));
  }

  setListeningStateToDatabase(String chatUID, bool state) {
    // if current user is listening, update the database regarding that
    _chatsCollectionReference
        .doc(chatUID)
        .set({"isListening": state}, SetOptions(merge: true));
  }

  Future updateYourShoutState(String chatUID, String messageUID) async {
    // if a shout is listened, update it in the database.
    return _chatsCollectionReference
        .doc(chatUID)
        .collection("messages")
        .doc(messageUID)
        .update({
      "isListened": true,
      "listenedAt": DateTime.now(),
    });
  }

  Future updateChatState(String chatUID, Map<String, dynamic> data) {
    return _chatsCollectionReference
        .doc(chatUID)
        .set(data, SetOptions(merge: true));
  }

  Future<void> sendShout(String myUID, String yourUID, String chatForYou,
      String audioUID, DateTime currentTime) async {
    // update the shout in the database
    await _chatsCollectionReference
        .doc(chatForYou)
        .collection("messages")
        .doc(audioUID)
        .set({
      "isListened": false,
      "sendAt": currentTime,
      "listenedAt": null,
    });
    await _userCollectionReference
        .doc(yourUID)
        .collection("chats")
        .doc(myUID)
        .set({
      "lastModifiedAt": currentTime,
    });
    await _userCollectionReference
        .doc(myUID)
        .collection("chats")
        .doc(yourUID)
        .set({
      "lastModifiedAt": currentTime,
    });
  }
}
