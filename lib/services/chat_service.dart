import 'dart:convert';

import 'package:flutter_sound/flutter_sound.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:stacked/stacked.dart';
import 'package:observable_ish/observable_ish.dart';

class ChatService with ReactiveServiceMixin {
  // recorder related variables
  FlutterSoundRecorder _flutterSoundRecorder = new FlutterSoundRecorder();
  var _flutterSoundRecorderSubscription;
  ReactiveValue<String> _recordingTime = ReactiveValue<String>("");

  // player related variables;
  FlutterSoundPlayer _flutterSoundPlayer = new FlutterSoundPlayer();
  var _flutterSoundPlayerSubscription;
  ReactiveValue<bool> _loadingShout = ReactiveValue<bool>(false);
  ReactiveValue<bool> _playingShout = ReactiveValue<bool>(false);

  String get recordingTime => _recordingTime.value;
  bool get isLoadingShout => _loadingShout.value;
  bool get isPlayingShout => _playingShout.value;

  ChatService() {
    listenToReactiveValues([_recordingTime, _loadingShout, _playingShout]);
  }

  cancelSubscriptions() {
    suspendRecording();
    suspendPlaying();
  }

  suspendPlaying() async {
    _playingShout.value = false;
    await _flutterSoundPlayerSubscription?.cancel();
    await _flutterSoundPlayer?.stopPlayer();
    await _flutterSoundPlayer?.closeAudioSession();
  }

  Future<void> suspendRecording() async {
    _recordingTime.value = "";
    await _flutterSoundRecorderSubscription?.cancel();
    await _flutterSoundRecorder?.stopRecorder();
    await _flutterSoundRecorder?.closeAudioSession();
  }

  startRecording(String path) async {
    await _flutterSoundRecorder.openAudioSession();
    _flutterSoundRecorderSubscription = _flutterSoundRecorder.onProgress.listen((event) {
      _recordingTime.value = event.duration.inSeconds.toString() + 's';
    });
    await _flutterSoundRecorder.setSubscriptionDuration(Duration(milliseconds: 500));
    await _flutterSoundRecorder.startRecorder(
      toFile: path,
      codec: Codec.aacADTS,
    );
  }

  Future<void> stopRecording() async {
    return suspendRecording();
  }

  Future startPlaying(String downloadURL, Function whenFinished) async {
    await suspendPlaying();
    _loadingShout.value = true;
    await _flutterSoundPlayer.openAudioSession();
    _flutterSoundPlayerSubscription = _flutterSoundPlayer.onProgress.listen((event) {
      if (_flutterSoundPlayer.playerState == PlayerState.isPlaying) {
        _loadingShout.value = false;
        _playingShout.value = true;
      } else {
        _loadingShout.value = true;
        _playingShout.value = false;
      }
    });
    await _flutterSoundPlayer.setSubscriptionDuration(Duration(milliseconds: 500));
    return _flutterSoundPlayer.startPlayer(
      fromURI: downloadURL,
      codec: Codec.mp3,
      whenFinished: () {
        _playingShout.value = false;
        _loadingShout.value = false;
        whenFinished();
      }
    );
  }

  Future<void> stopPlaying() async {
    return suspendPlaying();
  }
}