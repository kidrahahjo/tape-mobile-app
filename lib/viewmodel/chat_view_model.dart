import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:stacked/stacked.dart';
import 'package:uuid/uuid.dart';
import 'package:tapemobileapp/locator.dart';
import 'package:tapemobileapp/services/authentication_service.dart';
import 'package:tapemobileapp/services/chat_service.dart';
import 'package:tapemobileapp/services/firebase_storage_service.dart';
import 'package:tapemobileapp/services/firstore_service.dart';
import 'package:tapemobileapp/services/navigation_service.dart';

class ChatViewModel extends ReactiveViewModel with WidgetsBindingObserver {
  final String yourUID;
  final String yourName;

  // services
  final NavigationService _navigationService = locator<NavigationService>();
  final ChatService _chatService = locator<ChatService>();
  final AuthenticationService _authenticationService =
      locator<AuthenticationService>();
  final FirestoreService _firestoreService = locator<FirestoreService>();
  final FirebaseStorageService _firebaseStorageService =
      locator<FirebaseStorageService>();

  // shout related variables
  Queue<String> shoutQueue = new Queue<String>();
  int currentShoutPlaying = 1;
  Map<String, DateTime> shoutsToTimeStamp = {};

  // status related variables
  String yourStatus;
  bool youAreOnline = false;

  // current state related variables
  bool youAreRecording = false;
  bool hasPlayed = false;
  String myChatState;
  String yourChatState;
  DateTime lastSentTime;
  DateTime lastPlayedTime;

  // recording related variables
  bool _record = false;
  bool _sendingShout = false;

  // player related variables
  bool autoplay = false;

  // Streams
  Stream<DocumentSnapshot> yourDocumentStream;
  StreamSubscription<DocumentSnapshot> yourDocumentStreamSubscription;
  Stream<QuerySnapshot> shoutsStream;
  StreamSubscription<QuerySnapshot> shoutsStreamSubscription;
  Stream<DocumentSnapshot> chatStateStream;
  StreamSubscription<DocumentSnapshot> chatStateStreamSubscription;
  Stream<DocumentSnapshot> myShoutsSentStateStream;
  StreamSubscription<DocumentSnapshot> myShoutsSentStateStreamSubscription;

  ChatViewModel(this.yourUID, this.yourName) {
    WidgetsBinding.instance.addObserver(this);
    _firestoreService.saveUserInfo(_authenticationService.currentUser.uid, {"chattingWith": yourUID});
    enableYourDocumentStream();
    enableShoutsStream();
    enableChatForMeStateStream();
    enableChatForYouStateStream();
  }

  @override
  List<ReactiveServiceMixin> get reactiveServices => [_chatService];

  String get myUID => _authenticationService.currentUser.uid;

  String get chatForMeUID => yourUID + '_' + myUID;

  String get chatForYouUID => myUID + '_' + yourUID;

  String get recordingTimer => _chatService.recordingTime;

  bool get isLoadingShout => _chatService.isLoadingShout;

  bool get iAmListening => _chatService.isPlayingShout;

  bool get iAmRecording => _chatService.isRecordingShout;

  bool get sendingShout => _sendingShout;

  int get totalShouts => shoutQueue.length;

  String get status => yourStatus == null ? "" : yourStatus;

  enableYourDocumentStream() {
    yourDocumentStream = _firestoreService.getUserDataStream(yourUID);
    yourDocumentStreamSubscription = yourDocumentStream.listen((event) {
      if (event.exists) {
        Map<String, dynamic> data = event.data();
        yourStatus = data['currentStatus'];
        youAreOnline = data['isOnline'] == null ? false : data['isOnline'];
        notifyListeners();
      }
    });
  }

  convertToDateTime(Timestamp time) {
    if (time == null) {
      return null;
    } else {
      return DateTime.fromMicrosecondsSinceEpoch(time.microsecondsSinceEpoch);
    }
  }

  enableShoutsStream() {
    shoutsStream =
        _firestoreService.fetchEndToEndShoutsFromDatabase(chatForMeUID);
    shoutsStreamSubscription = shoutsStream.listen((event) {
      event.docs.forEach((element) {
        if (!shoutQueue.contains(element.id)) {
          shoutQueue.add(element.id);
          Map<String, dynamic> data = element.data();
          shoutsToTimeStamp[element.id] = convertToDateTime(data['sentAt']);
          notifyListeners();
          if (shoutQueue.length == 1 && autoplay) {
            currentShoutPlaying = 1;
            startPlaying();
          }
        }
      });
    });
  }

  enableChatForMeStateStream() {
    chatStateStream = _firestoreService.getChatState(chatForMeUID);
    chatStateStreamSubscription = chatStateStream.listen((event) {
      if (event.exists) {
        Map<String, dynamic> data = event.data();
        this.youAreRecording =
            data['isRecording'] != null ? data['isRecording'] : false;
        this.yourChatState = data['chatState'];
        this.lastPlayedTime = convertToDateTime(data['lastListenedAt']);
        notifyListeners();
      }
    });
  }

  enableChatForYouStateStream() {
    myShoutsSentStateStream = _firestoreService.getChatState(chatForYouUID);
    myShoutsSentStateStreamSubscription =
        myShoutsSentStateStream.listen((event) {
      if (event.exists) {
        Map<String, dynamic> data = event.data();
        this.myChatState = data['chatState'];
        this.lastSentTime = convertToDateTime(data['lastSentAt']);
      }
      notifyListeners();
    });
  }

  backToHome() {
    _firestoreService.saveUserInfo(_authenticationService.currentUser.uid, {"chattingWith": null});
    _chatService.suspendPlaying();
    _chatService.suspendRecording();
    _navigationService.goBack();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _firestoreService.saveUserInfo(_authenticationService.currentUser.uid, {"isOnline": false, "chattingWith": null});
    } else if (state == AppLifecycleState.resumed) {
      _firestoreService.saveUserInfo(_authenticationService.currentUser.uid, {"isOnline": true, "chattingWith": yourUID});
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    yourDocumentStreamSubscription?.cancel();
    _chatService.cancelSubscriptions();
    shoutsStreamSubscription?.cancel();
    chatStateStreamSubscription?.cancel();
    myShoutsSentStateStreamSubscription?.cancel();
    super.dispose();
  }

  void playNextShout() {
    currentShoutPlaying += 1;
    notifyListeners();
    if (autoplay) {
      startPlaying();
    }
  }

  void skip() {
    _firestoreService.updateYourShoutState(
      chatForMeUID,
      shoutQueue.elementAt(currentShoutPlaying - 1),
      {
        "isListened": true,
        "listenedAt": DateTime.now(),
      },
    );
    if (currentShoutPlaying == shoutQueue.length) {
      _firestoreService.updateChatState(chatForYouUID,
          {"chatState": 'Played', 'lastListenedAt': DateTime.now()});
      if (yourChatState == 'Played') {
        _firestoreService.updateChatState(chatForMeUID, {"chatState": null});
      }
      shoutQueue = new Queue();
      currentShoutPlaying = 1;
    } else {
      playNextShout();
    }
  }

  void startRecording() async {
    _record = true;
    bool continueRecording = true;
    String audioUID = Uuid().v4().replaceAll("-", "");
    var tempDir = await getTemporaryDirectory();
    String audioPath = '${tempDir.path}/$audioUID.aac';
    if (continueRecording == _record) {
      _firestoreService.setRecordingStateToDatabase(chatForYouUID, true);
      _chatService.startRecording(audioUID, audioPath);
    }
  }

  void stopRecording() async {
    _record = false;
    if (_chatService.recordingTime == "" ||
        _chatService.recordingTime == "0s") {
      await _chatService.stopRecording();
      // show snackbar
    } else {
      try {
        _sendingShout = true;
        notifyListeners();
        List<String> audioVariables = await _chatService.stopRecording();
        _uploadAudio(audioVariables[0], audioVariables[1]);
      } catch (e) {
        _sendingShout = false;
        notifyListeners();
        // show failed to send snackbar
      }
    }
    _firestoreService.setRecordingStateToDatabase(chatForYouUID, false);
  }

  _uploadAudio(String filePath, String currentAudioUID) async {
    File file = File(filePath);
    await _firebaseStorageService
        .getLocationReference(chatForYouUID, currentAudioUID)
        .putFile(file)
        .whenComplete(() {
      _sendingShout = false;
    });
  }

  void startPlaying() async {
    autoplay = true;
    int current = currentShoutPlaying;
    if (current > shoutQueue.length) {
      currentShoutPlaying = shoutQueue.length;
      notifyListeners();
    } else {
      try {
        notifyListeners();
        String thisAudioUID = shoutQueue.elementAt(current - 1);
        String downloadURL = await _firebaseStorageService
            .getLocationReference(chatForMeUID, thisAudioUID)
            .getDownloadURL();
        if (current == currentShoutPlaying) {
          _chatService.startPlaying(downloadURL, whenFinished, thisAudioUID);
        }
      } catch (e) {
        notifyListeners();
        _chatService.stopPlaying();
      }
    }
  }

  void stopPlaying() {
    autoplay = false;
    notifyListeners();
    _chatService.stopPlaying();
  }

  void whenFinished(String audioUID) {
    // update message and chat state
    _firestoreService.updateYourShoutState(
      chatForMeUID,
      audioUID,
      {
        "isListened": true,
        "listenedAt": DateTime.now(),
      },
    );
    if (currentShoutPlaying == shoutQueue.length) {
      _firestoreService.updateChatState(chatForYouUID,
          {"chatState": 'Played', 'lastListenedAt': DateTime.now()});
      if (yourChatState == 'Played') {
        _firestoreService.updateChatState(chatForMeUID, {"chatState": null});
      }
      shoutQueue = new Queue();
      currentShoutPlaying = 1;
      autoplay = false;
    } else {
      playNextShout();
    }
  }

  void poke() {
    _firestoreService.sendPoke(this.chatForYouUID, {"sendAt": DateTime.now()});
  }

  bool showPlayer() {
    return totalShouts > 0;
  }

  bool showClear() {
    return (myChatState == null || myChatState == 'Played') &&
        yourChatState == null;
  }

  bool showSent() {
    return yourChatState == 'Received';
  }

  bool showShoutPlayed() {
    return yourChatState == 'Played';
  }

  String convertTime(DateTime dateTime) {
    Duration difference = DateTime.now().difference(dateTime);
    int day = difference.inDays;
    int hours = difference.inHours;
    int minutes = difference.inMinutes;
    int seconds = difference.inSeconds;
    if (day != 0) {
      return day.toString() + 'd ago';
    } else if (hours != 0) {
      return hours.toString() + 'h ago';
    } else if (minutes != 0) {
      return minutes.toString() + 'm ago';
    } else if (seconds >= 20) {
      return seconds.toString() + 's ago';
    } else {
      return 'Just now';
    }
  }

  String getTime() {
    if (showPlayer()) {
      DateTime time =
          shoutsToTimeStamp[shoutQueue.elementAt(currentShoutPlaying - 1)];
      return time == null ? "" : convertTime(time);
    } else if (showSent()) {
      return lastSentTime == null ? "" : convertTime(lastSentTime);
    } else if (showShoutPlayed()) {
      return lastPlayedTime == null ? "" : convertTime(lastPlayedTime);
    } else {
      return "";
    }
  }
}
