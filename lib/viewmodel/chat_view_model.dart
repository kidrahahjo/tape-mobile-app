import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:stacked/stacked.dart';
import 'package:tapemobileapp/utils/time_utils.dart';
import 'package:uuid/uuid.dart';
import 'package:tapemobileapp/locator.dart';
import 'package:tapemobileapp/services/authentication_service.dart';
import 'package:tapemobileapp/services/chat_service.dart';
import 'package:tapemobileapp/services/firebase_storage_service.dart';
import 'package:tapemobileapp/services/firestore_service.dart';
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
  bool youAreOnline = false;
  String yourChatState;

  // current state related variables
  bool youAreRecording = false;
  bool hasPlayed = false;

  Map<String, String> tapeState = {};
  Map<String, DateTime> tapesByDateTime = {};
  Map<String, String> tapePlayerState = {};
  Set<String> yourTapes = {};
  Queue<String> allTapes = new Queue();

  // recording related variables
  bool _record = false;

  // player related variables
  bool autoplay = false;

  //new chat related variables
  Queue<Map<String, bool>> tapeList = new Queue<Map<String, bool>>();

  ScrollController scrollController = new ScrollController();

  // Streams
  Stream<DocumentSnapshot> yourDocumentStream;
  StreamSubscription<DocumentSnapshot> yourDocumentStreamSubscription;
  Stream<QuerySnapshot> tapesForMeStream;
  StreamSubscription<QuerySnapshot> tapesForMeStreamSubscription;
  Stream<DocumentSnapshot> chatStateStream;
  StreamSubscription<DocumentSnapshot> chatStateStreamSubscription;
  Stream<DocumentSnapshot> myShoutsSentStateStream;
  StreamSubscription<DocumentSnapshot> myShoutsSentStateStreamSubscription;

  ChatViewModel(this.yourUID, this.yourName) {
    WidgetsBinding.instance.addObserver(this);
    _firestoreService.saveUserInfo(
        _authenticationService.currentUser.uid, {"chattingWith": yourUID});
    initialiseStreams();
  }

  initialiseStreams() async {
    await getInitialChatData();
    enableYourDocumentStream();
    enableTapesForMeStream();
    enableChatForMeStateStream();
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

  getInitialChatData() async {
    await _firestoreService.getRequestedChats(chatForMeUID).then((value) {
      value.docs.forEach((element) {
        Map<String, dynamic> data = element.data();
        yourTapes.add(element.id);
        tapesByDateTime[element.id] =
            convertTimestampToDateTime(data['sentAt']);
      });
    });
    await _firestoreService.getRequestedChats(chatForYouUID).then((value) {
      value.docs.forEach((element) {
        print(element.id);
        Map<String, dynamic> data = element.data();
        tapesByDateTime[element.id] =
            convertTimestampToDateTime(data['sentAt']);
      });
    });
    List<String> sortedKeys = tapesByDateTime.keys.toList(growable: false)
      ..sort((k1, k2) =>
          compareDateTimeGreaterThan(tapesByDateTime[k1], tapesByDateTime[k2]));
    allTapes.addAll(List<String>.from(sortedKeys));
  }

  enableYourDocumentStream() {
    yourDocumentStream = _firestoreService.getUserDataStream(yourUID);
    yourDocumentStreamSubscription = yourDocumentStream.listen((event) {
      if (event.exists) {
        Map<String, dynamic> data = event.data();
        youAreOnline = data['isOnline'] == null ? false : data['isOnline'];
        notifyListeners();
      }
    });
  }

  enableTapesForMeStream() {
    tapesForMeStream =
        _firestoreService.fetchEndToEndShoutsFromDatabase(chatForMeUID);
    tapesForMeStreamSubscription = tapesForMeStream.listen((event) {
      event.docs.forEach((element) {
        if (!allTapes.contains(element.id)) {
          allTapes.add(element.id);
          yourTapes.add(element.id);
          Map<String, dynamic> data = element.data();
          tapesByDateTime[element.id] =
              convertTimestampToDateTime(data['sentAt']);
          notifyListeners();
          scrollController.animateTo(scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut);
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
        notifyListeners();
      }
    });
  }

  backToHome() {
    _firestoreService.saveUserInfo(
        _authenticationService.currentUser.uid, {"chattingWith": null});
    _chatService.suspendPlaying();
    _chatService.suspendRecording();
    _navigationService.goBack();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive) {
      _firestoreService.saveUserInfo(_authenticationService.currentUser.uid,
          {"isOnline": false, "chattingWith": null});
    } else if (state == AppLifecycleState.resumed) {
      _firestoreService.saveUserInfo(_authenticationService.currentUser.uid,
          {"isOnline": true, "chattingWith": yourUID});
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _firestoreService.saveUserInfo(
        _authenticationService.currentUser.uid, {"chattingWith": null});

    yourDocumentStreamSubscription?.cancel();
    _chatService.cancelSubscriptions();
    tapesForMeStreamSubscription?.cancel();
    chatStateStreamSubscription?.cancel();
    myShoutsSentStateStreamSubscription?.cancel();
    super.dispose();
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
    String audioUID, audioPath;
    if (_chatService.recordingTime == "" ||
        _chatService.recordingTime == "0s") {
      await _chatService.stopRecording();
      // show snackbar
    } else {
      try {
        List<String> audioVariables = await _chatService.stopRecording();
        audioPath = audioVariables[0];
        audioUID = audioVariables[1];
        allTapes.add(audioUID);
        tapeState[audioUID] = "Sending";
        notifyListeners();
        _uploadAudio(audioPath, audioUID);
        scrollController.animateTo(scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 500), curve: Curves.easeOut);
      } catch (e) {
        tapeState[audioUID] = "Some Error Occured";
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
      tapeState[currentAudioUID] = "Sent";
      notifyListeners();
    });
  }

  void playTape(audioUID) async {
    tapePlayerState[audioUID] = "Loading";
    notifyListeners();
    bool yourTape = yourTapes.contains(audioUID);
    String downloadURL = await _firebaseStorageService
        .getLocationReference(yourTape ? chatForMeUID : chatForYouUID, audioUID)
        .getDownloadURL();
    tapePlayerState[audioUID] = "Playing";
    notifyListeners();
    _chatService.startPlaying(
        downloadURL, yourTape ? whenFinished : () {}, audioUID);
  }

  void stopTape(audioUID) {
    tapePlayerState[audioUID] = null;
    notifyListeners();
    _chatService.stopPlaying();
  }

  void whenFinished(String audioUID) {
    tapePlayerState[audioUID] = null;
    notifyListeners();
    // update message and chat state
    _firestoreService.updateYourShoutState(
      chatForMeUID,
      audioUID,
      {
        "isListened": true,
        "listenedAt": DateTime.now(),
      },
    );
    if (audioUID == yourTapes.last) {
      _firestoreService.updateChatState(chatForYouUID,
          {"chatState": 'Played', 'lastListenedAt': DateTime.now()});
      if (yourChatState == 'Played') {
        _firestoreService.updateChatState(chatForMeUID, {"chatState": null});
      }
    }
    int index = allTapes.toList().indexOf(audioUID);
    for (int i = index + 1; i < allTapes.length; i ++) {
      String uid = allTapes.elementAt(i);
      if (yourTapes.contains(uid)) {
        playTape(uid);
        break;
      }
    }
  }

  void poke() {
    _firestoreService.sendPoke(this.chatForYouUID, {"sendAt": DateTime.now()});
  }

  Widget playerButton(String tapeUID, String playerState) {
    return playerState == null
        ? IconButton(
            onPressed: () {
              playTape(tapeUID);
            },
            icon: Icon(PhosphorIcons.playFill))
        : playerState == "Playing"
            ? IconButton(
                onPressed: () {
                  stopTape(tapeUID);
                },
                icon: Icon(PhosphorIcons.stopFill))
            : Center(
                child: CircularProgressIndicator(),
              );
  }

  Widget showTape(int index, BuildContext context) {
    String tapeUID = allTapes.elementAt(index);
    String playerState = tapePlayerState[tapeUID];
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: !yourTapes.contains(tapeUID)
            ? Theme.of(context).accentColor
            : Colors.grey.shade900,
      ),
      padding: EdgeInsets.all(12),
      child: !yourTapes.contains(tapeUID)
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                playerButton(tapeUID, playerState),
                CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 24,
                  child: tapeState[tapeUID] == "Sending"
                      ? Center(
                          child: CircularProgressIndicator(),
                        )
                      : null,
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 24,
                ),
                playerButton(tapeUID, playerState),
              ],
            ),
    );
  }
}
