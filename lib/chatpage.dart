import 'dart:async';
import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:phosphor_flutter/phosphor_flutter.dart';
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
  int numberOfShoutsSent;
  String yourFirstShoutReceived;
  String myFirstShoutSent;

  // stream related variables
  Stream<QuerySnapshot> chatStream;
  StreamSubscription<QuerySnapshot> chatStreamSubs;
  Stream<DocumentSnapshot> chatStateStream;
  StreamSubscription<DocumentSnapshot> chatStateStreamSubs;
  Stream<DocumentSnapshot> myChatStateStream;
  StreamSubscription<DocumentSnapshot> myChatStateStreamSubs;

  // helper variables
  String audioUID;
  String audioPath;
  String chatForYou;
  String chatForMe;
  bool dontRecord = false;

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
    music_queue = new Queue();
    chatStream = DatabaseMethods().fetchEndToEndShoutsFromDatabase(chatForMe);
    chatStreamSubs = chatStream.listen((event) {
      event.docChanges.forEach((element) {
        if (!music_queue.contains(element.doc.id)) {
          music_queue.add(element.doc.id);
          if (autoplay && !(isRecording || isLoadingMusic || isPlaying)) {
            startPlaying();
          } else {
            if (this.mounted) {
              setState(() {
                this.showReplay = false;
              });
            }
          }
        }
      });
    });
    chatStateStream = DatabaseMethods().getChatState(chatForMe);
    chatStateStreamSubs = chatStateStream.listen((event) {
      if (event.exists) {
        Map<String, dynamic> data = event.data();
        if (this.mounted) {
          setState(() {
            this.youAreRecording =
                data['isRecording'] != null ? data['isRecording'] : false;
            this.youAreListening =
                data['isListening'] != null ? data['isListening'] : false;
          });
        }
        this.yourFirstShoutReceived = data['firstShoutSent'];
      }
    });
    chatStateStream = DatabaseMethods().getChatState(chatForYou);
    chatStateStreamSubs = chatStateStream.listen((event) {
      if (event.exists) {
        Map<String, dynamic> data = event.data();
        this.numberOfShoutsSent = data['numberOfLonelyShouts'];
        myFirstShoutSent = data['firstShoutSent'];
        if (myFirstShoutSent == null && this.numberOfShoutsSent != null) {
          numberOfShoutsSent = 0;
        }
        if (this.mounted) {
          setState(() {});
        }
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
    myChatStateStreamSubs?.cancel();
    DatabaseMethods().setRecordingStateToDatabase(chatForYou, false);
    DatabaseMethods().setListeningStateToDatabase(chatForYou, false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: false,
        body: SafeArea(
            child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 24, 0, 24),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: mainHeader(context),
                ),
                centerImageDisplay(),
                mainFooter(),
                // ShowTemporaryRecordingHelperWidget(),
                // MainFooter(),
              ]),
        )));
  }

  Widget displayPlayer() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(200),
        border: Border.all(width: 2, color: Theme.of(context).primaryColor),
      ),
      width: 200,
      height: 200,
      child: Center(
        child: isLoadingMusic
            ? CircularProgressIndicator()
            : IconButton(
                icon: Icon(
                  showReplay
                      ? PhosphorIcons.arrowCounterClockwise
                      : isPlaying
                          ? PhosphorIcons.stop
                          : PhosphorIcons.play,
                  color: Colors.white,
                  size: 36,
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

  Widget listeningRecordingStatus() {
    return Text(
      youAreRecording ? "Recording..." : "Listening...",
      style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).accentColor),
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
                    fontSize: 16, color: Theme.of(context).primaryColor),
              ));
  }

  Widget centerImageDisplay() {
    return Column(children: [
      SizedBox(height: 32),
      isRecording
          ? Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(200),
                border:
                    Border.all(width: 2, color: Theme.of(context).primaryColor),
              ),
              width: 200,
              height: 200,
              child: Center(
                child: Text(
                  "Recording...",
                  style: TextStyle(
                      fontSize: 16, color: Theme.of(context).primaryColor),
                ),
              ),
            )
          : music_queue.length == 0
              ? !(this.numberOfShoutsSent == null &&
                      this.myFirstShoutSent == null)
                  ? this.myFirstShoutSent != null
                      ? circularStatusAvatar(PhosphorIcons.paperPlaneTiltThin)
                      : circularStatusAvatar(PhosphorIcons.megaphoneThin)
                  : circularStatusAvatar("Start Shouting")
              : displayPlayer(),
      SizedBox(height: 16),
      centerStatusDisplay(),
    ]);
  }

  Widget circularStatusAvatar(image) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(200),
        border: Border.all(width: 2, color: Theme.of(context).primaryColor),
      ),
      width: 200,
      height: 200,
      child: Center(
        child: Icon(image, size: 72),
      ),
    );
  }

  Widget centerStatusDisplay() {
    return Text(
      isRecording
          ? timer
          : music_queue.length == 0
              ? !(this.numberOfShoutsSent == null &&
                      this.myFirstShoutSent == null)
                  ? this.myFirstShoutSent != null
                      ? "You sent $numberOfShoutsSent shouts!"
                      : "$yourName played your shouts!"
                  : "Send shout to $yourName!"
              : music_queue.length == 1
                  ? "$yourName sent a shout!"
                  : "${this.currentAudioPlaying.toString()} of ${this.music_queue.length.toString()}",
      style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Theme.of(context).primaryColor),
    );
  }

  Widget backToHome(context) {
    return IconButton(
        icon: Icon(
          PhosphorIcons.caretLeft,
          color: Theme.of(context).primaryColor,
          size: 32,
        ),
        // alignment: Alignment.centerRight,
        onPressed: () {
          Navigator.pop(context);
        });
  }

  Widget mainHeader(context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        backToHome(context),
        Column(children: [
          SizedBox(
            height: 8,
          ),
          Text(
            yourName,
            style: TextStyle(
                fontSize: 24,
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold),
          ),
          SizedBox(
            height: 8,
          ),
          yourCurrentStatus(),
        ]),
        SizedBox(
          height: 48,
          width: 48,
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
                    strokeWidth: 2,
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
            color: Theme.of(context).primaryColor,
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
          border: Border.all(width: 2, color: Theme.of(context).primaryColor),
          color: Theme.of(context).accentColor,
        ),
        width: 80,
        height: 80,
        child: Icon(
          PhosphorIcons.broadcast,
          size: 36,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Future startRecording() async {
    shoutsToDelete = new Queue();
    for (var val in this.music_queue) {
      shoutsToDelete.add(val);
    }
    this.isRecording = true;
    this.dontRecord = false;
    flutterSoundRecorder = await FlutterSoundRecorder().openAudioSession();
    String id = Uuid().v4();
    this.audioUID = id.replaceAll("-", "");
    var tempDir = await getTemporaryDirectory();
    this.audioPath = '${tempDir.path}/$audioUID.aac';
    flutterSoundPlayer?.stopPlayer();
    flutterSoundPlayer?.closeAudioSession();
    if (this.mounted) {
      setState(() {
        this.isPlaying = false;
      });
    }
    if (!this.dontRecord) {
      DatabaseMethods().setRecordingStateToDatabase(chatForYou, true);
      recorderSubscription =
          flutterSoundRecorder?.onProgress?.listen((e) async {
        Duration maxDuration = e.duration;
        if (this.mounted) {
          setState(() {
            this.timer = maxDuration.inSeconds.toString() + 's';
          });
        }
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
      if (this.mounted) {
        setState(() {
          this.timer = "";
          this.isRecording = false;
          this.sendingShout = false;
          this.showTemporaryRecordingHelper = true;
          Future.delayed(Duration(seconds: 1), () {
            if (this.mounted) {
              setState(() {
                this.showTemporaryRecordingHelper = false;
              });
            }
          });
        });
      }
    } else {
      DatabaseMethods().setRecordingStateToDatabase(chatForYou, false);
      // Recording was done properly
      String _timer = this.timer;
      await flutterSoundRecorder.stopRecorder();
      await flutterSoundRecorder.closeAudioSession();
      recorderSubscription.cancel();
      recorderSubscription = null;
      flutterSoundRecorder = null;
      if (this.mounted) {
        setState(() {
          this.isRecording = false;
          this.sendingShout = true;
          this.timer = "";
        });
      }
      if (_timer == "0s" || _timer == "") {
        if (this.mounted) {
          setState(() {
            this.sendingShout = false;
            this.showTemporaryRecordingHelper = true;
            Future.delayed(Duration(seconds: 1), () {
              if (this.mounted) {
                setState(() {
                  this.showTemporaryRecordingHelper = false;
                });
              }
            });
          });
        }
      } else {
        currentAudioPlaying = 1;
        for (String val in shoutsToDelete) {
          DatabaseMethods()
              .updateShoutState(chatForMe, val)
              .onError((error, stackTrace) => null)
              .then((value) {
            music_queue.remove(val);
            if (this.mounted) {
              setState(() {});
            }
          });
        }
        try {
          Map<String, dynamic> data = {};
          if (numberOfShoutsSent == 0 || numberOfShoutsSent == null) {
            data['firstShoutSent'] = audioUID;
            numberOfShoutsSent = 0;
          }
          data['numberOfLonelyShouts'] = numberOfShoutsSent + 1;
          DatabaseMethods().updateChatState(chatForYou, data);
          _uploadAudio(this.audioPath, audioUID);
        } catch (e) {
          if (this.mounted) {
            setState(() {
              this.sendingShout = false;
            });
          }
          failedToSendSnackBar();
        }
      }
    }
  }

  Future playMusic(String downloadURL) async {
    DatabaseMethods().setListeningStateToDatabase(chatForYou, true);
    flutterSoundPlayer = await FlutterSoundPlayer().openAudioSession();
    playerSubscription = flutterSoundPlayer.onProgress.listen((event) {
      // Duration maxDuration = e.duration;
      // Duration position = e.position;
      // TODO: use the above to display a circular progress indicator
    });
    if (this.mounted) {
      setState(() {
        this.isLoadingMusic = false;
        this.isPlaying = true;
      });
    }
    flutterSoundPlayer.startPlayer(
        fromURI: downloadURL,
        codec: Codec.mp3,
        whenFinished: () async {
          DatabaseMethods().setListeningStateToDatabase(chatForYou, false);
          if (this.mounted) {
            setState(() {
              this.isPlaying = false;
              if (currentAudioPlaying == music_queue.length) {
                this.showReplay = true;
              } else {
                currentAudioPlaying += 1;
              }
              this.isPlaying = false;
            });
          }
          if (showReplay) {
            if (this.mounted) {
              setState(() {
                this.isLoadingMusic = false;
              });
            }
          } else if (currentAudioPlaying <= music_queue.length) {
            startPlaying();
          } else {
            if (this.mounted) {
              setState(() {
                this.isPlaying = false;
                this.isLoadingMusic = false;
              });
            }
          }
        });
  }

  Future startPlaying() async {
    int current = currentAudioPlaying;
    if (this.mounted) {
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
    }
    flutterSoundPlayer?.stopPlayer();
    playerSubscription?.cancel();
    flutterSoundPlayer?.closeAudioSession();
    try {
      String thisAudioUID = music_queue.elementAt(current - 1);
      String audio_stored = "audio/" + chatForMe + "/" + thisAudioUID + ".aac";
      String downloadURL = await firebase_storage.FirebaseStorage.instance
          .ref(audio_stored)
          .getDownloadURL();
      if (current == currentAudioPlaying) {
        if (thisAudioUID == yourFirstShoutReceived) {
          DatabaseMethods().updateChatState(chatForMe, {
            "firstShoutSent": null,
          });
        }
        playMusic(downloadURL);
      }
    } catch (e) {
      if (this.mounted) {
        setState(() {
          this.autoplay = false;
          currentAudioPlaying = music_queue.length;
        });
      }
    }
  }

  Future stopPlaying() async {
    DatabaseMethods().setListeningStateToDatabase(chatForYou, false);
    flutterSoundPlayer?.stopPlayer();
    playerSubscription?.cancel();
    flutterSoundPlayer?.closeAudioSession();
    if (this.mounted) {
      setState(() {
        this.isPlaying = false;
      });
    }
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

    DatabaseMethods()
        .sendShout(myUID, yourUID, chatForYou, audioUID, current_time)
        .timeout(Duration(seconds: 5))
        .onError((error, stackTrace) {
      if (this.mounted) {
        setState(() {
          this.sendingShout = false;
        });
      }
      failedToSendSnackBar();
    }).then((value) {
      audioUID = null;
      if (this.mounted) {
        setState(() {
          this.sendingShout = false;
        });
      }
    });
  }
}
