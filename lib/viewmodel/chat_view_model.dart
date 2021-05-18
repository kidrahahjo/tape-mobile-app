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
  Queue<String> shoutsToDelete = new Queue<String>();
  int currentShoutPlaying = 1;

  // current state related variables
  bool youAreRecording = false;
  bool youAreListening = false;
  String yourFirstShoutReceived;
  String myFirstShoutSent;
  int numberOfLonelyShouts;
  bool hasPlayed = false;

  // recording related variables
  bool _record = false;
  bool _sendingShout = false;

  // player related variables
  bool autoplay = false;
  bool showReplay = false;

  // Streams
  Stream<QuerySnapshot> shoutsStream;
  StreamSubscription<QuerySnapshot> shoutsStreamSubscription;
  Stream<DocumentSnapshot> chatStateStream;
  StreamSubscription<DocumentSnapshot> chatStateStreamSubscription;
  Stream<DocumentSnapshot> myShoutsSentStateStream;
  StreamSubscription<DocumentSnapshot> myShoutsSentStateStreamSubscription;

  ChatViewModel(this.yourUID, this.yourName) {
    enableShoutsStream();
    enableChatStateStream();
    enableMySentShoutsStateStream();
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

  enableShoutsStream() {
    shoutsStream =
        _firestoreService.fetchEndToEndShoutsFromDatabase(chatForMeUID);
    shoutsStreamSubscription = shoutsStream.listen((event) {
      event.docs.forEach((element) {
        if (!shoutQueue.contains(element.id)) {
          shoutQueue.add(element.id);
          showReplay = false;
          if (autoplay && !(iAmRecording || iAmListening)) {
            currentShoutPlaying = shoutQueue.length;
            startPlaying();
          } else if (showReplay == true &&
              currentShoutPlaying == shoutQueue.length - 1) {
            currentShoutPlaying = shoutQueue.length;
            startPlaying();
          }
          notifyListeners();
        }
      });
    });
  }

  enableChatStateStream() {
    chatStateStream = _firestoreService.getChatState(chatForMeUID);
    chatStateStreamSubscription = chatStateStream.listen((event) {
      if (event.exists) {
        Map<String, dynamic> data = event.data();
        this.youAreRecording =
            data['isRecording'] != null ? data['isRecording'] : false;
        this.youAreListening =
            data['isListening'] != null ? data['isListening'] : false;
        this.yourFirstShoutReceived = data['firstShoutSent'];
        notifyListeners();
      }
    });
  }

  enableMySentShoutsStateStream() {
    myShoutsSentStateStream = _firestoreService.getChatState(chatForYouUID);
    myShoutsSentStateStreamSubscription =
        myShoutsSentStateStream.listen((event) {
      if (event.exists) {
        Map<String, dynamic> data = event.data();
        numberOfLonelyShouts = data['numberOfLonelyShouts'];
        myFirstShoutSent = data['firstShoutSent'];
        hasPlayed = data['hasPlayed'];
      } else {
        myFirstShoutSent = null;
        numberOfLonelyShouts = null;
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
    if (!iAmRecording && currentShoutPlaying < shoutQueue.length) {
      currentShoutPlaying += 1;
      notifyListeners();
      startPlaying();
    } else if (currentShoutPlaying >= shoutQueue.length) {
      showReplay = true;
      notifyListeners();
      _chatService.suspendPlaying();
    }
  }

  void startRecording() async {
    _record = true;
    bool continueRecording = true;
    shoutsToDelete = new Queue<String>();
    for (String val in shoutQueue) {
      shoutsToDelete.add(val);
    }
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
      print('recording too short');
    } else {
      try {
        _sendingShout = true;
        notifyListeners();
        List<String> audioVariables = await _chatService.stopRecording();
        currentShoutPlaying = 1;
        if (shoutsToDelete.contains(yourFirstShoutReceived)) {
          _firestoreService.updateChatState(chatForMeUID, {
            "firstShoutSent": null,
            "numberOfLonelyShouts": 0,
          });
        }

        for (String val in shoutsToDelete) {
          await _firestoreService
              .updateYourShoutState(chatForMeUID, val)
              .onError((error, stackTrace) => null);
          shoutQueue.remove(val);
        }
        Map<String, dynamic> data = {};
        if (numberOfLonelyShouts == 0 || numberOfLonelyShouts == null) {
          data['firstShoutSent'] = audioVariables[1];
          data['hasPlayed'] = false;
        }
        data['numberOfLonelyShouts'] =
            numberOfLonelyShouts == null ? 1 : numberOfLonelyShouts + 1;
        _firestoreService.updateChatState(chatForYouUID, data);
        _uploadAudio(audioVariables[0], audioVariables[1]);
      } catch (e) {
        _sendingShout = false;
        notifyListeners();
        // show failed to send snackbar
        print('failed to send audio 1');
      }
    }
    _firestoreService.setRecordingStateToDatabase(chatForYouUID, false);
  }

  _uploadAudio(String filePath, String currentAudioUID) async {
    File file = File(filePath);
    await _firebaseStorageService
        .getLocationReference(chatForYouUID, currentAudioUID)
        .putFile(file);
    _firestoreService
        .sendShout(
            myUID, yourUID, chatForYouUID, currentAudioUID, DateTime.now())
        .onError((error, stackTrace) {
      // show failed to send snackbar
      print('failed to send audio 2');
    }).whenComplete(() {
      _sendingShout = false;
      notifyListeners();
    });
  }

  void replayShouts() {
    currentShoutPlaying = 1;
    showReplay = false;
    notifyListeners();
    startPlaying();
  }

  void startPlaying() async {
    autoplay = true;
    int current = currentShoutPlaying;
    if (current > shoutQueue.length) {
      currentShoutPlaying = shoutQueue.length;
      showReplay = false;
      notifyListeners();
    } else {
      try {
        showReplay = false;
        notifyListeners();
        String thisAudioUID = shoutQueue.elementAt(current - 1);
        String downloadURL = await _firebaseStorageService
            .getLocationReference(chatForMeUID, thisAudioUID)
            .getDownloadURL();
        if (thisAudioUID == yourFirstShoutReceived) {
          _firestoreService.updateChatState(chatForMeUID, {
            "hasPlayed": true,
          });
        }
        if (current == currentShoutPlaying) {
          _firestoreService.setListeningStateToDatabase(chatForYouUID, true);
          _chatService.startPlaying(downloadURL, whenFinished);
        }
      } catch (e) {
        notifyListeners();
        _chatService.stopPlaying();
        _firestoreService.setListeningStateToDatabase(chatForYouUID, false);
      }
    }
  }

  void stopPlaying() {
    autoplay = false;
    notifyListeners();
    _firestoreService.setListeningStateToDatabase(chatForYouUID, false);
    _chatService.stopPlaying();
  }

  void whenFinished() {
    _firestoreService.setListeningStateToDatabase(chatForYouUID, false);
    playNextShout();
  }
}
