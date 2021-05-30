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

  Stream<QuerySnapshot> fetchReceivedTapesFromDatabase(String chatUID) {
    // Get the shouts in the current chat
    return _chatsCollectionReference
        .doc(chatUID)
        .collection("messages")
        .where("isListened", isEqualTo: false)
        .orderBy("sentAt", descending: false)
        .snapshots();
  }

  Stream<QuerySnapshot> fetchPokesForMe(String chatUID) {
    return _chatsCollectionReference
        .doc(chatUID)
        .collection("waves")
        .where("isExpired", isEqualTo: false)
        .orderBy("sentAt", descending: true)
        .snapshots();
  }

  expirePoke(String waveID, String chatUID) {
    _chatsCollectionReference
        .doc(chatUID)
        .collection("messages")
        .doc(waveID)
        .set({"isExpired": true}, SetOptions(merge: true));
  }

  Future<QuerySnapshot> getChatsForMe(String chatUID) {
    return _chatsCollectionReference
        .doc(chatUID)
        .collection("messages")
        .where("isListened", isEqualTo: false)
        .orderBy("sentAt", descending: false)
        .get();
  }

  Stream<QuerySnapshot> fetchSentTapesFromDatabase(String chatUID,
      {bool descending = false}) {
    return _chatsCollectionReference
        .doc(chatUID)
        .collection("messages")
        .where("isExpired", isEqualTo: false)
        .orderBy("sentAt", descending: descending)
        .snapshots();
  }

  Future<QuerySnapshot> getChatsForYou(String chatUID) {
    return _chatsCollectionReference
        .doc(chatUID)
        .collection("messages")
        .where("isExpired", isEqualTo: false)
        .orderBy("sentAt", descending: false)
        .get();
  }

  Stream<QuerySnapshot> getLastTapeStateStream(String chatUID) {
    return _chatsCollectionReference
        .doc(chatUID)
        .collection("messages")
        .orderBy("sentAt", descending: true)
        .limit(1)
        .snapshots();
  }

  Future<QuerySnapshot> getLastTapeListenedDoc(String chatUID) {
    return _chatsCollectionReference
        .doc(chatUID)
        .collection("messages")
        .orderBy("sentAt", descending: true)
        .limit(1)
        .get();
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

  sendPoke(String chatUID, Map<String, dynamic> data) {
    _chatsCollectionReference.doc(chatUID).collection("waves").add(data);
  }
}
