import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';

import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(ChatPage());
}

class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          leading: Icon(Icons.arrow_back),
        ),
        backgroundColor: Colors.white,
        body: Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Center(
                child: Text(
                  "Hardik",
                  textScaleFactor: 2,
                ),
              ),
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white,
                  border: Border.all(width: 1, color: Colors.black26),
                ),
                child: PlaybackButton(),
              ),
              RecordButton(),
            ],
          ),
        ),
      ),
    );
  }
}

class RecordButton extends StatefulWidget {
  @override
  _RecordButtonState createState() => _RecordButtonState();
}

class _RecordButtonState extends State<RecordButton> {
  FlutterSoundRecorder _myRecorder = FlutterSoundRecorder();

  firebase_storage.FirebaseStorage storage =
      firebase_storage.FirebaseStorage.instance;

  Future<void> _uploadAudio(String filePath) async {
    File file = File(filePath);

    await firebase_storage.FirebaseStorage.instance
        .ref('audio/foo.aac')
        .putFile(file);
  }

  Future<void> _record() async {
    await _myRecorder.startRecorder(
      toFile: 'foo.aac',
      codec: Codec.aacADTS,
    );
  }

  Future<void> _stopRecorder() async {
    await _myRecorder.stopRecorder();
    _uploadAudio('/data/user/0/com.example.wavemobileapp/cache/foo.aac');
  }

  @override
  void initState() {
    super.initState();
    Permission.microphone.request();
    _myRecorder.openAudioSession().then((value) {
      setState(() {
        bool _mRecorderIsInited = true;
      });
    });
  }

  @override
  void dispose() {
    _myRecorder.closeAudioSession();
    _myRecorder = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) => {_record()},
      onTapUp: (details) => {_stopRecorder()},
      child: Container(
        height: 100,
        width: 100,
        child: Icon(Icons.mic),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          color: Colors.white,
          border: Border.all(width: 1, color: Colors.black26),
        ),
      ),
    );
  }
}

class PlaybackButton extends StatefulWidget {
  @override
  _PlaybackButtonState createState() => _PlaybackButtonState();
}

class _PlaybackButtonState extends State<PlaybackButton> {
  bool _isPlaying = false;
  FlutterSoundPlayer _myPlayer;

  @override
  void initState() {
    super.initState();
    _myPlayer = FlutterSoundPlayer();
    _myPlayer.openAudioSession().then((value) {
      setState(() {
        bool _mPlayerIsInited = true;
      });
    });
  }

  @override
  void dispose() {
    _myPlayer.closeAudioSession();
    _myPlayer = null;
    super.dispose();
  }

  void _play() async {
    String downloadURL = await firebase_storage.FirebaseStorage.instance
        .ref('audio/foo.aac')
        .getDownloadURL();

    await _myPlayer.startPlayer(
        fromURI: downloadURL,
        codec: Codec.mp3,
        whenFinished: () {
          setState(() => _isPlaying = !_isPlaying);
        });
  }

  Future<void> _stop() async {
    if (_myPlayer != null) {
      await _myPlayer.stopPlayer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: _isPlaying ? Icon(Icons.stop) : Icon(Icons.play_arrow),
      onPressed: () {
        if (_isPlaying) {
          _stop();
        } else {
          _play();
        }
        setState(() => _isPlaying = !_isPlaying);
      },
    );
  }
}
