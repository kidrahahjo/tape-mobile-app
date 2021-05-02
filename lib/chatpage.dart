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

  ChatPage(@required this.myUID, @required this.userUID,
      @required this.userName);

  @override
  _ChatPageState createState() => _ChatPageState(myUID, userUID, userName);
}


class _ChatPageState extends State<ChatPage> {
  String myUID;
  String userUID;
  String userName;

  String chatForMeUID;
  String chatForUserUID;

  bool isFetchingChats = true;
  bool uploadingToFirebase = false;
  bool isRecording = false;

  String audioUID = null;

  FlutterSoundRecorder _myRecorder = FlutterSoundRecorder();

  _ChatPageState(@required this.myUID, @required this.userUID,
      @required this.userName) {
    this.chatForUserUID = myUID + "_" + userUID;
    this.chatForMeUID = userUID + "_" + myUID;
  }

  @override
  void initState() {
    super.initState();
    // request for microphone permission
    Permission.microphone.request();
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

    Map<String, DateTime> data = {
      "lastModifiedAt": DateTime.now()
    };

    await DatabaseMethods().updateLastTimeStamp(myUID, userUID, data).then(
      (value) {
        audioUID = null;
        setState((){
          this.uploadingToFirebase = false;
        });
      }
    );

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
          SizedBox(height: 20,),
          Center(
            child: Text(
              userName,
              textScaleFactor: 2,
            ),
          ),
          Spacer(),
          // Spacer(),
          GestureDetector(
            onTapDown: (details) => _record(),
            onTapUp: (details) => _stopRecorder(audioUID),
            child: Container(
              height: 100,
              width: 100,
              child: Icon(Icons.mic),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                color: Colors.white,
                border: Border.all(width: 1, color: isRecording ? Colors.blue : Colors.black26),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//         appBar: AppBar(
//           leading: Icon(Icons.arrow_back),
//         ),
//         backgroundColor: Colors.white,
//         body: Padding(
//           padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             mainAxisSize: MainAxisSize.max,
//             children: <Widget>[
//               Center(
//                 child: Text(
//                   "Hardik",
//                   textScaleFactor: 2,
//                 ),
//               ),
//               Container(
//                 height: 200,
//                 width: double.infinity,
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(20),
//                   color: Colors.white,
//                   border: Border.all(width: 1, color: Colors.black26),
//                 ),
//                 child: PlaybackButton(),
//               ),
//               RecordButton(),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//
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
