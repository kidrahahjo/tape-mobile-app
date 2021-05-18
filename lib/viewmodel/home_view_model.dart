import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:wavemobileapp/permissions.dart';
import 'package:wavemobileapp/routing_constants.dart' as routes;
import 'package:wavemobileapp/locator.dart';
import 'package:wavemobileapp/services/authentication_service.dart';
import 'package:wavemobileapp/services/firstore_service.dart';
import 'package:wavemobileapp/services/navigation_service.dart';
import 'package:wavemobileapp/viewmodel/base_model.dart';
import 'package:flutter_cache/flutter_cache.dart' as cache;

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

  HomeViewModel(this.myUID, this.myPhoneNumber) {
    initialise();
  }

  initialise() async {
    print('start');
    await getCache();
    print('done');
    initialiseChatsStream();
    fetchAllContacts();
  }

  getCache() async {
    try {
      contactsMap =
          List<String>.from(await cache.load('contactsMap', contactsMap));
    } catch (e) {
      print(e);
      contactsMap = [];
    }
    try {
      userUIDDisplayNameMapping = Map<String, String>.from(
          await cache.load('userUIDDisplayNameMapping', <String, String>{}));
    } catch (e) {
      print(e);
      userUIDDisplayNameMapping = {};
    }
    try {
      userUIDNumberMapping = Map<String, String>.from(
          await cache.load('userUIDNumberMapping', userUIDNumberMapping));
    } catch (e) {
      print(e);
      userUIDNumberMapping = {};
    }
    try {
      userNumberContactNameMapping = Map<String, String>.from(await cache.load(
          'userNumberContactNameMapping', userNumberContactNameMapping));
    } catch (e) {
      print(e);
      userNumberContactNameMapping = {};
    }
  }

  initialiseChatsStream() async {
    chatsStream = _firestoreService.getUserChats(myUID);
    chatStreamSubscription = chatsStream.listen((event) async {
      // handle chat stream logic here
      if (event.docChanges.length != 0) {
        List<String> chatListChanged = [];
        for (QueryDocumentSnapshot element in event.docs) {
          String uid = element.id;
          chatListChanged.add(uid);
          await _firestoreService.getUserData(uid).then((value) {
            userUIDDisplayNameMapping[uid] = value.get('displayName');
            userUIDNumberMapping[uid] = value.get('phoneNumber');
          });
        }
        cache.remember('userUIDDisplayNameMapping', userUIDDisplayNameMapping);
        cache.remember('userUIDNumberMapping', userUIDNumberMapping);
        chatsList.clear();
        chatsList.addAll(chatListChanged);
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    chatStreamSubscription?.cancel();
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
    bool contactPermission = await getContactPermission();
    if (contactPermission) {
      if (contactsMap.length == 0) {
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
        cache.remember(
            'userNumberContactNameMapping', userNumberContactNameMapping);
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
        cache.remember('contactsMap', contactsMap);
        cache.remember('userUIDDisplayNameMapping', userUIDDisplayNameMapping);
        cache.remember('userUIDNumberMapping', userUIDNumberMapping);

        isFetchingContacts = false;
      }
      notifyListeners();
    }
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
      cache.destroy('contactsMap');
      fetchAllContacts();
    }
  }

  void goToContactScreen(String uid) async {
    bool microphonePermission = await getMicrophonePermission();
    bool storagePermission = await getStoragePermission();
    if (microphonePermission && storagePermission) {
      _navigationService.navigateTo(routes.ChatViewRoute,
          arguments: {'yourUID': uid, 'yourName': getUserName(uid)});
    }
  }

  String getPhoneNumber(String uid) {
    return userUIDNumberMapping[uid];
  }
}
