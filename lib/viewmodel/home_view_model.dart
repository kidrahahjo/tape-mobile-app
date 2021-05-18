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

class HomeViewModel extends BaseModel {
  final String myUID;
  final String myPhoneNumber;
  final FirestoreService _firestoreService = locator<FirestoreService>();
  final AuthenticationService _authenticationService =
      locator<AuthenticationService>();
  final NavigationService _navigationService = locator<NavigationService>();

  // chat related variables
  List<Map<String, dynamic>> chatsList = [];
  Stream<QuerySnapshot> chatsStream;
  StreamSubscription<QuerySnapshot> chatStreamSubscription;
  Map<String, String> userUIDNameMapping = {};

  // contact related variables
  List<Map<String, dynamic>> contactsMap = [];
  bool isFetchingContacts = true;
  Map<String, String> userNumberContactNameMapping = {};

  HomeViewModel(this.myUID, this.myPhoneNumber) {
    initialiseChatsStream();
    fetchAllContacts();
  }

  initialiseChatsStream() async {
    chatsStream = _firestoreService.getUserChats(myUID);
    chatStreamSubscription = chatsStream.listen((event) async {
      // handle chat stream logic here
      if (event.docChanges.length != 0) {
        List<Map<String, String>> chatListChanged = [];
        for (QueryDocumentSnapshot element in event.docs) {
          String uid = element.id;
          String userName = userUIDNameMapping.containsKey(uid)
              ? userUIDNameMapping[uid]
              : await _firestoreService.getUserData(uid).then((value) {
                  String name = value.get('displayName');
                  userUIDNameMapping[uid] = name;
                  return name;
                });
          chatListChanged.add({
            'yourUID': uid,
            'yourName': userName,
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
      List<Map<String, dynamic>> contactsData = [];
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
            contactsData.add({
              'yourUID': userUID,
              'yourName': displayName,
              'yourPhoneNumber': phone,
            });
            userUIDNameMapping[userUID] = displayName;
          });
        });
      }

      contactsMap.clear();
      contactsMap.addAll(contactsData);
      isFetchingContacts = false;
      notifyListeners();
    }
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

  void goToContactScreen(String uid) async {
    bool microphonePermission = await getMicrophonePermission();
    bool storagePermission = await getStoragePermission();
    if (microphonePermission && storagePermission) {
      _navigationService.navigateTo(routes.ChatViewRoute,
          arguments: {'yourUID': uid, 'yourName': userUIDNameMapping[uid]});
    }
  }
}
