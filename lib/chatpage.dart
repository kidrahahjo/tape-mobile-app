import 'dart:async';
import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:uuid/uuid.dart';
import 'package:wavemobileapp/database.dart';

class ChatPage extends StatefulWidget {
  String myUID;
  String userUID;
  String userName;

  ChatPage(
      @required this.myUID, @required this.userUID, @required this.userName);

  @override
  _ChatPageState createState() => _ChatPageState(myUID, userUID, userName);
}

class _ChatPageState extends State<ChatPage> {
  String myUID;
  String userUID;
  String userName;

  String chatForMeUID;
  String chatForUserUID;

  bool uploadingToFirebase = false;
  bool isRecording = false;
  bool isWavePlaying = false;

  String audioUID = null;

  FlutterSoundRecorder _myRecorder = FlutterSoundRecorder();
  FlutterSoundPlayer _myPlayer = FlutterSoundPlayer();

  Stream waves;
  Queue urlsToAudio = new Queue();

  Timer timer;

  _ChatPageState(
      @required this.myUID, @required this.userUID, @required this.userName) {
    this.chatForUserUID = myUID + "_" + userUID;
    this.chatForMeUID = userUID + "_" + myUID;
  }

  getWaves() async {
    waves = await DatabaseMethods().fetchChatFromDatabase(myUID, userUID);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    getWaves();
    timer =
        Timer.periodic(Duration(seconds: 10), (Timer t) => checkForNewWaves());
    // request for microphone permission
    Permission.microphone.request();
    uploadingToFirebase = false;
    isRecording = false;
    isWavePlaying = false;
    urlsToAudio = new Queue();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  failedToSendSnackBar() {
    final ScaffoldMessengerState scaffoldMessenger =
        ScaffoldMessenger.of(context);
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text("Failed to send wave to $userName")));
  }

  Future<void> _uploadAudio(String filePath, String audio_uid) async {
    File file = File(filePath);

    await firebase_storage.FirebaseStorage.instance
        .ref('audio/$chatForUserUID/$audio_uid.aac')
        .putFile(file);
    DateTime current_time = DateTime.now();

    await DatabaseMethods()
        .updateSentMessage(myUID, userUID, audio_uid, userName, current_time)
        .then((value) {
      audioUID = null;
      setState(() {
        this.uploadingToFirebase = false;
      });
    });
  }

  Future<void> _record() async {
    setState(() {
      this.isRecording = true;
    });
    await _myRecorder.openAudioSession();
    String id = Uuid().v4();
    this.audioUID = id.replaceAll("-", "");
    await _myRecorder.startRecorder(
      toFile: '$audioUID.aac',
      codec: Codec.aacADTS,
    );
  }

  Future<void> _stopRecorder(audio_uid) async {
    setState(() {
      this.isRecording = false;
    });
    await _myRecorder.stopRecorder();
    await _myRecorder.closeAudioSession();
    setState(() {
      this.uploadingToFirebase = true;
    });
    if (audioUID != null) {
      try {
        await _uploadAudio(
            '/data/user/0/com.example.wavemobileapp/cache/$audio_uid.aac',
            audio_uid);
      } catch (e) {
        setState(() {
          this.uploadingToFirebase = false;
        });
        failedToSendSnackBar();
      }
    }
  }

  Future _startPlaying() async {
    setState(() {
      isWavePlaying = true;
    });
    if (urlsToAudio.length == 0) {
      // do nothing
      setState(() {
        urlsToAudio = new Queue();
        isWavePlaying = false;
      });
    } else {
      String audio_stored =
          "audio/" + chatForMeUID + "/" + urlsToAudio.first + ".aac";
      String downloadURL = await firebase_storage.FirebaseStorage.instance
          .ref(audio_stored)
          .getDownloadURL();
      _myPlayer.openAudioSession();
      try {
        await _myPlayer.startPlayer(
            fromURI: downloadURL,
            codec: Codec.mp3,
            whenFinished: () async {
              String lastAudioPlayed = urlsToAudio.removeFirst();
              await DatabaseMethods()
                  .updateChatMessageState(myUID, userUID, lastAudioPlayed);
              setState(() {
                isWavePlaying = !isWavePlaying;
              });
            });
      } catch (e) {
        String lastAudioPlayed = urlsToAudio.removeFirst();
        await DatabaseMethods()
            .updateChatMessageState(myUID, userUID, lastAudioPlayed);
        setState(() {
          isWavePlaying = !isWavePlaying;
        });
      }
    }
  }

  Future _stopPlaying() async {
    if (_myPlayer != null) {
      await _myPlayer.stopPlayer();
      await _myPlayer.closeAudioSession();
    }
    setState(() {
      isWavePlaying = false;
    });
  }

  checkForNewWaves() {
    if (!isRecording && !isWavePlaying) {
      setState(() {});
    }
  }

  Widget wavePlayerWidget() {
    List<String> uids = [];
    return StreamBuilder(
        stream: waves,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            for (QueryDocumentSnapshot doc in snapshot.data.docs) {
              uids.add(doc.id);
            }
          }
          for (String id in uids) {
            if (!urlsToAudio.contains(id)) {
              urlsToAudio.add(id);
            }
          }
          return Text("No waves from $userName, yet!");
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Wave"),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          SizedBox(
            height: 20,
          ),
          Center(
            child: Text(
              userName,
              textScaleFactor: 2,
            ),
          ),
          Spacer(),
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
              border: Border.all(width: 1, color: Colors.black26),
            ),
            child: urlsToAudio.length == 0
                ? Center(
                    child: wavePlayerWidget(),
                  )
                : IconButton(
                    icon: isWavePlaying
                        ? Icon(Icons.stop)
                        : Icon(Icons.play_arrow),
                    onPressed: () {
                      if (isWavePlaying) {
                        _stopPlaying();
                      } else {
                        _startPlaying();
                      }
                    }),
          ),
          Spacer(),
          uploadingToFirebase
              ? Center(child: Text("Uploading..."))
              : GestureDetector(
                  onTapDown: (details) => _record(),
                  onTapUp: (details) => _stopRecorder(audioUID),
                  child: Container(
                    height: 100,
                    width: 100,
                    child: Icon(Icons.mic),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      color: Colors.white,
                      border: Border.all(
                          width: 1,
                          color: isRecording ? Colors.blue : Colors.black26),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

// class PlaybackButton extends StatefulWidget {
//   @override
//   _PlaybackButtonState createState() => _PlaybackButtonState();
// }
//
// class _PlaybackButtonState extends State<PlaybackButton> {
//   bool _isPlaying = false;
//   FlutterSoundPlayer _myPlayer;
//
//   @override
//   void initState() {
//     super.initState();
//     _myPlayer = FlutterSoundPlayer();
//     _myPlayer.openAudioSession().then((value) {
//       setState(() {
//         bool _mPlayerIsInited = true;
//       });
//     });
//   }
//
//   @override
//   void dispose() {
//     _myPlayer.closeAudioSession();
//     _myPlayer = null;
//     super.dispose();
//   }
//
//   void _play() async {
//     String downloadURL = await firebase_storage.FirebaseStorage.instance
//         .ref('audio/foo.aac')
//         .getDownloadURL();
//
//     await _myPlayer.startPlayer(
//         fromURI: downloadURL,
//         codec: Codec.mp3,
//         whenFinished: () {
//           setState(() => _isPlaying = !_isPlaying);
//         });
//   }
//
//   Future<void> _stop() async {
//     if (_myPlayer != null) {
//       await _myPlayer.stopPlayer();
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return IconButton(
//       icon: _isPlaying ? Icon(Icons.stop) : Icon(Icons.play_arrow),
//       onPressed: () {
//         if (_isPlaying) {
//           _stop();
//         } else {
//           _play();
//         }
//         setState(() => _isPlaying = !_isPlaying);
//       },
//     );
//   }
// }
