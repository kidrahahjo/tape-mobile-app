import 'dart:async';
import 'dart:collection';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:uuid/uuid.dart';
import 'package:wavemobileapp/permissions.dart';
import 'package:wavemobileapp/routing_constants.dart' as routes;
import 'package:wavemobileapp/locator.dart';
import 'package:wavemobileapp/services/authentication_service.dart';
import 'package:wavemobileapp/services/firstore_service.dart';
import 'package:wavemobileapp/services/navigation_service.dart';
import 'package:wavemobileapp/viewmodel/base_model.dart';

class HomeViewModel extends BaseModel {
  final String myUID;
  final String myPhoneNumber;
  final FirestoreService _firestoreService = locator<FirestoreService>();
  final AuthenticationService _authenticationService =
      locator<AuthenticationService>();
  final NavigationService _navigationService = locator<NavigationService>();

  // chat related variables
  List<String> chatsList = [];
  Stream<QuerySnapshot> chatsStream;
  StreamSubscription<QuerySnapshot> chatStreamSubscription;
  Map<String, String> userUIDDisplayNameMapping = {};
  Map<String, String> userUIDNumberMapping = {};

  // contact related variables
  List<String> contactsMap = [];
  bool isFetchingContacts = false;
  Map<String, String> userNumberContactNameMapping = {};

  // status related variables
  String currentStatus;
  Queue<String> allStatuses = new Queue();
  Queue<String> allStatusesMessages = new Queue();
  Map<String, String> statusesUIDStatusTextMap = {};
  Stream<QuerySnapshot> myStatusStream;
  StreamSubscription<QuerySnapshot> myStatusStreamSubscription;
  bool updateStatus = false;
  String textToShow;
  final TextEditingController statusTextController =
      new TextEditingController();

  HomeViewModel(this.myUID, this.myPhoneNumber) {
    initialise();
    statusTextController.addListener(() {
      textToShow = statusTextController.text.trim();
      notifyListeners();
    });
  }

  String get status {
    return textToShow != null
        ? textToShow
        : currentStatus == null
            ? "What's happening?"
            : statusesUIDStatusTextMap[currentStatus];
  }

  initialise() async {
    initialiseStatusStream();
    initialiseChatsStream();
    fetchAllContacts();
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
      if (event.docChanges.length != 0) {
        List<String> chatListChanged = [];
        for (QueryDocumentSnapshot element in event.docs) {
          Map<String, dynamic> data = element.data();
          String uid = data['receiver'];
          chatListChanged.add(uid);
          await _firestoreService.getUserData(uid).then((value) {
            userUIDDisplayNameMapping[uid] = value.get('displayName');
            userUIDNumberMapping[uid] = value.get('phoneNumber');
          });
        }
        chatsList.clear();
        chatsList.addAll(chatListChanged);
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    chatStreamSubscription?.cancel();
    myStatusStreamSubscription?.cancel();
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
    bool contactPermission = await getContactPermission();
    if (contactPermission) {
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
            Map<String, dynamic> metadata = element.data();
            String phone = metadata['phoneNumber'];
            String displayName = metadata['displayName'];
            contactsData.add(userUID);
            userUIDDisplayNameMapping[userUID] = displayName;
            userUIDNumberMapping[userUID] = phone;
          });
        });
      }
      contactsMap.clear();
      contactsMap.addAll(contactsData);
      notifyListeners();
    }
    isFetchingContacts = false;
  }

  String getUserName(String uid) {
    String number = userUIDNumberMapping[uid];
    String contactName = userNumberContactNameMapping[number];
    if (contactName != null) {
      return contactName;
    } else {
      return number;
    }
  }

  String getUserStatus(String uid) {
    return 'Vibing';
  }

  void signOut() async {
    bool signedOut = await _authenticationService.signOutUser();
    if (signedOut) {
      _navigationService.navigateReplacementTo(routes.StartupViewRoute);
    }
  }

  void refreshContacts() {
    if (!this.isFetchingContacts) {
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
}
