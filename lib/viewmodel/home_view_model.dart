import 'dart:async';
import 'dart:collection';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:tapemobileapp/services/push_notification_service.dart';
import 'package:uuid/uuid.dart';
import 'package:tapemobileapp/permissions.dart';
import 'package:tapemobileapp/routing_constants.dart' as routes;
import 'package:tapemobileapp/locator.dart';
import 'package:tapemobileapp/services/authentication_service.dart';
import 'package:tapemobileapp/services/firstore_service.dart';
import 'package:tapemobileapp/services/navigation_service.dart';
import 'package:tapemobileapp/viewmodel/base_model.dart';
import 'package:flutter_cache/flutter_cache.dart' as cache;

class HomeViewModel extends BaseModel {
  final String myUID;
  final String myPhoneNumber;
  final FirestoreService _firestoreService = locator<FirestoreService>();
  final AuthenticationService _authenticationService =
      locator<AuthenticationService>();
  final NavigationService _navigationService = locator<NavigationService>();
  final PushNotification _pushNotification = locator<PushNotification>();

  // chat related variables
  List<String> chatsList = [];
  List<String> userUIDs = [];
  List<Stream<DocumentSnapshot>> usersChatStateStream = [];
  List<StreamSubscription<DocumentSnapshot>> usersChatStateStreamSubscription =
      [];
  List<Stream<DocumentSnapshot>> usersDocuments = [];
  List<StreamSubscription<DocumentSnapshot>> usersDocumentsSubscriptions = [];
  Map<String, String> userUIDDYourChatStateMapping = {};
  Map<String, String> userUIDDMyChatStateMapping = {};

  Stream<QuerySnapshot> chatsStream;
  StreamSubscription<QuerySnapshot> chatStreamSubscription;
  Map<String, String> userUIDDisplayNameMapping = {};
  Map<String, String> userUIDNumberMapping = {};
  Map<String, String> userUIDStatusMapping = {};
  Map<String, bool> userUIDRecordingState = {};

  // contact related variables
  List<String> contactsMap = [];
  bool isFetchingContacts = false;
  Map<String, String> userNumberContactNameMapping = {};
  Map<String, String> userUIDContactNameMapping = {};
  // status related variables
  String currentStatus;
  Queue<String> allStatuses = new Queue();
  Queue<String> allStatusesMessages = new Queue();
  Map<String, String> statusesUIDStatusTextMap = {};
  Stream<QuerySnapshot> myStatusStream;
  StreamSubscription<QuerySnapshot> myStatusStreamSubscription;
  bool updateStatus = false;
  String textToShow;
  bool onHome = true;

  final TextEditingController statusTextController =
      new TextEditingController();

  HomeViewModel(this.myUID, this.myPhoneNumber) {
    initialise();
    statusTextController.addListener(() {
      textToShow = statusTextController.text.trim();
      if (onHome) {
        textToShow = null;
      }
      notifyListeners();
    });
  }

  String realStatus() {
    return currentStatus == null
        ? "What's happening?"
        : statusesUIDStatusTextMap[currentStatus];
  }

  String get status {
    return textToShow != null
        ? textToShow.length == 0
            ? "What's happening?"
            : textToShow
        : realStatus();
  }

  bool isRecording(String userUID) {
    return userUIDRecordingState[userUID] == null
        ? false
        : userUIDRecordingState[userUID];
  }

  initialise() {
    _pushNotification.initialise(this.myUID);
    initialise_cache();
    initialiseStatusStream();
    initialiseChatsStream();
  }

  initialise_cache() async {
    try {
      userUIDContactNameMapping = await cache.load('userUIDContactNameMapping');
      print(userUIDContactNameMapping);
      if (userUIDContactNameMapping == null) {
        userUIDContactNameMapping = {};
      }
    } catch(e) {
      userUIDContactNameMapping = {};
    }
  }

  initialiseStatusStream() async {
    myStatusStream = _firestoreService.getStatuses(myUID);
    myStatusStreamSubscription = myStatusStream.listen((event) {
      allStatuses.clear();
      allStatusesMessages.clear();
      int i = 0;
      if (event.docs.length == 0) {
        currentStatus = null;
        allStatuses.clear();
        allStatusesMessages.clear();
        notifyListeners();
      }
      event.docs.forEach((element) {
        Map<String, dynamic> data = element.data();
        statusesUIDStatusTextMap[element.id] = data['message'];
        allStatuses.add(element.id);
        allStatusesMessages.add(data['message']);
        if (i == 0) {
          currentStatus = element.id;
        }
        i += 1;
        notifyListeners();
      });
    });
  }

  deleteStatus(String statusUID) {
    _firestoreService.updateStatusState(myUID, statusUID,
        {"isDeleted": true, "lastModifiedAt": DateTime.now()});
    if (currentStatus == statusUID) {
      _firestoreService.saveUserInfo(myUID, {"currentStatus": null});
      updateStatus = false;
      statusTextController.text = "";
    }
  }

  resetTempVars() {
    onHome = true;
    textToShow = null;
    notifyListeners();
  }

  addNewStatus() {
    String message = statusTextController.text.trim();
    if (allStatusesMessages.contains(message)) {
      int index = allStatusesMessages.toList().indexOf(message);
      String uid = allStatuses.elementAt(index);
      setStatusWithUID(uid);
    } else if (message == null || message.length == 0) {
      // do nothing
    } else {
      String statusUID = Uuid().v4().replaceAll("-", "");
      statusesUIDStatusTextMap[statusUID] = message;
      _firestoreService.updateStatusState(myUID, statusUID, {
        "message": message,
        "isDeleted": false,
        "lastModifiedAt": DateTime.now()
      });
      _firestoreService.saveUserInfo(myUID, {"currentStatus": message});
    }
  }

  setStatusWithUID(String statusUID) {
    updateStatus = false;
    statusTextController.text = statusesUIDStatusTextMap[statusUID];
    if (currentStatus != statusUID) {
      _firestoreService.updateStatusState(myUID, statusUID,
          {"isDeleted": false, "lastModifiedAt": DateTime.now()});
      _firestoreService.saveUserInfo(
          myUID, {"currentStatus": statusesUIDStatusTextMap[statusUID]});
    }
    // update this status
  }

  initialiseChatsStream() async {
    chatsStream = _firestoreService.getUserChats(myUID);
    chatStreamSubscription = chatsStream.listen((event) async {
      // handle chat stream logic here
      if (event.docs.length != 0) {
        List<String> chatListChanged = [];
        for (QueryDocumentSnapshot element in event.docs) {
          Map<String, dynamic> data = element.data();
          String uid = data['receiver'];
          chatListChanged.add(uid);
          if (!userUIDs.contains(uid)) {
            userUIDs.add(uid);
            userDocumentStream(uid);
            userChatStateStream(uid);
          }
          userUIDDMyChatStateMapping[uid] = data['chatState'];
          await _firestoreService.getUserData(uid).then((value) {});
        }
        chatsList.clear();
        chatsList.addAll(chatListChanged);
        notifyListeners();
      }
    });
  }

  userDocumentStream(String uid) {
    Stream<DocumentSnapshot> userStream =
        _firestoreService.getUserDataStream(uid);
    usersDocuments.add(userStream);
    usersDocumentsSubscriptions.add(userStream.listen((event) {
      if (event.exists) {
        Map<String, dynamic> data = event.data();
        userUIDDisplayNameMapping[uid] = data['displayName'];
        userUIDNumberMapping[uid] = data['phoneNumber'];
        userUIDStatusMapping[uid] = data['currentStatus'];
        notifyListeners();
      }
    }));
  }

  userChatStateStream(String uid) {
    Stream<DocumentSnapshot> chatState =
        _firestoreService.getChatState(uid + '_' + myUID);
    usersDocuments.add(chatState);
    usersDocumentsSubscriptions.add(chatState.listen((event) {
      if (event.exists) {
        Map<String, dynamic> data = event.data();
        userUIDDYourChatStateMapping[data['sender']] = data['chatState'];
        userUIDRecordingState[data['sender']] = data['isRecording'];
        notifyListeners();
      }
    }));
  }

  @override
  void dispose() {
    chatStreamSubscription?.cancel();
    myStatusStreamSubscription?.cancel();
    for (var stream in usersDocumentsSubscriptions) {
      stream?.cancel;
    }
    for (var stream in usersChatStateStreamSubscription) {
      stream?.cancel;
    }
    super.dispose();
  }

  String refactorPhoneNumber(String phone) {
    phone = phone.replaceAll(" ", "");
    if (phone.startsWith('+91')) {
      // indian phone number
      return phone;
    } else if (phone.startsWith('+')) {
      // non-indian phone number
      return null;
    } else {
      try {
        String num = '+91' + int.parse(phone).toString();
        if (num.length == 13) {
          // indian phone number
          return num;
        } else {
          // non-indian phone number
          return null;
        }
      } catch (e) {
        // non-indian phone number
        return null;
      }
    }
  }

  fetchAllContacts() async {
    isFetchingContacts = true;
    notifyListeners();
    final Iterable<Contact> contacts = await ContactsService.getContacts();
    for (Contact contact in contacts) {
      for (Item phone in contact.phones) {
        String number = refactorPhoneNumber(phone.value.toString());
        if (number != null) {
          userNumberContactNameMapping[number] = contact.displayName;
        }
      }
    }
    List<String> contactsData = [];
    List<String> userContactsList =
        userNumberContactNameMapping.keys.toList(growable: false);
    for (int i = 0; i < userContactsList.length; i += 10) {
      List<String> phoneNumbers = userContactsList.sublist(
          i,
          i + 10 <= userContactsList.length
              ? i + 10
              : userContactsList.length);
      await _firestoreService
          .getUserFromPhone(phoneNumbers)
          .then((querySnapshot) {
        querySnapshot.docs.forEach((element) {
          String userUID = element.id;
          if (!userUIDs.contains(userUID)) {
            userDocumentStream(element.id);
          }
          Map<String, dynamic> data = element.data();
          contactsData.add(userUID);
          userUIDContactNameMapping[userUID] = userNumberContactNameMapping[data['phoneNumber']];
        });
      });
    }
    await cache.destroy('userUIDContactNameMapping');
    await cache.remember('userUIDContactNameMapping', userUIDContactNameMapping);
    contactsMap.clear();
    contactsMap.addAll(contactsData);
    notifyListeners();
    isFetchingContacts = false;
  }

  String getUserName(String uid) {
    String number = userUIDNumberMapping[uid];
    String contactName = userUIDContactNameMapping[uid];
    if (contactName != null) {
      return contactName;
    } else if (number != null) {
      return number;
    } else {
      return "";
    }
  }

  String getUserStatus(String uid) {
    return userUIDStatusMapping[uid] == null ? "" : userUIDStatusMapping[uid];
  }

  String getStatusFromUID(String statusUID) {
    return statusesUIDStatusTextMap[statusUID] == null
        ? ""
        : statusesUIDStatusTextMap[statusUID];
  }

  void signOut() async {
    bool signedOut = await _authenticationService.signOutUser();
    if (signedOut) {
      _navigationService.navigateReplacementTo(routes.StartupViewRoute);
    }
  }

  void refreshContacts() async {
    bool contactPermission = false;
    try {
      contactPermission = await getContactPermission();
    } catch (err) {
      contactPermission = false;
    }
    if (!this.isFetchingContacts && contactPermission) {
      fetchAllContacts();
    }
  }

  void goToContactScreen(String uid, {bool fromContacts: false}) async {
    bool microphonePermission = await getMicrophonePermission();
    bool storagePermission = await getStoragePermission();
    if (microphonePermission && storagePermission) {
      if (fromContacts) {
        _navigationService.goBack();
      }
      _navigationService.navigateTo(routes.ChatViewRoute,
          arguments: {'yourUID': uid, 'yourName': getUserName(uid)});
    }
  }

  String getPhoneNumber(String uid) {
    return userUIDNumberMapping[uid];
  }

  popIt() {
    _navigationService.goBack();
  }

  void submit() {
    if (textToShow == null ||
        textToShow == userUIDStatusMapping[currentStatus]) {
      updateStatus = false;
    } else {
      updateStatus = true;
    }
    _navigationService.goBack();
  }

  Icon showChatState(String yourUID) {
    String myState = userUIDDMyChatStateMapping[yourUID];
    String yourState = userUIDDYourChatStateMapping[yourUID];
    if (myState == 'Received') {
      return Icon(
        PhosphorIcons.playFill,
        color: Colors.orange,
      );
    } else if ((myState == null || myState == 'Played') && yourState == null) {
      return null;
    } else if (yourState == 'Received') {
      return Icon(PhosphorIcons.paperPlane);
    } else if (yourState == 'Played') {
      return Icon(PhosphorIcons.speakerSimpleHigh);
    }
    return null;
  }
}
