import 'dart:async';
import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:uuid/uuid.dart';
import 'package:wavemobileapp/database.dart';

class ChatPage extends StatefulWidget {
  // instance variables
  String yourUID;
  String yourName;
  String myUID;

  ChatPage(this.myUID, this.yourUID, this.yourName);

  @override
  _ChatPageState createState() => _ChatPageState(myUID, yourUID, yourName);
}

class _ChatPageState extends State<ChatPage> {
  // instance variables
  String myUID, yourUID, yourName, yourStatus;

  // state controller variables
  Queue music_queue;
  Queue shoutsToDelete;
  int currentAudioPlaying = 1;
  bool isRecording = false;
  bool sendingShout = false;
  String timer = "";
  bool showTemporaryRecordingHelper = false;
  bool isPlaying = false;
  bool isLoadingMusic = false;
  bool youAreListening = false;
  bool youAreRecording = false;
  bool autoplay = false;
  bool showReplay = false;
  bool changedWave = true;

  // stream related variables
  Stream<QuerySnapshot> chatStream;
  StreamSubscription<QuerySnapshot> chatStreamSubs;
  Stream<DocumentSnapshot> chatStateStream;
  StreamSubscription<DocumentSnapshot> chatStateStreamSubs;

  // helper variables
  String audioUID;
  String audioPath;
  String chatForYou;
  String chatForMe;
  bool dontRecord = false;
  bool isFetchingChats;

  // sound related variables
  FlutterSoundRecorder flutterSoundRecorder = new FlutterSoundRecorder();
  var recorderSubscription;
  FlutterSoundPlayer flutterSoundPlayer = new FlutterSoundPlayer();
  var playerSubscription;

  _ChatPageState(this.myUID, this.yourUID, this.yourName) {
    chatForYou = myUID + '_' + yourUID;
    chatForMe = yourUID + '_' + myUID;
  }

  @override
  void initState() {
    this.isFetchingChats = false;
    music_queue = new Queue();
    chatStream = DatabaseMethods().fetchEndToEndShoutsFromDatabase(chatForMe);
    chatStreamSubs = chatStream.listen((event) {
      event.docChanges.forEach((element) {
        if (!music_queue.contains(element.doc.id)) {
          music_queue.add(element.doc.id);
          if (autoplay && !(isRecording || isLoadingMusic || isPlaying)) {
            startPlaying();
          } else {
            setState(() {
              this.showReplay = false;
            });
          }
        }
      });
    });
    chatStateStream = DatabaseMethods().getChatState(chatForMe);
    chatStateStreamSubs = chatStateStream.listen((event) {
      if (event.exists) {
        this.youAreRecording = event.data().containsKey('isRecording')
            ? event.data()['isRecording']
            : false;
        this.youAreListening = event.data().containsKey('isListening')
            ? event.data()['isListening']
            : false;
      }
      if (this.youAreListening || this.youAreListening) {
        setState(() {});
      }
    });
    super.initState();
  }

  @override
  void deactivate() {
    flutterSoundRecorder?.closeAudioSession();
    recorderSubscription?.cancel();
    flutterSoundPlayer?.closeAudioSession();
    playerSubscription?.cancel();
    DatabaseMethods().setRecordingStateToDatabase(chatForYou, false);
    DatabaseMethods().setListeningStateToDatabase(chatForYou, false);
    super.deactivate();
  }

  @override
  void dispose() {
    flutterSoundRecorder?.closeAudioSession();
    recorderSubscription?.cancel();
    flutterSoundPlayer?.closeAudioSession();
    playerSubscription?.cancel();
    chatStreamSubs?.cancel();
    chatStateStreamSubs?.cancel();
    DatabaseMethods().setRecordingStateToDatabase(chatForYou, false);
    DatabaseMethods().setListeningStateToDatabase(chatForYou, false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: "Wave",
        home: Scaffold(
            body: SafeArea(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
              Spacer(),
              Container(
                height: 32,
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: mainHeader(context),
              ),
              SizedBox(
                height: 20,
              ),
              yourCurrentStatus(),
              Spacer(
                flex: 2,
              ),
              centerImageDisplay(),
              SizedBox(
                height: 20,
              ),
              centerStatusDisplay(),
              Spacer(
                flex: 2,
              ),
              mainFooter(),
              Spacer(),
              // ShowTemporaryRecordingHelperWidget(),
              // MainFooter(),
            ]))));
  }

  Widget displayPlayer() {
    return CircleAvatar(
      radius: 100,
      backgroundColor: Colors.black.withOpacity(0.1),
      child: Center(
        child: isRecording
            ? Text(
                "Recording",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff333333)),
              )
            : isLoadingMusic
                ? CircularProgressIndicator()
                : IconButton(
                    iconSize: 50,
                    icon: Icon(
                      showReplay
                          ? Icons.replay
                          : isPlaying
                              ? Icons.stop
                              : Icons.play_arrow,
                      color: Colors.black,
                    ),
                    onPressed: () {
                      if (showReplay) {
                        currentAudioPlaying = 1;
                        this.showReplay = false;
                        this.autoplay = true;
                        startPlaying();
                      } else if (isPlaying) {
                        this.autoplay = false;
                        stopPlaying();
                      } else {
                        this.autoplay = true;
                        startPlaying();
                      }
                    },
                  ),
      ),
    );
  }

  Widget centerImageDisplay() {
    return Container(
      height: 200,
      width: 200,
      // color: Colors.blue,
      child: CircleAvatar(
        radius: 100,
        backgroundColor: Colors.amber,
        child: music_queue.length != 0 ? displayPlayer() : null,
      ),
    );
  }

  Widget listeningRecordingStatus() {
    return Text(
      youAreRecording ? "Recording..." : "Listening...",
      style: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w400, color: Colors.amber),
    );
  }

  Widget yourCurrentStatus() {
    return Container(
        height: 20,
        alignment: Alignment.center,
        child: (youAreListening || youAreRecording)
            ? listeningRecordingStatus()
            : Text(
                "Vibing",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Color(0xff333333)),
              ));
  }

  Widget centerStatusDisplay() {
    return Container(
      height: 40,
      // color: Colors.blue,
      alignment: Alignment.center,
      child: isRecording
          ? Text(timer,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Color(0xff333333)))
          : music_queue.length == 0
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text("No shouts yet.",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Color(0xff333333))),
                    Text("Hold to record, release to send!",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Color(0xff333333))),
                  ],
                )
              : Text(
                  music_queue.length == 1
                      ? "1 shout received."
                      : "${this.currentAudioPlaying.toString()} of ${this.music_queue.length.toString()}",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Color(0xff333333)),
                ),
    );
  }

  Widget backToHome(context) {
    return Container(
      width: 32,
      height: 32,
      child: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            size: 20,
            color: Colors.black,
          ),
          // alignment: Alignment.centerRight,
          onPressed: () {
            Navigator.pop(context);
          }),
    );
  }

  Widget mainHeader(context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        backToHome(context),
        Text(
          yourName,
          style: TextStyle(
              fontSize: 20, color: Colors.black, fontWeight: FontWeight.bold),
        ),
        SizedBox(
          height: 32,
          width: 32,
        ),
      ],
    );
  }

  Widget showTemporaryRecordingHelperWidget() {
    return AnimatedOpacity(
        // If the widget is visible, animate to 0.0 (invisible).
        // If the widget is hidden, animate to 1.0 (fully visible).
        opacity: showTemporaryRecordingHelper ? 1.0 : 0.0,
        duration: Duration(milliseconds: 200),
        // The green box must be a child of the AnimatedOpacity widget.
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
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

  Widget mainFooter() {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          showTemporaryRecordingHelperWidget(),
          footerButtons(),
        ],
      ),
    );
  }

  Widget footerButtons() {
    // Display Buttons which enables features like
    // recording, skipping
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 80,
            width: 80,
          ),
          sendingShout
              ? SizedBox(
                  child: CircularProgressIndicator(
                    strokeWidth: 1,
                  ),
                  height: 80.0,
                  width: 80.0,
                )
              : recordButton(),
          SizedBox(
              height: 80,
              width: 80,
              child: currentAudioPlaying < music_queue.length
                  ? skipButton()
                  : null),
        ],
      ),
    );
  }

  Widget skipButton() {
    return Padding(
      padding: EdgeInsets.only(top: 10, bottom: 10, left: 20),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xfff5f5f5),
        ),
        width: 60,
        height: 60,
        child: IconButton(
          icon: Icon(
            Icons.fast_forward,
            color: Colors.black,
          ),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          onPressed: () {
            if (!isRecording && currentAudioPlaying < music_queue.length) {
              currentAudioPlaying += 1;
              startPlaying();
              DatabaseMethods().setListeningStateToDatabase(chatForYou, false);
            }
          },
        ),
      ),
    );
  }

  Widget recordButton() {
    return GestureDetector(
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
    );
  }

  Future startRecording() async {
    shoutsToDelete = this.music_queue;
    this.isRecording = true;
    this.dontRecord = false;
    flutterSoundRecorder = await FlutterSoundRecorder().openAudioSession();
    String id = Uuid().v4();
    this.audioUID = id.replaceAll("-", "");
    var tempDir = await getTemporaryDirectory();
    this.audioPath = '${tempDir.path}/$audioUID.aac';
    flutterSoundPlayer?.stopPlayer();
    flutterSoundPlayer?.closeAudioSession();
    setState(() {
      this.isPlaying = false;
    });
    if (!this.dontRecord) {
      DatabaseMethods().setRecordingStateToDatabase(chatForYou, true);
      recorderSubscription =
          flutterSoundRecorder?.onProgress?.listen((e) async {
        Duration maxDuration = e.duration;
        setState(() {
          this.timer = maxDuration.inSeconds.toString() + 's';
        });
      });
      await flutterSoundRecorder
          .setSubscriptionDuration(Duration(milliseconds: 100));
      await flutterSoundRecorder?.startRecorder(
        toFile: this.audioPath,
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
      DatabaseMethods().setRecordingStateToDatabase(chatForYou, false);
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
        currentAudioPlaying = 1;
        for (String val in shoutsToDelete) {
          DatabaseMethods()
              .updateShoutState(chatForMe, val)
              .onError((error, stackTrace) => null)
              .then((value) {
            music_queue.remove(val);
            setState(() {});
          });
        }
        try {
          _uploadAudio(this.audioPath, audioUID);
        } catch (e) {
          setState(() {
            this.sendingShout = false;
          });
          failedToSendSnackBar();
        }
      }
    }
  }

  Future playMusic(String downloadURL, int chatNumber) async {
    DatabaseMethods().setListeningStateToDatabase(chatForYou, true);
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
          DatabaseMethods().setListeningStateToDatabase(chatForYou, false);
          setState(() {
            this.isPlaying = false;
          });
          setState(() {
            if (currentAudioPlaying == music_queue.length) {
              this.showReplay = true;
            } else {
              currentAudioPlaying += 1;
            }
            this.isPlaying = false;
          });
          if (showReplay) {
            setState(() {
              this.isLoadingMusic = false;
            });
          } else if (currentAudioPlaying <= music_queue.length) {
            startPlaying();
          } else {
            setState(() {
              this.isPlaying = false;
              this.isLoadingMusic = false;
            });
          }
        });
  }

  Future startPlaying() async {
    int current = currentAudioPlaying;
    setState(() {
      this.isLoadingMusic = true;
      this.isPlaying = false;
      if (this.showReplay) {
        if (this.currentAudioPlaying != music_queue.length) {
          currentAudioPlaying += 1;
          current = currentAudioPlaying;
        }
        this.showReplay = false;
      }
    });
    flutterSoundPlayer?.stopPlayer();
    playerSubscription?.cancel();
    flutterSoundPlayer?.closeAudioSession();
    try {
      String audio_stored = "audio/" +
          chatForMe +
          "/" +
          music_queue.elementAt(current - 1) +
          ".aac";
      String downloadURL = await firebase_storage.FirebaseStorage.instance
          .ref(audio_stored)
          .getDownloadURL();
      if (current == currentAudioPlaying) {
        playMusic(downloadURL, currentAudioPlaying);
      }
    } catch (e) {
      setState(() {
        this.autoplay = false;
        currentAudioPlaying = music_queue.length;
      });
    }
  }

  Future stopPlaying() async {
    DatabaseMethods().setListeningStateToDatabase(chatForYou, false);
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
    }).then((value) {
      audioUID = null;
      setState(() {
        this.sendingShout = false;
      });
    });
  }
}
