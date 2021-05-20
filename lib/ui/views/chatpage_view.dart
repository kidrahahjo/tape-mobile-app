import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:stacked/stacked.dart';
import 'package:wavemobileapp/viewmodel/chat_view_model.dart';

class ChatPageView extends StatelessWidget {
  final String yourUID;
  final String yourName;

  ChatPageView(this.yourUID, this.yourName);

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<ChatViewModel>.nonReactive(
      viewModelBuilder: () => ChatViewModel(yourUID, yourName),
      builder: (context, model, child) {
        return Scaffold(
            appBar: AppBar(
              title: Text(
                yourName,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              leading: IconButton(
                icon: Icon(
                  PhosphorIcons.caretLeft,
                  size: 32,
                ),
                onPressed: () => model.backToHome(),
              ),
            ),
            resizeToAvoidBottomInset: true,
            body: SafeArea(
                child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          CurrentStatus(),
                          CenterImageDisplay(),
                          MainFooter(),
                        ]))));
      },
    );
  }
}

class CurrentStatus extends ViewModelWidget<ChatViewModel> {
  CurrentStatus() : super(reactive: true);

  @override
  Widget build(BuildContext context, ChatViewModel viewModel) {
    return (viewModel.youAreRecording)
        ? Text(
            "Recording...",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          )
        : Text(
            "Vibing",
            style: TextStyle(),
          );
  }
}

class MainFooter extends ViewModelWidget<ChatViewModel> {
  MainFooter() : super(reactive: false);

  @override
  Widget build(BuildContext context, ChatViewModel viewModel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SendingShoutIndicator(),
        RecordButton(),
        SkipButton(),
      ],
    );
  }
}

class SendingShoutIndicator extends ViewModelWidget<ChatViewModel> {
  SendingShoutIndicator() : super(reactive: true);

  @override
  Widget build(BuildContext context, ChatViewModel viewModel) {
    return SizedBox(
      height: 80,
      width: 80,
      child: viewModel.sendingShout
          ? Center(
              child: CircularProgressIndicator(),
            )
          : null,
    );
  }
}

class RecordButton extends ViewModelWidget<ChatViewModel> {
  RecordButton() : super(reactive: true);

  @override
  Widget build(BuildContext context, ChatViewModel viewModel) {
    return GestureDetector(
      onTapDown: (details) {
        viewModel.startRecording();
      },
      onTapUp: (details) {
        viewModel.stopRecording();
      },
      onHorizontalDragEnd: (value) {
        viewModel.stopRecording();
      },
      child: SizedBox(
        height: 64,
        width: 64,
        child: RawMaterialButton(
          shape: CircleBorder(),
          fillColor: Colors.black87,
          onPressed: null,
          child: Icon(
            PhosphorIcons.voicemail,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class SkipButton extends ViewModelWidget<ChatViewModel> {
  SkipButton() : super(reactive: true);

  @override
  Widget build(BuildContext context, ChatViewModel viewModel) {
    return SizedBox(
        height: 80,
        width: 80,
        child: viewModel.currentShoutPlaying < viewModel.shoutQueue.length
            ? Padding(
                padding: EdgeInsets.only(top: 10, bottom: 10, left: 20),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  width: 60,
                  height: 60,
                  child: IconButton(
                    icon: Icon(
                      PhosphorIcons.skipForward,
                    ),
                    onPressed: () {
                      viewModel.playNextShout();
                    },
                  ),
                ),
              )
            : null);
  }
}

class CenterImageDisplay extends ViewModelWidget<ChatViewModel> {
  CenterImageDisplay() : super(reactive: true);

  @override
  Widget build(BuildContext context, ChatViewModel viewModel) {
    return Column(children: <Widget>[
      viewModel.iAmRecording
          ? RecordingDisplay()
          : viewModel.shoutQueue.length == 0
              ? CircularStatusAvatar()
              : ShoutsPlayerDisplay(),
      SizedBox(
        height: 24,
      ),
      CenterStatusDisplay(),
    ]);
  }
}

class RecordingDisplay extends ViewModelWidget<ChatViewModel> {
  @override
  Widget build(BuildContext context, ChatViewModel viewModel) {
    return CircleAvatar(
      radius: 120,
      child: Text(
        viewModel.recordingTimer,
        style: TextStyle(fontSize: 72, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class CenterStatusDisplay extends ViewModelWidget<ChatViewModel> {
  CenterStatusDisplay() : super(reactive: true);

  @override
  Widget build(BuildContext context, ChatViewModel viewModel) {
    return Column(
      children: [
        Text(
          viewModel.iAmRecording
              ? "Recording..."
              : viewModel.showPlayer()
                  ? viewModel.totalShouts == 1
                      ? "${viewModel.yourName} sent a shout!"
                      : "${viewModel.currentShoutPlaying.toString()} of ${viewModel.totalShouts.toString()}"
                  : viewModel.showClear()
                      ? "Hold to record, and release to send!"
                      : viewModel.showSent()
                          ? "You sent a shout!"
                          : viewModel.showShoutPlayed()
                              ? "${viewModel.yourName} played your shouts!"
                              : "Hold to record, and release to send!",
          style: TextStyle(),
        ),
        SizedBox(
          height: 4,
        ),
        Text(viewModel.iAmRecording
            ? ""
            : viewModel.showClear()
                ? ""
                : viewModel.getTime()),
      ],
    );
  }
}

class ShoutsPlayerDisplay extends ViewModelWidget<ChatViewModel> {
  @override
  Widget build(BuildContext context, ChatViewModel viewModel) {
    return Center(
      child: viewModel.isLoadingShout
          ? CircularProgressIndicator()
          : IconButton(
              icon: Icon(
                viewModel.iAmListening
                    ? PhosphorIcons.stop
                    : PhosphorIcons.play,
                size: 36,
              ),
              onPressed: () {
                if (viewModel.iAmListening) {
                  viewModel.stopPlaying();
                } else {
                  viewModel.startPlaying();
                }
              },
            ),
    );
  }
}

class CircularStatusAvatar extends ViewModelWidget<ChatViewModel> {
  @override
  Widget build(BuildContext context, ChatViewModel viewModel) {
    return CircleAvatar(
      radius: 120,
      child: Icon(
        viewModel.showClear()
            ? PhosphorIcons.microphoneFill
            : viewModel.showSent()
                ? PhosphorIcons.paperPlane
                : viewModel.showShoutPlayed()
                    ? PhosphorIcons.speakerSimpleHighFill
                    : PhosphorIcons.microphoneFill,
        size: 72,
      ),
    );
  }
}
