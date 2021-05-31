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
import 'package:tapemobileapp/app/locator.dart';
import 'package:tapemobileapp/services/authentication_service.dart';
import 'package:tapemobileapp/services/chat_service.dart';
import 'package:tapemobileapp/services/firebase_storage_service.dart';
import 'package:tapemobileapp/services/firestore_service.dart';
import 'package:tapemobileapp/services/navigation_service.dart';
import 'package:just_audio/just_audio.dart';

class ChatViewModel extends ReactiveViewModel with WidgetsBindingObserver {
  final String yourUID;
  final String yourName;
  final BuildContext context;

  // services
  final NavigationService _navigationService = locator<NavigationService>();
  final ChatService _chatService = locator<ChatService>();
  final AuthenticationService _authenticationService =
      locator<AuthenticationService>();
  final FirestoreService _firestoreService = locator<FirestoreService>();
  final FirebaseStorageService _firebaseStorageService =
      locator<FirebaseStorageService>();

  //sfx variables
  AudioPlayer player;
  void playSound(String name) async {
    player = AudioPlayer();
    await player.setAsset('assets/sfx/$name.wav');
    player.play();
  }

  // Tape related variables
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
  Map<String, double> gapBetweenShouts = {};
  Map<String, double> bubbleTail = {};
  String profilePic;
  double drawerHeight = 144;
  bool drawerOpen = false;
  double buttonSize = 64;
  String myMood, yourMood;
  bool shakeYourMood = false;
  Map<String, String> moodEmojiMapping = {
    "😂": "Face With Tears of Joy",
    "❤️": "Heavy Black Heart",
    "😢": "Crying Face",
    "😱": "Face Screaming in Fear",
    "💋": "Kiss Mark",
    "💩": "Pile of Poo",
    "😘": "Face Throwing a Kiss",
    "😒": "Unamused Face",
    "😍": "Smiling Face With Heart-Shaped Eyes",
    "😡": "Pouting Face",
    "😳": "Flushed Face",
    "😐": "Neutral Face",
    "👌": "OK Hand Sign",
    "😉": "Winking Face",
    "😕": "Confused Face",
    "👍": "Thumbs Up Sign",
    "😔": "Disappointed Face",
    "😃": "Smiling Face With Open Mouth",
    "😎": "Smirking Face",
    "😄": "Smiling Face With Open Mouth and Smiling Eyes"
  };

//recording widget related variables
  double boxLength = 72;
  bool boxExpanded = false;
  Widget deleteIcon = SizedBox.shrink();
  Widget sendIcon = SizedBox.shrink();

  // Streams

  Stream<DocumentSnapshot> yourMoodStream;
  StreamSubscription<DocumentSnapshot> yourMoodStreamSubscription;

  Stream<QuerySnapshot> pokesForMeStream;
  StreamSubscription<QuerySnapshot> pokesForMeStreamSubscription;
  bool newPoke = false;

  Stream<DocumentSnapshot> yourDocumentStream;
  StreamSubscription<DocumentSnapshot> yourDocumentStreamSubscription;
  Stream<QuerySnapshot> tapesForMeStream;
  StreamSubscription<QuerySnapshot> tapesForMeStreamSubscription;
  Stream<DocumentSnapshot> chatStateStream;
  StreamSubscription<DocumentSnapshot> chatStateStreamSubscription;
  Stream<QuerySnapshot> myTapesSentStateStream;
  StreamSubscription<QuerySnapshot> myTapesSentStateStreamSubscription;

  ChatViewModel(this.yourUID, this.yourName, this.context) {
    WidgetsBinding.instance.addObserver(this);
    _firestoreService.saveUserInfo(
        _authenticationService.currentUser.uid, {"chattingWith": yourUID});
    _firestoreService.getChatStateData(chatForYouUID).then((doc) {
      myMood = doc.get("mood");

      notifyListeners();
    });
    initialiseStreams();
  }

  initialiseStreams() async {
    await getInitialChatData();
    await getMood();
    enableYourDocumentStream();
    enableYourMoodStream();
    enableTapesForMeStream();
    enableChatForMeStateStream();
    enableTapesSentStateSream();
    enablePokeStream();
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

  updateMyMood(String emoji) async {
    await _firestoreService.updateChatState(chatForYouUID, {"mood": emoji});
    await _firestoreService
        .getChatStateData(chatForYouUID)
        .then((doc) => {myMood = doc.get("mood")});
    notifyListeners();
  }

  enableYourMoodStream() {
    yourMoodStream = _firestoreService.getChatState(chatForMeUID);
    yourMoodStreamSubscription = yourMoodStream.listen((event) {
      if (event.get("mood") != yourMood) {
        Map<String, dynamic> data = event.data();
        yourMood = data["mood"] == null ? null : data["mood"];

        shakeYourMood = true;
        notifyListeners();
        playSound(moodEmojiMapping[yourMood]);
        Future.delayed(Duration(seconds: 1), () {
          shakeYourMood = false;
          notifyListeners();
        });
      }
    });
  }

  getMood() async {
    await _firestoreService
        .getChatStateData(chatForMeUID)
        .then((value) => yourMood = value.get("mood"));
  }

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
    for (int i = 0; i < allTapes.length; i++) {
      if (i == 0) {
        gapBetweenShouts[allTapes.elementAt(i)] = 4;
        bubbleTail[allTapes.elementAt(i)] = 4;
      } else {
        String last = allTapes.elementAt(i - 1);
        String curr = allTapes.elementAt(i);
        if (yourTapes.contains(last) && yourTapes.contains(curr)) {
          bubbleTail[allTapes.elementAt(i - 1)] = 32;
          gapBetweenShouts[allTapes.elementAt(i)] = 4;
        } else if (!yourTapes.contains(last) && !yourTapes.contains(curr)) {
          bubbleTail[allTapes.elementAt(i - 1)] = 32;
          gapBetweenShouts[allTapes.elementAt(i)] = 4;
        } else {
          bubbleTail[allTapes.elementAt(i - 1)] = 4;
          gapBetweenShouts[allTapes.elementAt(i)] = 16;
        }
      }
    }
    notifyListeners();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    });
  }

  double getGap(int index) {
    return gapBetweenShouts[allTapes.elementAt(index)] == null
        ? 4
        : gapBetweenShouts[allTapes.elementAt(index)];
  }

  enableYourDocumentStream() {
    yourDocumentStream = _firestoreService.getUserDataStream(yourUID);
    yourDocumentStreamSubscription = yourDocumentStream.listen((event) {
      if (event.exists) {
        Map<String, dynamic> data = event.data();
        youAreOnline = data['isOnline'] == null ? false : data['isOnline'];
        profilePic =
            data['displayImageURL'] == null ? null : data['displayImageURL'];
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
          if (allTapes.length == 0) {
            gapBetweenShouts[element.id] = 4;
            bubbleTail[element.id] = 4;
          } else {
            if (yourTapes.contains(allTapes.last)) {
              gapBetweenShouts[element.id] = 4;
              bubbleTail[element.id] = 4;
              bubbleTail[allTapes.last] = 32;
            } else {
              gapBetweenShouts[element.id] = 16;
              bubbleTail[element.id] = 4;
            }
          }
          allTapes.add(element.id);
          yourTapes.add(element.id);
          Map<String, dynamic> data = element.data();
          tapesByDateTime[element.id] =
              convertTimestampToDateTime(data['sentAt']);
          notifyListeners();
          SchedulerBinding.instance.addPostFrameCallback((_) {
            scrollController.animateTo(
              scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 500),
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

  enablePokeStream() {
    pokesForMeStream = _firestoreService.fetchPokesForMe(chatForMeUID);
    pokesForMeStreamSubscription = pokesForMeStream.listen((event) {
      if (event.docs.length > 0) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
            margin: EdgeInsets.fromLTRB(16, 0, 16, 160),
            backgroundColor: Theme.of(context).accentColor,
            behavior: SnackBarBehavior.floating,
            content: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(PhosphorIcons.handWavingFill),
                SizedBox(width: 8),
                Text(
                  "$yourName waved at you!",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ],
            ),
          ),
        );
      }
      event.docs.forEach((element) {
        _firestoreService.expirePoke(element.id, chatForMeUID);
      });
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
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
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
    pokesForMeStreamSubscription?.cancel();
    yourMoodStreamSubscription?.cancel();
    yourDocumentStreamSubscription?.cancel();
    _chatService.cancelSubscriptions();
    tapesForMeStreamSubscription?.cancel();
    chatStateStreamSubscription?.cancel();
    myTapesSentStateStreamSubscription?.cancel();
    super.dispose();
  }

  void expandBox() {
    boxLength = 280;
    notifyListeners();
    Future.delayed(Duration(milliseconds: 300), () {
      boxExpanded = true;
      notifyListeners();
    });
  }

  void contractBox() {
    boxLength = 72;
    notifyListeners();
    Future.delayed(Duration(milliseconds: 300), () {
      boxExpanded = false;
      notifyListeners();
    });
  }

  void startRecording() async {
    _record = true;
    bool continueRecording = true;

    notifyListeners();
    String audioUID = Uuid().v4().replaceAll("-", "");
    var tempDir = await getTemporaryDirectory();
    String audioPath = '${tempDir.path}/$audioUID.aac';
    if (continueRecording == _record) {
      _firestoreService.setRecordingStateToDatabase(chatForYouUID, true);

      _chatService.startRecording(audioUID, audioPath);
    }
  }

  void deleteRecording() async {
    _record = false;
    notifyListeners();
    await _chatService.stopRecording();
    _firestoreService.setRecordingStateToDatabase(chatForYouUID, false);
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
        if (allTapes.length == 0) {
          gapBetweenShouts[audioUID] = 4;
        } else {
          String lastTape = allTapes.last;
          if (yourTapes.contains(lastTape)) {
            gapBetweenShouts[audioUID] = 16;
          } else {
            gapBetweenShouts[audioUID] = 4;

            bubbleTail[allTapes.last] = 32;
          }
        }
        allTapes.add(audioUID);
        tapeRecorderState[audioUID] = "Sending";
        notifyListeners();
        SchedulerBinding.instance.addPostFrameCallback((_) {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
          );
        });
        _uploadAudio(audioPath, audioUID);
      } catch (e) {
        print(e);
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
    playedTapes.add(audioUID);
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
        if (!playedTapes.contains(uid)) {
          playTape(uid);
        }
        break;
      }
    }
  }

  void poke() {
    _firestoreService.sendPoke(
        this.chatForYouUID, {"sentAt": DateTime.now(), "isExpired": false});
  }

  Widget playerButton(String tapeUID, BuildContext context, int index) {
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
          height: 52,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                  bottomLeft: Radius.circular(
                      bubbleTail[allTapes.elementAt(index)] == null
                          ? 4
                          : bubbleTail[allTapes.elementAt(index)]),
                  bottomRight: Radius.circular(32)),
              color: playerState == null
                  ? Theme.of(context).accentColor
                  : Colors.grey.shade900),
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: playerState == "Played"
              ? Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                  Icon(
                    PhosphorIcons.arrowCounterClockwiseBold,
                    size: 20,
                    color: Theme.of(context).accentColor,
                  ),
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
                              Icon(
                                PhosphorIcons.stopFill,
                                size: 20,
                                color: Theme.of(context).accentColor,
                              ),
                              SizedBox(width: 12),
                              Text("Playing...")
                            ])
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                              Icon(
                                PhosphorIcons.stopFill,
                                size: 20,
                                color: Theme.of(context).accentColor,
                              ),
                              SizedBox(width: 12),
                              Text("Loading...")
                            ]),
        ));
  }

  Widget senderButton(String tapeUID, BuildContext context, int index) {
    String recorderState = tapeRecorderState[tapeUID];
    bool playedState =
        tapePlayedState[tapeUID] == null ? false : tapePlayedState[tapeUID];
    return GestureDetector(
        onTap: () {
          // TODO: code for resend
        },
        child: Container(
            height: 52,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(
                        bubbleTail[allTapes.elementAt(index)] == null
                            ? 4
                            : bubbleTail[allTapes.elementAt(index)])),
                color: Colors.grey.shade900),
            padding: EdgeInsets.symmetric(horizontal: 16),
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
                            Icon(PhosphorIcons.paperPlaneFill, size: 20),
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
                                Icon(PhosphorIcons.paperPlaneFill,
                                    color: Theme.of(context).accentColor,
                                    size: 20),
                                SizedBox(width: 14),
                                Text("Delivered")
                              ])));
  }

  Widget showTape(int index, BuildContext context) {
    String tapeUID = allTapes.elementAt(index);
    if (!yourTapes.contains(tapeUID)) {
      return Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(),
          ),
          Expanded(flex: 4, child: senderButton(tapeUID, context, index)),
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(
            flex: 2,
            child: playerButton(tapeUID, context, index),
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
