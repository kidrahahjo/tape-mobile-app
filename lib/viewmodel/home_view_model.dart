import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:tapemobileapp/services/push_notification_service.dart';
import 'package:tapemobileapp/app/permissions.dart';
import 'package:tapemobileapp/app/routing_constants.dart' as routes;
import 'package:tapemobileapp/app/locator.dart';
import 'package:tapemobileapp/services/authentication_service.dart';
import 'package:tapemobileapp/services/firestore_service.dart';
import 'package:tapemobileapp/services/navigation_service.dart';
import 'package:tapemobileapp/viewmodel/base_model.dart';
import 'package:flutter_cache/flutter_cache.dart' as cache;
import 'package:tapemobileapp/utils/time_utils.dart';

class HomeViewModel extends BaseModel with WidgetsBindingObserver {
  // variables related to me
  final String myUID;
  final String myPhoneNumber;
  String myDisplayName;
  String myProfilePic;

  // streams related to me
  Stream<DocumentSnapshot> myDocumentStream;
  StreamSubscription<DocumentSnapshot> myDocumentStreamSubscription;

  // services
  final FirestoreService _firestoreService = locator<FirestoreService>();
  final AuthenticationService _authenticationService =
      locator<AuthenticationService>();
  final NavigationService _navigationService = locator<NavigationService>();
  final PushNotification _pushNotification = locator<PushNotification>();

  // variables related to users
  Map<String, String> userUIDDisplayNameMapping = {};
  Map<String, String> userUIDNumberMapping = {};
  Map<String, bool> userUIDOnlineMapping = {};
  Map<String, String> userUIDProfilePicMapping = {};

  // streams related to users
  List<Stream<DocumentSnapshot>> usersDocuments = [];
  List<StreamSubscription<DocumentSnapshot>> usersDocumentsSubscriptions = [];

  // variables related to chat
  List<String> chatsList = [];
  List<String> userUIDs = [];
  Map<String, String> userUIDDYourChatStateMapping = {};
  Map<String, bool> userUIDWaveMapping = {};
  Map<String, String> userUIDDMyChatStateMapping = {};
  Map<String, bool> userUIDRecordingState = {};
  Map<String, String> userUIDMoodState = {};
  Map<String, int> userUIDReceivedTapesMapping = {};
  Map<String, DateTime> userUIDReceivedTapesTimeMapping = {};
  Map<String, String> userUIDLastSentTapeStateMapping = {};
  Map<String, DateTime> userUIDLastSentTapeTimeMapping = {};

  // streams related to chat
  Stream<QuerySnapshot> chatsStream;
  StreamSubscription<QuerySnapshot> chatStreamSubscription;
  List<Stream<QuerySnapshot>> usersChatForMeStreams = [];
  List<StreamSubscription<QuerySnapshot>> usersChatForMeStreamSubscriptions =
      [];
  List<Stream<QuerySnapshot>> usersChatForYouStreams = [];
  List<StreamSubscription<QuerySnapshot>> usersChatForYouStreamSubscriptions =
      [];
  List<Stream<QuerySnapshot>> usersPokeStreams = [];
  List<StreamSubscription<QuerySnapshot>> usersPokeStreamsSubscriptions = [];

//variables related to home navigation

  int activePage = 0;
  final pageController = PageController(initialPage: 1);

  // variables related to contacts
  List<String> contactsMap = [];
  bool isFetchingContacts = false;
  Map<String, String> userNumberContactNameMapping = {};
  Map<String, String> userUIDContactNameMapping = {};

  HomeViewModel(this.myUID, this.myPhoneNumber) {
    WidgetsBinding.instance.addObserver(this);
    _firestoreService.saveUserInfo(myUID, {"isOnline": true});
    initialise();
  }

  bool isRecording(String userUID) {
    return userUIDRecordingState[userUID] == null
        ? false
        : userUIDRecordingState[userUID];
  }

  void initialise() async {
    notifyListeners();
    _pushNotification.initialise(this.myUID);
    await initialiseCache();
    initialiseMyDocumentStream();
    initialiseChatsStream();

    bool contactPermission = false;
    try {
      contactPermission = await getContactPermission();
    } catch (err) {
      contactPermission = false;
    }
    if (contactPermission) {
      fetchAllContacts();
    }
  }

  initialiseCache() async {
    try {
      myProfilePic = await cache.load('myProfilePic');
    } catch (e) {
      myProfilePic = null;
    }
    try {
      myDisplayName = await cache.load('myDisplayName');
    } catch (e) {
      myDisplayName = null;
    }
    try {
      contactsMap = List<String>.from(await cache.load('contactsMap'));
      if (chatsList == null) {
        contactsMap = <String>[];
      } else {
        notifyListeners();
      }
    } catch (e) {
      contactsMap = <String>[];
    }
    try {
      userUIDContactNameMapping = Map<String, String>.from(
          await cache.load('userUIDContactNameMapping'));
      if (userUIDContactNameMapping == null) {
        userUIDContactNameMapping = {};
      } else {
        notifyListeners();
      }
    } catch (e) {
      userUIDContactNameMapping = {};
    }
    try {
      userUIDNumberMapping =
          Map<String, String>.from(await cache.load('userUIDNumberMapping'));
      if (userUIDNumberMapping == null) {
        userUIDNumberMapping = {};
      } else {
        notifyListeners();
      }
    } catch (e) {
      userUIDNumberMapping = {};
    }
    try {
      userNumberContactNameMapping = Map<String, String>.from(
          await cache.load('userNumberContactNameMapping'));
      if (userNumberContactNameMapping == null) {
        userNumberContactNameMapping = {};
      } else {
        notifyListeners();
      }
    } catch (e) {
      userNumberContactNameMapping = {};
    }
  }

  initialiseMyDocumentStream() {
    myDocumentStream = _firestoreService.getUserDataStream(myUID);
    myDocumentStreamSubscription = myDocumentStream.listen((event) {
      if (event.exists) {
        Map<String, dynamic> data = event.data();
        myProfilePic = data['displayImageURL'];
        myDisplayName = data['displayName'];
        if (myProfilePic != null) {
          cache.write('myProfilePic', myProfilePic);
        }
        if (myDisplayName != null) {
          cache.write('myDisplayName', myDisplayName);
        }
        notifyListeners();
      }
    });
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
            initialiseUsersChatForMeStream(uid);
            initialiseUsersChatForYouStream(uid);
          }
          await _firestoreService.getUserData(uid).then((value) {});
        }
        chatsList.clear();
        chatsList.addAll(chatListChanged);
        notifyListeners();
      }
    });
  }

  initialiseUsersChatForMeStream(String uid) {
    Stream<QuerySnapshot> chatForMeStream =
        _firestoreService.fetchReceivedTapesFromDatabase(uid + "_" + myUID);
    usersChatForMeStreams.add(chatForMeStream);
    usersChatForMeStreamSubscriptions.add(chatForMeStream.listen((event) async {
      userUIDReceivedTapesMapping[uid] = event.docs.length;
      await _firestoreService
          .getLastTapeListenedDoc(uid + "_" + myUID)
          .then((value) {
        if (value.docs.length == 0) {
          userUIDReceivedTapesTimeMapping[uid] = null;
        } else {
          Map<String, dynamic> data = value.docs.first.data();
          if (data['isListened']) {
            userUIDReceivedTapesTimeMapping[uid] =
                convertTimestampToDateTime(data['listenedAt']);
          } else {
            userUIDReceivedTapesTimeMapping[uid] =
                convertTimestampToDateTime(data['sentAt']);
          }
        }
      });
    }));

    Stream<QuerySnapshot> usersPokeStream =
        _firestoreService.fetchPokesForMe(uid + "_" + myUID);
    usersPokeStreams.add(usersPokeStream);
    usersPokeStreamsSubscriptions.add(usersPokeStream.listen((event) async {
      if (event.docs.length > 0) {
        userUIDWaveMapping[uid] = true;
      } else {
        userUIDWaveMapping[uid] = false;
      }
      notifyListeners();
    }));
  }

  initialiseUsersChatForYouStream(String uid) {
    Stream<QuerySnapshot> chatForYouStream =
        _firestoreService.getLastTapeStateStream(myUID + "_" + uid);
    usersChatForYouStreams.add(chatForYouStream);
    usersChatForYouStreamSubscriptions.add(chatForYouStream.listen((event) {
      if (event.docs.length == 0) {
        userUIDLastSentTapeStateMapping[uid] = "Empty";
      } else {
        Map<String, dynamic> data = event.docs.first.data();
        if (data['isListened'] == true && data['isExpired'] == true) {
          userUIDLastSentTapeStateMapping[uid] = "Reply";
          userUIDLastSentTapeTimeMapping[uid] =
              convertTimestampToDateTime(data['listenedAt']);
        } else if (data['isListened'] == true) {
          userUIDLastSentTapeStateMapping[uid] = "Played";
          userUIDLastSentTapeTimeMapping[uid] =
              convertTimestampToDateTime(data['listenedAt']);
        } else {
          userUIDLastSentTapeStateMapping[uid] = "Sent";
          userUIDLastSentTapeTimeMapping[uid] =
              convertTimestampToDateTime(data['sentAt']);
        }
      }
    }));
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
        userUIDOnlineMapping[uid] = data['isOnline'];
        userUIDProfilePicMapping[uid] = data['displayImageURL'];
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
        userUIDRecordingState[data['sender']] = data['isRecording'];
        userUIDMoodState[data['sender']] = data['mood'];
        notifyListeners();
      }
    }));
  }

  getUserMood(String uid) {
    return userUIDMoodState[uid];
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    chatStreamSubscription?.cancel();
    myDocumentStreamSubscription?.cancel();
    _firestoreService.saveUserInfo(myUID, {"isOnline": false});
    for (var stream in usersDocumentsSubscriptions) {
      stream?.cancel;
    }
    for (var stream in usersChatForMeStreamSubscriptions) {
      stream?.cancel;
    }
    super.dispose();
  }

  String getProfilePic(String uid) {
    String downloadURL = userUIDProfilePicMapping[uid];
    return downloadURL;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive) {
      _firestoreService.saveUserInfo(myUID, {"isOnline": false});
    } else if (state == AppLifecycleState.resumed) {
      _firestoreService.saveUserInfo(myUID, {"isOnline": true});
    }
    super.didChangeAppLifecycleState(state);
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
      List<String> phoneNumbers = userContactsList.sublist(i,
          i + 10 <= userContactsList.length ? i + 10 : userContactsList.length);
      await _firestoreService
          .getUserFromPhone(phoneNumbers)
          .then((querySnapshot) {
        querySnapshot.docs.forEach((element) {
          String userUID = element.id;
          if (!userUIDs.contains(userUID)) {
            userDocumentStream(element.id);
          }
          Map<String, dynamic> data = element.data();
          if (data['phoneNumber'] != myPhoneNumber) {
            contactsData.add(userUID);
            userUIDContactNameMapping[userUID] =
                userNumberContactNameMapping[data['phoneNumber']];
            if (!userUIDNumberMapping.containsKey(userUID)) {
              userUIDNumberMapping[userUID] = data['phoneNumber'];
            }
          }
        });
      });
    }

    await cache.write(
        'userNumberContactNameMapping', userNumberContactNameMapping);
    await cache.write('userUIDContactNameMapping', userUIDContactNameMapping);
    await cache.write('userUIDNumberMapping', userUIDNumberMapping);
    contactsMap.clear();
    contactsMap.addAll(contactsData);
    await cache.write('contactsMap', contactsMap);
    notifyListeners();
    isFetchingContacts = false;
  }

  String getUserName(String uid) {
    String number = userUIDNumberMapping[uid];
    String contactNameFromUID = userUIDContactNameMapping[uid];
    String contactNameFromNumber = userNumberContactNameMapping[number];
    if (contactNameFromUID != null) {
      return contactNameFromUID;
    } else if (contactNameFromNumber != null) {
      return contactNameFromNumber;
    } else if (number != null) {
      return number;
    } else {
      return "";
    }
  }

  bool getUserOnlineState(String uid) {
    return userUIDOnlineMapping[uid] == null
        ? false
        : userUIDOnlineMapping[uid];
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

  String getPhoneNumber(String uid) {
    return userUIDNumberMapping[uid] != null ? userUIDNumberMapping[uid] : "";
  }

  popIt() {
    _navigationService.goBack();
  }

  Icon showChatState(String yourUID) {
    String myState = userUIDDMyChatStateMapping[yourUID];
    String yourState = userUIDDYourChatStateMapping[yourUID];
    if (myState == 'Received') {
      return Icon(
        PhosphorIcons.playFill,
        color: Colors.deepPurpleAccent,
      );
    } else if ((myState == null || myState == 'Played') && yourState == null) {
      return null;
    } else if (yourState == 'Received') {
      return Icon(
        PhosphorIcons.paperPlane,
        color: Colors.grey,
      );
    } else if (yourState == 'Played') {
      return Icon(PhosphorIcons.speakerSimpleHigh, color: Colors.grey);
    }
    return null;
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

  void goToProfileView() {
    _navigationService.navigateTo(routes.ProfileViewRoute,
        arguments: {"downloadURL": myProfilePic, "displayName": myDisplayName});
  }

  refreshPage() {
    notifyListeners();
  }

  Widget getSubtitle(String yourUID, BuildContext context) {
    int receivedTapes = userUIDReceivedTapesMapping[yourUID] == null
        ? 0
        : userUIDReceivedTapesMapping[yourUID];
    String lastSentTapeState = userUIDLastSentTapeStateMapping[yourUID] == null
        ? "Empty"
        : userUIDLastSentTapeStateMapping[yourUID];
    DateTime lastSentTime = userUIDLastSentTapeTimeMapping[yourUID];
    DateTime lastReceivedTime = userUIDReceivedTapesTimeMapping[yourUID];
    return receivedTapes > 0
        ? Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            children: [
              Icon(
                PhosphorIcons.chatTeardropFill,
                size: 16,
                color: Theme.of(context).accentColor,
              ),
              Text(
                "New Tape",
                style: TextStyle(
                    color: Theme.of(context).accentColor,
                    fontWeight: FontWeight.bold),
              ),
              Text(
                "• ${getTimeDifference(userUIDReceivedTapesTimeMapping[yourUID])}",
                style: TextStyle(color: Colors.grey.shade700),
              )
            ],
          )
        : lastSentTapeState == "Sent"
            ? Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                children: [
                  Icon(
                    PhosphorIcons.paperPlaneRightFill,
                    size: 16,
                    color: Theme.of(context).accentColor,
                  ),
                  Text(
                    "Delivered",
                    style: TextStyle(),
                  ),
                  Text(
                    "• ${getTimeDifference(userUIDLastSentTapeTimeMapping[yourUID])}",
                    style: TextStyle(color: Colors.grey.shade700),
                  )
                ],
              )
            : compareDateTimeGreaterThan(lastReceivedTime, lastSentTime) == 1
                ? Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    children: [
                      Icon(
                        PhosphorIcons.chatTeardropFill,
                        size: 16,
                        color: Colors.grey.shade700,
                      ),
                      Text(
                        "Received",
                      ),
                      Text(
                        "• ${getTimeDifference(userUIDReceivedTapesTimeMapping[yourUID])}",
                        style: TextStyle(color: Colors.grey.shade700),
                      )
                    ],
                  )
                : lastSentTapeState == "Played" || lastSentTapeState == "Reply"
                    ? Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        children: [
                          Icon(
                            PhosphorIcons.speakerSimpleHighFill,
                            size: 16,
                            color: Colors.grey.shade700,
                          ),
                          Text(
                            "Played",
                            style: TextStyle(),
                          ),
                          Text(
                            "• ${getTimeDifference(userUIDLastSentTapeTimeMapping[yourUID])}",
                            style: TextStyle(color: Colors.grey.shade700),
                          )
                        ],
                      )
                    : Text("Tap to Tape");
  }

  bool showPoke(String yourUID) {
    return userUIDWaveMapping[yourUID] == null
        ? false
        : userUIDWaveMapping[yourUID];
  }
}
