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
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
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
              color: Theme.of(context).accentColor,
            ),
          )
        : Text(
            "Vibing",
            style: TextStyle(
              fontSize: 16,
            ),
          );
  }
}

class MainFooter extends ViewModelWidget<ChatViewModel> {
  MainFooter() : super(reactive: false);

  @override
  Widget build(BuildContext context, ChatViewModel viewModel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        SizedBox(
          width: 64,
          height: 64,
        ),
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
        height: 72,
        width: 72,
        child: RawMaterialButton(
          shape: CircleBorder(),
          fillColor: Theme.of(context).accentColor,
          onPressed: null,
          child: Icon(
            PhosphorIcons.voicemail,
            color: Colors.black,
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
      width: 64,
      height: 64,
      child: viewModel.totalShouts != 0
          ? RawMaterialButton(
              onPressed: () {
                viewModel.skip();
              },
              shape: CircleBorder(),
              child: Icon(
                PhosphorIcons.skipForward,
              ),
            )
          : null,
    );
  }
}

class CenterImageDisplay extends ViewModelWidget<ChatViewModel> {
  CenterImageDisplay() : super(reactive: true);

  @override
  Widget build(BuildContext context, ChatViewModel viewModel) {
    return Column(children: <Widget>[
      viewModel.iAmRecording
          ? RecordingDisplay()
          : viewModel.sendingShout
              ? CircleAvatar(
                  radius: 120,
                  child: Stack(children: [
                    Center(
                      child: Icon(
                        PhosphorIcons.paperPlaneThin,
                        size: 64,
                        color: Colors.grey,
                      ),
                    ),
                    Container(
                      width: 240,
                      height: 240,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    ),
                  ]),
                )
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
        style: TextStyle(
          fontSize: 56,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).accentColor,
        ),
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
              : viewModel.sendingShout
                  ? "Sending..."
                  : viewModel.showPlayer()
                      ? viewModel.totalShouts == 1
                          ? "${viewModel.yourName} sent a shout!"
                          : "${viewModel.currentShoutPlaying.toString()} of ${viewModel.totalShouts.toString()}"
                      : viewModel.showClear()
                          ? "Hold to record, release to send!"
                          : viewModel.showSent()
                              ? "You sent a shout!"
                              : viewModel.showShoutPlayed()
                                  ? "${viewModel.yourName} played your shouts!"
                                  : "Hold to record, and release to send!",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(
          height: 8,
        ),
        Text(
          viewModel.iAmRecording
              ? ""
              : viewModel.sendingShout
                  ? ""
                  : viewModel.showClear()
                      ? ""
                      : viewModel.getTime(),
          style: TextStyle(fontSize: 16),
        ),
      ],
    );
  }
}

class ShoutsPlayerDisplay extends ViewModelWidget<ChatViewModel> {
  @override
  Widget build(BuildContext context, ChatViewModel viewModel) {
    return CircleAvatar(
      radius: 120,
      backgroundColor: Theme.of(context).accentColor.withOpacity(0.3),
      child: viewModel.isLoadingShout
          ? CircularProgressIndicator()
          : IconButton(
              iconSize: 64,
              icon: Icon(
                viewModel.iAmListening
                    ? PhosphorIcons.stopThin
                    : PhosphorIcons.playThin,
                color: Colors.black,
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
            ? PhosphorIcons.voicemailThin
            : viewModel.showSent()
                ? PhosphorIcons.paperPlaneThin
                : viewModel.showShoutPlayed()
                    ? PhosphorIcons.speakerSimpleHighThin
                    : PhosphorIcons.voicemailThin,
        size: 64,
        color: Theme.of(context).accentColor,
      ),
    );
  }
}
