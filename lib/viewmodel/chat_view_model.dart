import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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
  String currentTapePlaying;

  Map<String, String> tapeRecorderState = {};
  Map<String, DateTime> tapesByDateTime = {};
  Map<String, String> tapePlayerState = {};
  Map<String, bool> tapePlayedState = {};
  Set<String> yourTapes = {};
  Set<String> playedTapes = {};
  Queue<String> allTapes = new Queue();

  // recording related variables
  bool _record = false;

  // player related variables
  bool autoplay = false;

  //new chat related variables
  Queue<Map<String, bool>> tapeList = new Queue<Map<String, bool>>();
  ScrollController scrollController = new ScrollController();
  String lastTapeSource = "your";
  bool lastTapeSourceWasSame = false;

  // Streams
  Stream<DocumentSnapshot> yourDocumentStream;
  StreamSubscription<DocumentSnapshot> yourDocumentStreamSubscription;
  Stream<QuerySnapshot> tapesForMeStream;
  StreamSubscription<QuerySnapshot> tapesForMeStreamSubscription;
  Stream<DocumentSnapshot> chatStateStream;
  StreamSubscription<DocumentSnapshot> chatStateStreamSubscription;
  Stream<QuerySnapshot> myTapesSentStateStream;
  StreamSubscription<QuerySnapshot> myTapesSentStateStreamSubscription;

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
    enableTapesSentStateSream();
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
    await _firestoreService.getChatsForMe(chatForMeUID).then((value) {
      value.docs.forEach((element) {
        Map<String, dynamic> data = element.data();
        yourTapes.add(element.id);
        tapesByDateTime[element.id] =
            convertTimestampToDateTime(data['sentAt']);
      });
    });
    await _firestoreService.getChatsForYou(chatForYouUID).then((value) {
      value.docs.forEach((element) {
        Map<String, dynamic> data = element.data();
        tapesByDateTime[element.id] =
            convertTimestampToDateTime(data['sentAt']);
        tapeRecorderState[element.id] = "Sent";
        if (data['isListened'] == true) {
          tapePlayedState[element.id] = data['isListened'];
          _firestoreService.updateYourShoutState(
              chatForYouUID, element.id, {"isExpired": true});
        }
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
        _firestoreService.fetchReceivedTapesFromDatabase(chatForMeUID);
    tapesForMeStreamSubscription = tapesForMeStream.listen((event) {
      event.docs.forEach((element) {
        if (!allTapes.contains(element.id)) {
          allTapes.add(element.id);
          yourTapes.add(element.id);
          Map<String, dynamic> data = element.data();
          tapesByDateTime[element.id] =
              convertTimestampToDateTime(data['sentAt']);
          notifyListeners();
          SchedulerBinding.instance.addPostFrameCallback((_) {
            scrollController.animateTo(
              scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          });
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

  enableTapesSentStateSream() {
    myTapesSentStateStream =
        _firestoreService.fetchSentTapesFromDatabase(chatForYouUID);
    myTapesSentStateStreamSubscription = myTapesSentStateStream.listen((event) {
      event.docs.forEach((element) {
        if (allTapes.contains(element.id) &&
            (tapePlayedState[element.id] == null)) {
          Map<String, dynamic> data = element.data();
          if (data['isListened'] == true) {
            tapePlayedState[element.id] = data['isListened'];
            notifyListeners();
            _firestoreService.updateYourShoutState(
                chatForYouUID, element.id, {"isExpired": true});
          }
        }
      });
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
    if (state == AppLifecycleState.detached ||
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
    myTapesSentStateStreamSubscription?.cancel();
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
        tapeRecorderState[audioUID] = "Sending";
        notifyListeners();
        SchedulerBinding.instance.addPostFrameCallback((_) {
          print(scrollController.position.maxScrollExtent);
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });
        _uploadAudio(audioPath, audioUID);
      } catch (e) {
        tapeRecorderState[audioUID] = "Some Error Occured";
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
      tapeRecorderState[currentAudioUID] = "Sent";
      notifyListeners();
    });
  }

  void playTape(audioUID) async {
    if (currentTapePlaying != null) {
      if (playedTapes.contains(currentTapePlaying)) {
        tapePlayerState[currentTapePlaying] = "Played";
      } else {
        tapePlayerState[currentTapePlaying] = null;
      }
    }
    currentTapePlaying = audioUID;
    tapePlayerState[audioUID] = "Loading";
    notifyListeners();
    bool yourTape = yourTapes.contains(audioUID);
    String downloadURL = await _firebaseStorageService
        .getLocationReference(yourTape ? chatForMeUID : chatForYouUID, audioUID)
        .getDownloadURL();
    tapePlayerState[audioUID] = "Playing";
    notifyListeners();
    _chatService.startPlaying(
        downloadURL,
        yourTape
            ? whenFinished
            : (audioUID) {
                tapePlayerState[audioUID] = null;
                notifyListeners();
              },
        audioUID);
    _firestoreService.updateYourShoutState(
      chatForMeUID,
      audioUID,
      {
        "isListened": true,
        "listenedAt": DateTime.now(),
        "count": FieldValue.increment(1),
      },
    );
  }

  void stopTape(audioUID) {
    if (playedTapes.contains(currentTapePlaying)) {
      tapePlayerState[currentTapePlaying] = "Played";
    } else {
      tapePlayerState[currentTapePlaying] = null;
    }
    notifyListeners();
    _chatService.stopPlaying();
  }

  void whenFinished(String audioUID) {
    playedTapes.add(audioUID);
    currentTapePlaying = null;
    tapePlayerState[audioUID] = "Played";
    notifyListeners();
    // update message and chat state
    if (audioUID == yourTapes.last) {
      _firestoreService.updateChatState(chatForYouUID,
          {"chatState": 'Played', 'lastListenedAt': DateTime.now()});
      if (yourChatState == 'Played') {
        _firestoreService.updateChatState(chatForMeUID, {"chatState": null});
      }
    }
    int index = allTapes.toList().indexOf(audioUID);
    for (int i = index + 1; i < allTapes.length; i++) {
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

  Widget playerButton(String tapeUID, BuildContext context) {
    String playerState = tapePlayerState[tapeUID];
    return GestureDetector(
        onTap: () {
          if (playerState == null || playerState == "Played") {
            playTape(tapeUID);
          } else if (playerState == "Playing") {
            stopTape(tapeUID);
          }
        },
        child: Container(
          height: 56,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: playerState == null
                  ? Theme.of(context).accentColor
                  : Colors.grey.shade900),
          padding: EdgeInsets.all(16),
          child: playerState == "Played"
              ? Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                  Icon(PhosphorIcons.arrowCounterClockwiseBold, size: 20),
                  SizedBox(width: 12),
                  Text("Tap to replay")
                ])
              : playerState == null
                  ? Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                      Icon(PhosphorIcons.playFill, size: 20),
                      SizedBox(width: 12),
                      Text("Tap to play")
                    ])
                  : playerState == "Playing"
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                              Icon(PhosphorIcons.stopFill, size: 20),
                              SizedBox(width: 12),
                              Text("Playing...")
                            ])
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                              Icon(PhosphorIcons.stopFill, size: 20),
                              SizedBox(width: 12),
                              Text("Loading...")
                            ]),
        ));
  }

  Widget senderButton(String tapeUID, BuildContext context) {
    String recorderState = tapeRecorderState[tapeUID];
    bool playedState =
        tapePlayedState[tapeUID] == null ? false : tapePlayedState[tapeUID];
    return GestureDetector(
        onTap: () {
          // TODO: code for resend
        },
        child: Container(
            height: 56,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: playedState
                    ? Colors.grey.shade900
                    : Theme.of(context).accentColor),
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: playedState
                ? Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                    Icon(
                      PhosphorIcons.speakerSimpleHighFill,
                      color: Colors.grey,
                      size: 20,
                    ),
                    SizedBox(width: 14),
                    Text(
                      "Played",
                      style: TextStyle(color: Colors.grey),
                    )
                  ])
                : recorderState == "Sending"
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                            Icon(PhosphorIcons.paperPlane, size: 20),
                            SizedBox(width: 14),
                            Text("Sending...")
                          ])
                    : recorderState == "Some Error Occured"
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                                Icon(PhosphorIcons.warningFill, size: 20),
                                SizedBox(width: 14),
                                Text("Not delivered. Try again.")
                              ])
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                                Icon(PhosphorIcons.paperPlaneFill, size: 20),
                                SizedBox(width: 14),
                                Text("Delivered")
                              ])));
  }

  Widget showTape(int index, BuildContext context) {
    String tapeUID = allTapes.elementAt(index);
    if (!yourTapes.contains(tapeUID)) {
      if (lastTapeSource == "mine") {
        lastTapeSourceWasSame = true;
      } else {
        lastTapeSourceWasSame = false;
      }
      lastTapeSource = "mine";
      return Row(
        children: [
          Expanded(
            flex: 1,
            child: Container(),
          ),
          Expanded(flex: 3, child: senderButton(tapeUID, context)),
        ],
      );
    } else {
      if (lastTapeSource == "your") {
        lastTapeSourceWasSame = true;
      } else {
        lastTapeSourceWasSame = false;
      }
      lastTapeSource = "your";
      return Row(
        children: [
          Expanded(
            flex: 3,
            child: playerButton(tapeUID, context),
          ),
          Expanded(
            flex: 1,
            child: Container(),
          ),
        ],
      );
    }
  }
}
