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
import 'package:wavemobileapp/viewmodel/base_model.dart';
import 'package:wavemobileapp/routing_constants.dart' as routes;

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
  String audioUID;
  String audioPath;

  // current state related variables
  bool youAreRecording = false;
  bool youAreListening = false;
  String yourFirstShoutReceived;
  String myFirstShoutSent;
  int numberOfLonelyShouts;

  // recording related variables
  bool iAmRecording = false;

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
          } else if (showReplay == true && currentShoutPlaying == shoutQueue.length - 1) {
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
        if (myFirstShoutSent == null && this.numberOfLonelyShouts != null) {
          // firstShoutSent variable changed in database by other user
          numberOfLonelyShouts = 0;
        }
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
    // shoutsStreamSubscription?.cancel();
    // chatStateStreamSubscription?.cancel();
    // myShoutsSentStateStreamSubscription?.cancel();
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
    shoutsToDelete = new Queue<String>();
    for (String val in shoutQueue) {
      shoutsToDelete.add(val);
    }
    iAmRecording = true;
    bool continueRecording = true;
    audioUID = Uuid().v4().replaceAll("-", "");
    var tempDir = await getTemporaryDirectory();
    audioPath = '${tempDir.path}/$audioUID.aac';
    if (continueRecording == iAmRecording) {
      _firestoreService.setRecordingStateToDatabase(chatForYouUID, true);
      _chatService.startRecording(audioPath);
    } else {
      // show snackbar
    }
  }

  void stopRecording() async {
    iAmRecording = false;
    notifyListeners();
    _firestoreService.setRecordingStateToDatabase(chatForYouUID, false);
    if (_chatService.recordingTime == "" ||
        _chatService.recordingTime == "0s") {
      _chatService.stopRecording();
      // show snackbar
    } else {
      await _chatService.stopRecording();
      currentShoutPlaying = 1;
      bool updateData = false;
      if (shoutsToDelete.contains(yourFirstShoutReceived)) {
        updateData = true;
      }
      for (String val in shoutsToDelete) {
        _firestoreService
            .updateYourShoutState(chatForYouUID, val)
            .onError((error, stackTrace) => null)
            .then((value) {
          shoutQueue.remove(val);
        });
      }
      notifyListeners();
      try {
        Map<String, dynamic> data = {};
        if (numberOfLonelyShouts == 0 || numberOfLonelyShouts == null) {
          data['firstShoutSent'] = audioUID;
        }
        data['numberOfLonelyShouts'] =
            numberOfLonelyShouts == null ? 1 : numberOfLonelyShouts + 1;
        _uploadAudio(audioPath, audioUID, data);
        if (updateData) {
          _firestoreService.updateChatState(chatForMeUID, {
            "firstShoutSent": null,
          });
        }
      } catch (e) {
        // show failed to send snackbar
      }
    }
  }

  _uploadAudio(String filePath, String currentAudioUID,
      Map<String, dynamic> data) async {
    File file = File(filePath);
    await _firebaseStorageService
        .getLocationReference(chatForYouUID, currentAudioUID)
        .putFile(file);
    _firestoreService
        .sendShout(
            myUID, yourUID, chatForYouUID, currentAudioUID, DateTime.now())
        .onError((error, stackTrace) {
      // show failed to send snackbar
    }).whenComplete(() {
      _firestoreService.updateChatState(chatForYouUID, data);
      audioUID = null;
      audioPath = null;
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
            "firstShoutSent": null,
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
