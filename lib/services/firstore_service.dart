import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final CollectionReference _userCollectionReference =
      FirebaseFirestore.instance.collection("users");
  final CollectionReference _chatsCollectionReference =
      FirebaseFirestore.instance.collection("chats");

  Future<DocumentSnapshot> getUserData(String userUID) {
    return _userCollectionReference.doc(userUID).get();
  }

  Future<DocumentSnapshot> getChatStateData(String chatUID) {
    return _chatsCollectionReference.doc(chatUID).get();
  }

  Stream<DocumentSnapshot> getUserDataStream(String userUID) {
    return _userCollectionReference.doc(userUID).snapshots();
  }

  Future<void> saveUserInfo(String userUID, Map<String, dynamic> data) async {
    return _userCollectionReference
        .doc(userUID)
        .set(data, SetOptions(merge: true));
  }

  Stream<QuerySnapshot> getUserChats(String userUID) {
    return _chatsCollectionReference
        .where("sender", isEqualTo: userUID)
        .orderBy("lastModifiedAt", descending: true)
        .snapshots();
  }

  Future<QuerySnapshot> getUserFromPhone(List<String> phoneNumbers) {
    return _userCollectionReference
        .where("phoneNumber", whereIn: phoneNumbers)
        .get();
  }

  Stream<QuerySnapshot> fetchEndToEndShoutsFromDatabase(String chatUID) {
    // Get the shouts in the current chat
    return _chatsCollectionReference
        .doc(chatUID)
        .collection("messages")
        .where("isListened", isEqualTo: false)
        .orderBy("sentAt", descending: false)
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

  Future updateYourShoutState(
      String chatUID, String messageUID, Map<String, dynamic> data) async {
    // if a shout is listened, update it in the database.
    return _chatsCollectionReference
        .doc(chatUID)
        .collection("messages")
        .doc(messageUID)
        .set(data, SetOptions(merge: true));
  }

  Future updateChatState(String chatUID, Map<String, dynamic> data) {
    return _chatsCollectionReference
        .doc(chatUID)
        .set(data, SetOptions(merge: true));
  }

  Stream<QuerySnapshot> getStatuses(String userUID) {
    return _userCollectionReference
        .doc(userUID)
        .collection("statuses")
        .where("isDeleted", isEqualTo: false)
        .orderBy("lastModifiedAt", descending: true)
        .snapshots();
  }

  updateStatusState(
      String userUID, String statusUID, Map<String, dynamic> data) {
    _userCollectionReference
        .doc(userUID)
        .collection("statuses")
        .doc(statusUID)
        .set(data, SetOptions(merge: true));
  }
}
