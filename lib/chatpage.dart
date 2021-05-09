import 'dart:async';
import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:wavemobileapp/database.dart';

class ChatPage extends StatefulWidget {
  // instance variables
  String yourUID;
  String yourName;
  String myUID;

  ChatPage(
      @required this.myUID, @required this.yourUID, @required this.yourName);

  @override
  _ChatPageState createState() => _ChatPageState(myUID, yourUID, yourName);
}

class _ChatPageState extends State<ChatPage> {
  // instance variables
  String myUID, yourUID, yourName, yourStatus;

  // state controller variables
  Queue music_queue;
  int currentAudioPlaying = 1;
  bool isRecording = false;
  bool sendingShout = false;
  String timer = "";
  bool showTemporaryRecordingHelper = false;
  bool isPlaying = false;
  bool isLoadingMusic = false;

  // stream related variables
  Stream<QuerySnapshot> chatStream;

  // helper variables
  String audioUID;
  String chatForYou;
  String chatForMe;
  bool dontRecord = false;
  Timer chatTimer;
  bool isFetchingChats;

  // sound related variables
  FlutterSoundRecorder flutterSoundRecorder = new FlutterSoundRecorder();
  var recorderSubscription;
  FlutterSoundPlayer flutterSoundPlayer = new FlutterSoundPlayer();
  var playerSubscription;

  _ChatPageState(
      @required this.myUID, @required this.yourUID, @required this.yourName) {
    chatForYou = myUID + '_' + yourUID;
    chatForMe = yourUID + '_' + myUID;
  }

  @override
  void initState() {
    this.isFetchingChats = false;
    music_queue = new Queue();
    chatTimer =
        Timer.periodic(Duration(seconds: 1), (Timer t) => fetchChatData());
    super.initState();
  }

  @override
  void deactivate() {
    flutterSoundRecorder?.closeAudioSession();
    recorderSubscription?.cancel();
    flutterSoundPlayer?.closeAudioSession();
    playerSubscription?.cancel();
    chatTimer?.cancel();
    super.deactivate();
  }

  @override
  void dispose() {
    flutterSoundRecorder?.closeAudioSession();
    recorderSubscription?.cancel();
    flutterSoundPlayer?.closeAudioSession();
    playerSubscription?.cancel();
    chatTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: "Wave",
        home: Scaffold(
            body: SafeArea(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
              MainHeader(context),
              YourInfo(),
              isRecording ? RecordingDisplay() : ShoutsDisplay(),
              ShowTemporaryRecordingHelperWidget(),
              sendingShout ? SendingShoutDisplay() : MainFooter(),
            ]))));
  }

  fetchChatData() async {
    if (!this.isFetchingChats) {
      this.isFetchingChats = true;
      await DatabaseMethods()
          .fetchEndToEndShoutsFromDatabase(chatForMe)
          .timeout(Duration(seconds: 5))
          .onError((error, stackTrace) {
        print('timeout');
        this.isFetchingChats = false;
        return null;
      }).then((value) async {
        value.forEach((element) {
          element.docs.forEach((value) {
            this.isFetchingChats = true;
            if (!music_queue.contains(value.id)) {
              music_queue.add(value.id);
              setState(() {});
            }
          });
        });
        return null;
      }).whenComplete(() {
        this.isFetchingChats = false;
      });
    }
  }

  Widget MainHeader(context) {
    return Padding(
      padding: EdgeInsets.only(top: 20, left: 10, right: 10),
      child: Row(
        children: <Widget>[
          IconButton(
              icon: Icon(
                Icons.arrow_back_ios,
                size: 20,
                color: Colors.amber,
              ),
              alignment: Alignment.centerRight,
              onPressed: () {
                print('Peeche Jaa Re');
              }),
        ],
      ),
    );
  }

  Widget YourInfo() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Container(
        constraints: BoxConstraints.expand(
          height: 108,
        ),
        child: Column(
          children: <Widget>[
            Text(
              yourName,
              style: TextStyle(fontSize: 32, color: Colors.black),
            ),
            Text(
              "Vibing",
              style: TextStyle(
                fontSize: 20,
                color: Color(0xffaaaaaa),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget ShoutsDisplay() {
    return Padding(
        padding: EdgeInsets.all(20),
        child: Container(
          constraints: BoxConstraints.expand(
            height: 250,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                  radius: 100,
                  backgroundColor: Color(0xfff5f5f5),
                  child: music_queue.length == 0
                      ? null
                      : Material(
                          color: Colors.transparent,
                          child: Center(
                            child: isLoadingMusic
                                ? CircularProgressIndicator()
                                : IconButton(
                                    iconSize: 50,
                                    icon: Icon(
                                      isPlaying ? Icons.stop : Icons.play_arrow,
                                      color: Colors.black,
                                    ),
                                    onPressed: () {
                                      if (isPlaying) {
                                        stopPlaying();
                                      } else {
                                        startPlaying();
                                      }
                                    },
                                  ),
                          ))),
              Spacer(
                flex: 2,
              ),
              Text(
                music_queue.length == 0
                    ? "No shouts, yet!"
                    : "${this.currentAudioPlaying.toString()} of ${this.music_queue.length.toString()}",
                style: TextStyle(fontSize: 16, color: Color(0xffaaaaaa)),
              ),
              Spacer(),
            ],
          ),
        ));
  }

  Widget RecordingDisplay() {
    return Padding(
        padding: EdgeInsets.all(20),
        child: Material(
            color: Colors.white,
            shape: ContinuousRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            child: Container(
                constraints: BoxConstraints.expand(
                  height: 250,
                ),
                child: Column(children: [
                  Spacer(),
                  Text(
                    "Recording your shout!",
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xffaaaaaa),
                    ),
                  ),
                  Text(timer,
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xffaaaaaa),
                      )),
                  Spacer(),
                ]))));
  }

  Widget SendingShoutDisplay() {
    return Padding(
        padding: EdgeInsets.only(left: 20, right: 20, bottom: 20),
        child: Container(
            constraints: BoxConstraints.expand(
              height: 82,
            ),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SizedBox(
                    child: CircularProgressIndicator(
                      strokeWidth: 1,
                    ),
                    height: 80.0,
                    width: 80.0,
                  ),
                ])));
  }

  Widget ShowTemporaryRecordingHelperWidget() {
    return AnimatedOpacity(
        // If the widget is visible, animate to 0.0 (invisible).
        // If the widget is hidden, animate to 1.0 (fully visible).
        opacity: showTemporaryRecordingHelper ? 1.0 : 0.0,
        duration: Duration(milliseconds: 200),
        // The green box must be a child of the AnimatedOpacity widget.
        child: Padding(
          padding: EdgeInsets.only(left: 20, right: 20, bottom: 5),
          child: Container(
              constraints: BoxConstraints.expand(
                height: 50.0,
              ),
              alignment: Alignment.center,
              child: Material(
                  color: Color(0xFFF5F5F5),
                  shape: ContinuousRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: Text(
                      "Hold to record, release to send!",
                      style: TextStyle(fontSize: 16),
                    ),
                  ))),
        ));
  }

  Widget MainFooter() {
    // Display Buttons which enables features like
    // recording, skipping
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
      Padding(
          padding: EdgeInsets.only(left: 20, right: 20, bottom: 20),
          child: Container(
            constraints: BoxConstraints.expand(
              height: 82,
              width: MediaQuery.of(context).size.width / 2,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTapDown: (details) {
                    startRecording();
                  },
                  onTapUp: (details) {
                    stopRecording();
                  },
                  onHorizontalDragEnd: (value) {
                    stopRecording();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.amber,
                    ),
                    width: 80,
                    height: 80,
                    child: Icon(
                      Icons.record_voice_over,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ))
    ]);
  }

  Future startRecording() async {
    this.isRecording = true;
    this.dontRecord = false;
    flutterSoundRecorder = await FlutterSoundRecorder().openAudioSession();
    String id = Uuid().v4();
    this.audioUID = id.replaceAll("-", "");
    flutterSoundPlayer?.stopPlayer();
    flutterSoundPlayer.closeAudioSession();
    if (!this.dontRecord) {
      recorderSubscription =
          flutterSoundRecorder?.onProgress?.listen((e) async {
        Duration maxDuration = e.duration;
        setState(() {
          this.timer = maxDuration.inSeconds.toString() + 's';
        });
      });
      await flutterSoundRecorder?.startRecorder(
        toFile: audioUID + '.aac',
        codec: Codec.aacADTS,
      );
    }
  }

  Future stopRecording() async {
    if (recorderSubscription == null) {
      this.dontRecord = true;
      recorderSubscription?.cancel();
      recorderSubscription = null;
      flutterSoundRecorder?.stopRecorder();
      flutterSoundRecorder?.closeAudioSession();
      flutterSoundRecorder = null;
      setState(() {
        this.timer = "";
        this.isRecording = false;
        this.sendingShout = false;
        this.showTemporaryRecordingHelper = true;
        Future.delayed(Duration(seconds: 1), () {
          setState(() {
            this.showTemporaryRecordingHelper = false;
          });
        });
      });
    } else {
      // Recording was done properly
      String _timer = this.timer;
      await flutterSoundRecorder.stopRecorder();
      await flutterSoundRecorder.closeAudioSession();
      recorderSubscription.cancel();
      recorderSubscription = null;
      flutterSoundRecorder = null;
      setState(() {
        this.isRecording = false;
        this.sendingShout = true;
        this.timer = "";
      });
      if (_timer == "0s" || _timer == "") {
        setState(() {
          this.sendingShout = false;
          this.showTemporaryRecordingHelper = true;
          Future.delayed(Duration(seconds: 1), () {
            setState(() {
              this.showTemporaryRecordingHelper = false;
            });
          });
        });
      } else {
        try {
          String fileName =
              '/data/user/0/com.example.wavemobileapp/cache/$audioUID.aac';
          _uploadAudio(fileName, audioUID);
        } catch (e) {
          setState(() {
            this.sendingShout = false;
          });
          failedToSendSnackBar();
        }
      }
    }
  }

  Future playMusic(String downloadURL) async {
    flutterSoundPlayer = await FlutterSoundPlayer().openAudioSession();
    playerSubscription = flutterSoundPlayer.onProgress.listen((event) {
      // Duration maxDuration = e.duration;
      // Duration position = e.position;
      // TODO: use the above to display a circular progress indicator
    });
    setState(() {
      this.isLoadingMusic = false;
      this.isPlaying = true;
    });
    flutterSoundPlayer.startPlayer(
        fromURI: downloadURL,
        codec: Codec.mp3,
        whenFinished: () async {
          await DatabaseMethods()
              .updateShoutState(
                  chatForMe, music_queue.elementAt(currentAudioPlaying - 1))
              .onError((error, stackTrace) {
            setState(() {
              this.isPlaying = false;
            });
          }).then((value) {
            setState(() {
              if (currentAudioPlaying == music_queue.length) {
                currentAudioPlaying = 1;
                music_queue = new Queue();
              } else {
                currentAudioPlaying += 1;
              }
              this.isPlaying = false;
            });
            if (music_queue.length != 0) {
              startPlaying();
            } else {
              setState(() {
                this.isPlaying = false;
                this.isLoadingMusic = false;
              });
            }
          });
        });
  }

  Future startPlaying() async {
    setState(() {
      this.isLoadingMusic = true;
    });
    flutterSoundPlayer?.stopPlayer();
    playerSubscription?.cancel();
    flutterSoundPlayer?.closeAudioSession();
    String audio_stored = "audio/" +
        chatForMe +
        "/" +
        music_queue.elementAt(currentAudioPlaying - 1) +
        ".aac";
    print("getting download url");
    String downloadURL = await firebase_storage.FirebaseStorage.instance
        .ref(audio_stored)
        .getDownloadURL();

    print("playing music");
    playMusic(downloadURL);
  }

  Future stopPlaying() async {
    flutterSoundPlayer?.stopPlayer();
    playerSubscription?.cancel();
    flutterSoundPlayer?.closeAudioSession();
    setState(() {
      this.isPlaying = false;
    });
  }

  failedToSendSnackBar() {
    final ScaffoldMessengerState scaffoldMessenger =
        ScaffoldMessenger.of(context);
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text("Failed to send shout to $yourName")));
  }

  _uploadAudio(String filePath, String audio_uid) async {
    File file = File(filePath);
    await firebase_storage.FirebaseStorage.instance
        .ref('audio/$chatForYou/$audio_uid.aac')
        .putFile(file);

    DateTime current_time = DateTime.now();

    await DatabaseMethods()
        .sendShout(myUID, yourUID, chatForYou, audioUID, current_time)
    .timeout(Duration(seconds: 5))
    .onError((error, stackTrace) {
      setState(() {
        this.sendingShout = false;
      });
      failedToSendSnackBar();
    })
        .then((value) {
      audioUID = null;
      setState(() {
        this.sendingShout = false;
      });
    });
  }
}
