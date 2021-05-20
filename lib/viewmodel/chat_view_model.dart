import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:stacked/stacked.dart';
import 'package:uuid/uuid.dart';
import 'package:wavemobileapp/locator.dart';
import 'package:wavemobileapp/services/authentication_service.dart';
import 'package:wavemobileapp/services/chat_service.dart';
import 'package:wavemobileapp/services/firebase_storage_service.dart';
import 'package:wavemobileapp/services/firstore_service.dart';
import 'package:wavemobileapp/services/navigation_service.dart';

class ChatViewModel extends ReactiveViewModel {
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

  // current state related variables
  bool youAreRecording = false;
  bool hasPlayed = false;
  String myChatState;
  String yourChatState;

  // recording related variables
  bool _record = false;
  bool _sendingShout = false;

  // player related variables
  bool autoplay = false;

  // Streams
  Stream<QuerySnapshot> shoutsStream;
  StreamSubscription<QuerySnapshot> shoutsStreamSubscription;
  Stream<DocumentSnapshot> chatStateStream;
  StreamSubscription<DocumentSnapshot> chatStateStreamSubscription;
  Stream<DocumentSnapshot> myShoutsSentStateStream;
  StreamSubscription<DocumentSnapshot> myShoutsSentStateStreamSubscription;

  ChatViewModel(this.yourUID, this.yourName) {
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

  enableShoutsStream() {
    shoutsStream =
        _firestoreService.fetchEndToEndShoutsFromDatabase(chatForMeUID);
    shoutsStreamSubscription = shoutsStream.listen((event) {
      event.docs.forEach((element) {
        if (!shoutQueue.contains(element.id)) {
          shoutQueue.add(element.id);
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
      }
      notifyListeners();
    });
  }

  backToHome() {
    _chatService.suspendPlaying();
    _chatService.suspendRecording();
    _navigationService.goBack();
  }

  @override
  void dispose() {
    _chatService.cancelSubscriptions();
    shoutsStreamSubscription?.cancel();
    chatStateStreamSubscription?.cancel();
    myShoutsSentStateStreamSubscription?.cancel();
    super.dispose();
  }

  void playNextShout() {
    currentShoutPlaying += 1;
    notifyListeners();
    startPlaying();
  }

  void startRecording() async {
    _record = true;
    bool continueRecording = true;
    String audioUID = Uuid().v4().replaceAll("-", "");
    var tempDir = await getTemporaryDirectory();
    String audioPath = '${tempDir.path}/$audioUID.aac';
    if (continueRecording == _record) {
      _chatService.startRecording(audioUID, audioPath);
      _firestoreService.setRecordingStateToDatabase(chatForYouUID, true);
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
        .putFile(file);
    _firestoreService.sendShout({
      "chatForMe": chatForMeUID,
      "chatForYou": chatForYouUID,
      "myUID": myUID,
      "yourUID": yourUID,
      "chatState": 'Received',
    }, currentAudioUID, DateTime.now()).onError((error, stackTrace) {
      // show failed to send snackbar
    }).whenComplete(() {
      _sendingShout = false;
      notifyListeners();
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
        "isListenedAt": DateTime.now(),
      },
    );
    if (currentShoutPlaying == shoutQueue.length) {
      _firestoreService.updateChatState(chatForYouUID, {"chatState": 'Played'});
      if (yourChatState == 'Played') {
        _firestoreService.updateChatState(chatForMeUID, {"chatState": null});
      }
      shoutQueue = new Queue();
    } else {
      playNextShout();
    }
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

  String getTime() {
    return "5m ago";
  }
}
