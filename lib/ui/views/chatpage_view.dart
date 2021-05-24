import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:stacked/stacked.dart';
import 'package:tapemobileapp/viewmodel/chat_view_model.dart';

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
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Column(children: [
                            Text(yourName,
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis),
                            SizedBox(height: 8),
                            CurrentStatus()
                          ]),
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
        : YourStatus();
  }
}

class YourStatus extends ViewModelWidget<ChatViewModel> {
  @override
  Widget build(BuildContext context, ChatViewModel viewModel) {
    return Text(
      viewModel.status,
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
        PokeButton(),
        RecordButton(),
        SkipButton(),
      ],
    );
  }
}

class PokeButton extends ViewModelWidget<ChatViewModel> {
  @override
  Widget build(BuildContext context, ChatViewModel viewModel) {
    return SizedBox(
        width: 64,
        height: 64,
        child: RawMaterialButton(
          onPressed: () {
            viewModel.poke();
          },
          shape: CircleBorder(),
          child: Icon(
            PhosphorIcons.handWaving,
            size: 32,
          ),
        ));
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
          height: 56,
          width: 144,
          child: RawMaterialButton(
            shape: ContinuousRectangleBorder(
                borderRadius: BorderRadius.circular(24)),
            fillColor: Theme.of(context).accentColor,
            onPressed: null,
            child: Text('Tape',
                style: TextStyle(
                  color: Color(0xff2f2f2f),
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                )),
          ),
        ));
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
                size: 32,
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
                  radius: 88,
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
        height: 16,
      ),
      CenterStatusDisplay(),
    ]);
  }
}

class RecordingDisplay extends ViewModelWidget<ChatViewModel> {
  @override
  Widget build(BuildContext context, ChatViewModel viewModel) {
    return CircleAvatar(
      radius: 88,
      child: Text(
        viewModel.recordingTimer,
        style: TextStyle(
          fontSize: 48,
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
                          ? "${viewModel.yourName} sent a Tape!"
                          : "${viewModel.currentShoutPlaying.toString()} of ${viewModel.totalShouts.toString()}"
                      : viewModel.showClear()
                          ? "Hold to record, release to send!"
                          : viewModel.showSent()
                              ? "You sent a Tape!"
                              : viewModel.showShoutPlayed()
                                  ? "${viewModel.yourName} played your Tape!"
                                  : "Hold to record, and release to send!",
          style: TextStyle(
            fontSize: 16,
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
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ],
    );
  }
}

class ShoutsPlayerDisplay extends ViewModelWidget<ChatViewModel> {
  @override
  Widget build(BuildContext context, ChatViewModel viewModel) {
    return CircleAvatar(
      radius: 88,
      child: viewModel.isLoadingShout
          ? Container(
              width: 240,
              height: 240,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
          : IconButton(
              iconSize: 64,
              icon: viewModel.iAmListening
                  ? Icon(PhosphorIcons.stopFill)
                  : Icon(
                      PhosphorIcons.playFill,
                      color: Theme.of(context).accentColor,
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
      radius: 88,
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
