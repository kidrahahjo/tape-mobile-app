import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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
import 'package:progress_indicators/progress_indicators.dart';

class ChatViewModel extends ReactiveViewModel with WidgetsBindingObserver {
  // Variables related to services
  final NavigationService _navigationService = locator<NavigationService>();
  final ChatService _chatService = locator<ChatService>();
  final AuthenticationService _authenticationService =
      locator<AuthenticationService>();
  final FirestoreService _firestoreService = locator<FirestoreService>();
  final FirebaseStorageService _firebaseStorageService =
      locator<FirebaseStorageService>();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Variables related to you
  final String yourUID;
  final String yourName;
  String profilePic;
  bool youAreOnline = false;

  // Streams related to you
  Stream<DocumentSnapshot> yourDocumentStream;
  StreamSubscription<DocumentSnapshot> yourDocumentStreamSubscription;

  // Context variables
  final BuildContext context;
  bool isLoading = true;

  // Variables related to your chat state
  bool youAreRecording = false;

  // Streams related to your chat state
  Stream<DocumentSnapshot> chatStateStream;
  StreamSubscription<DocumentSnapshot> chatStateStreamSubscription;

  // Variables related to Tape Area
  ScrollController scrollController = new ScrollController();
  Map<String, double> gapBetweenShouts = {};
  Map<String, double> bubbleTail = {};
  Queue<String> allTapes = new Queue();
  Queue<Map<String, bool>> tapeList = new Queue<Map<String, bool>>();
  Map<String, String> tapeRecorderState = {};
  Map<String, DateTime> tapesByDateTime = {};
  Map<String, String> tapePlayerState = {};
  Map<String, bool> tapePlayedState = {};
  Set<String> yourTapes = {};
  Set<String> playedTapes = {};
  String currentTapePlaying;

  // Streams related to Tape Area
  Stream<QuerySnapshot> tapesForMeStream;
  StreamSubscription<QuerySnapshot> tapesForMeStreamSubscription;
  Stream<QuerySnapshot> myTapesSentStateStream;
  StreamSubscription<QuerySnapshot> myTapesSentStateStreamSubscription;

  // Variables related to Wave
  bool showPoke = false;
  bool pokeSent = false;

  // Streams related to Waves
  Stream<QuerySnapshot> pokesForMeStream;
  StreamSubscription<QuerySnapshot> pokesForMeStreamSubscription;

  // Variables related to mood
  Map<dynamic, String> moodEmojiMapping = {
    "😂": "Face With Tears of Joy",
    "heart": "Heavy Black Heart",
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
  AudioPlayer player = AudioPlayer();
  bool showGlow = false;
  String myMood, yourMood;
  DateTime yourMoodTime;
  bool playYourMood = false;

  // Streams related to mood
  Stream<DocumentSnapshot> yourMoodStream;
  StreamSubscription<DocumentSnapshot> yourMoodStreamSubscription;

  // Variables related to my recording
  double boxLength = 72;
  bool boxExpanded = false;
  Widget deleteIcon = SizedBox.shrink();
  Widget sendIcon = SizedBox.shrink();
  Directory tempDir;

  ChatViewModel(this.yourUID, this.yourName, this.context) {
    WidgetsBinding.instance.addObserver(this);
    _firestoreService.saveUserInfo(
        _authenticationService.currentUser.uid, {"chattingWith": yourUID});
    _firestoreService.getChatStateData(chatForYouUID).then((doc) {
      Map<String, dynamic> data = doc.data();
      myMood = data["mood"];
      notifyListeners();
    });
    flutterLocalNotificationsPlugin.cancel(0, tag: yourUID);
    flutterLocalNotificationsPlugin.cancel(1, tag: yourUID);
    initialiseStreams();
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
    player?.dispose();
    super.dispose();
  }

  // Getters
  @override
  List<ReactiveServiceMixin> get reactiveServices => [_chatService];

  String get myUID => _authenticationService.currentUser.uid;

  String get chatForMeUID => yourUID + '_' + myUID;

  String get chatForYouUID => myUID + '_' + yourUID;

  String get recordingTimer => _chatService.recordingTime;

  bool get iAmRecording => _chatService.isRecordingShout;

  double getGap(int index) {
    return gapBetweenShouts[allTapes.elementAt(index)] == null
        ? 4
        : gapBetweenShouts[allTapes.elementAt(index)];
  }

  // Streams
  initialiseStreams() async {
    await getInitialChatData();
    await getMyMood();
    isLoading = false;
    enableYourDocumentStream();
    enableYourMoodStream();
    enableTapesForMeStream();
    enableChatForMeStateStream();
    enablePokeStream();
    enableTapesSentStateSream();
  }

  getInitialChatData() async {
    tempDir = await getTemporaryDirectory();

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

  getMyMood() async {
    await _firestoreService.getChatStateData(chatForYouUID).then((value) {
      Map<String, dynamic> data = value.data();
      myMood = data["mood"] == "heart" ? "❤️" : data["mood"];
      notifyListeners();
    });
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

  enableYourMoodStream() {
    yourMoodStream = _firestoreService.getChatState(chatForMeUID);
    yourMoodStreamSubscription = yourMoodStream.listen((event) {
      if (event.exists) {
        Map<String, dynamic> data = event.data();
        yourMood = data["mood"] == null
            ? null
            : data["mood"] == "heart"
                ? "❤️"
                : data["mood"];
        DateTime time = convertTimestampToDateTime(data["lastMoodModifiedAt"]);

        if (playYourMood == true) {
          if (time != null &&
              compareDateTimeGreaterThan(time, yourMoodTime) == 1) {
            yourMoodTime = time;
            showGlow = true;
            notifyListeners();
            Future.delayed(Duration(milliseconds: 1500), () {
              showGlow = false;
              notifyListeners();
            });
            playSound(moodEmojiMapping[data["mood"]]);
          }
        } else {
          playYourMood = true;
          notifyListeners();
        }
      }
    });
  }

  enableTapesForMeStream() {
    tapesForMeStream =
        _firestoreService.fetchReceivedTapesFromDatabase(chatForMeUID);
    tapesForMeStreamSubscription = tapesForMeStream.listen((event) {
      event.docs.forEach((element) {
        if (!allTapes.contains(element.id)) {
          yourTapes.add(element.id);
          if (allTapes.length == 0) {
            gapBetweenShouts[element.id] = 4;
            bubbleTail[element.id] = 4;
          } else {
            String lastTape = allTapes.last;
            if (lastTape == "Recording") {
              bubbleTail[element.id] = 32;
              allTapes.removeLast();
              gapBetweenShouts["Recording"] = 4;
              lastTape = allTapes.last;
              if (yourTapes.contains(lastTape)) {
                bubbleTail[lastTape] = 32;
                gapBetweenShouts[element.id] = 4;
              } else {
                bubbleTail[lastTape] = 4;
                gapBetweenShouts[element.id] = 16;
              }
              allTapes.add(element.id);
              allTapes.add("Recording");
              notifyListeners();
            } else if (yourTapes.contains(allTapes.last)) {
              gapBetweenShouts[element.id] = 4;
              bubbleTail[element.id] = 4;
              bubbleTail[allTapes.last] = 32;
              allTapes.add(element.id);
            } else {
              gapBetweenShouts[element.id] = 16;
              bubbleTail[element.id] = 4;
              allTapes.add(element.id);
            }
          }
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
        bool recording =
            data['isRecording'] != null ? data['isRecording'] : false;
        if (recording != youAreRecording) {
          youAreRecording = recording;
          if (recording == false) {
            allTapes.remove("Recording");
            if (yourTapes.contains(allTapes.last)) {
              bubbleTail[allTapes.last] = 4;
            }
            notifyListeners();
          } else if (!allTapes.contains("Recording")) {
            if (yourTapes.contains(allTapes.last)) {
              gapBetweenShouts["Recording"] = 4;
              bubbleTail[allTapes.last] = 32;
            } else {
              gapBetweenShouts["Recording"] = 16;
            }
            allTapes.add("Recording");
            notifyListeners();
            SchedulerBinding.instance.addPostFrameCallback((_) {
              scrollController.animateTo(
                scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
              );
            });
          }
        }
      }
    });
  }

  enablePokeStream() {
    pokesForMeStream = _firestoreService.fetchPokesForMe(chatForMeUID);
    pokesForMeStreamSubscription = pokesForMeStream.listen((event) {
      if (event.docs.length > 0) {
        showGlow = true;
        showPoke = true;
        notifyListeners();
        Future.delayed(Duration(milliseconds: 1500), () {
          showGlow = false;
          showPoke = false;
          notifyListeners();
        });
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

  // I am recording related methods
  void startRecording() async {
    expandBox();
    String audioUID = Uuid().v4().replaceAll("-", "");
    String audioPath = '${tempDir.path}/$audioUID.aac';
    _firestoreService.setRecordingStateToDatabase(chatForYouUID, true);
    _chatService.startRecording(audioUID, audioPath, contractBox);
  }

  void deleteRecording() async {
    notifyListeners();
    await _chatService.stopRecording();
    _firestoreService.setRecordingStateToDatabase(chatForYouUID, false);
  }

  void stopRecording() async {
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
          if (lastTape == "Recording") {
            allTapes.removeLast();
            gapBetweenShouts["Recording"] = 16;
            lastTape = allTapes.last;
            if (yourTapes.contains(allTapes.last)) {
              bubbleTail[allTapes.last] = 4;
            } else {
              bubbleTail[allTapes.last] = 32;
            }
            allTapes.add(audioUID);
            allTapes.add("Recording");
          } else {
            allTapes.add(audioUID);
          }
          if (yourTapes.contains(lastTape)) {
            gapBetweenShouts[audioUID] = 16;
          } else {
            gapBetweenShouts[audioUID] = 4;
            bubbleTail[allTapes.last] = 32;
            bubbleTail[audioUID] = 4;
          }
        }
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

  // I am playing
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

  // Wave related methods
  void poke() {
    pokeSent = true;
    notifyListeners();
    _firestoreService.sendPoke(this.chatForYouUID, this.chatForMeUID,
        {"sentAt": DateTime.now(), "isExpired": false});
    Future.delayed(Duration(milliseconds: 1500), () {
      pokeSent = false;
      notifyListeners();
    });
  }

  // Reaction related methods
  updateMyMood(String emoji) async {
    await _firestoreService.updateChatState(
        chatForYouUID, {"mood": emoji, "lastMoodModifiedAt": DateTime.now()});
    myMood = emoji == "heart" ? "❤️" : emoji;
    playSound(moodEmojiMapping[emoji]);
    notifyListeners();
  }

  void playSound(String name) async {
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.detached ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.inactive ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.paused) {
    } else {
      try {
        await player.setAsset('assets/sfx/$name.wav');
        player.play();
      } catch (e) {
        print(e);
      }
    }
  }

  // UI Related Methods
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
                : Theme.of(context).primaryColorDark,
          ),
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
                color: Theme.of(context).primaryColorDark),
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: playedState
                ? Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                    Icon(
                      PhosphorIcons.speakerSimpleHighFill,
                      color: Theme.of(context).primaryColorLight,
                      size: 20,
                    ),
                    SizedBox(width: 14),
                    Text(
                      "Played",
                      style:
                          TextStyle(color: Theme.of(context).primaryColorLight),
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

  Widget recordingIndicator(BuildContext context) {
    return Container(
        height: 52,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(32)),
            color: Theme.of(context).primaryColorDark),
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(PhosphorIcons.microphoneFill,
                  color: Theme.of(context).accentColor, size: 20),
              SizedBox(width: 12),
              Text("Recording"),
              SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: JumpingDotsProgressIndicator(
                  fontSize: 20,
                  color: Colors.white,
                  dotSpacing: 2,
                ),
              ),
            ]));
  }

  Widget showTape(int index, BuildContext context) {
    String tapeUID = allTapes.elementAt(index);
    if (yourTapes.contains(tapeUID)) {
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
    } else if (tapeUID == "Recording") {
      return Row(
        children: [
          Expanded(flex: 2, child: recordingIndicator(context)),
          Expanded(
            flex: 1,
            child: Container(),
          ),
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(
            flex: 1,
            child: Container(),
          ),
          Expanded(flex: 2, child: senderButton(tapeUID, context, index)),
        ],
      );
    }
  }

  // Other methods
  backToHome() {
    _firestoreService.saveUserInfo(
        _authenticationService.currentUser.uid, {"chattingWith": null});
    _chatService.suspendPlaying();
    _chatService.suspendRecording();
    _navigationService.goBack();
  }
}
