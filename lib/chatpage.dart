import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(ChatPage());

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

  Future<void> _record() async {
    await Permission.microphone.request();

    await _myRecorder.startRecorder(
      toFile: 'foo.aac',
      codec: Codec.aacADTS,
    );
  }

  Future<void> _stopRecorder() async {
    await _myRecorder.stopRecorder();
  }

  @override
  void initState() {
    super.initState();
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
    await _myPlayer.startPlayer(
        fromURI: 'foo.aac',
        codec: Codec.mp3,
        whenFinished: () {
          setState(() {});
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
