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
    return ViewModelBuilder<ChatViewModel>.reactive(
      viewModelBuilder: () => ChatViewModel(yourUID, yourName),
      builder: (context, model, child) {
        return SafeArea(
          child: Container(
            child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 0),
                child: Column(children: <Widget>[
                  SizedBox(height: 48),
                  Container(
                    height: 6,
                    width: 40,
                    decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(.4),
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  SizedBox(height: 32),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    subtitle: CurrentStatus(),
                    title: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        children: [
                          Text(
                            yourName,
                            style: TextStyle(fontSize: 28),
                          ),
                          Icon(
                            PhosphorIcons.circleFill,
                            color: model.youAreOnline
                                ? Colors.green
                                : Colors.transparent,
                            size: 12,
                          )
                        ]),
                  ),
                  SizedBox(
                    height: 24,
                  ),
                  AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Theme.of(context).primaryColorLight,
                      ),
                      child: Center(child: CenterImageDisplay()),
                    ),
                  ),
                  SizedBox(
                    height: 32,
                  ),
                  CenterStatusDisplay(),
                  SizedBox(
                    height: 32,
                  ),
                  Divider(
                    height: 1,
                  ),
                  Expanded(child: MainFooter()),
                ])),
          ),
        );
      },
    );
  }
}

class CurrentStatus extends ViewModelWidget<ChatViewModel> {
  CurrentStatus() : super(reactive: true);

  @override
  Widget build(BuildContext context, ChatViewModel viewModel) {
    return viewModel.youAreRecording
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
      textAlign: TextAlign.left,
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
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        PokeButton(),
        SizedBox(width: 16),
        RecordButton(),
        SizedBox(width: 16),
        SkipButton(),
      ],
    );
  }
}

class PokeButton extends ViewModelWidget<ChatViewModel> {
  @override
  Widget build(BuildContext context, ChatViewModel viewModel) {
    return SizedBox(
        width: 72,
        height: 72,
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
          height: 72,
          width: 72,
          child: RawMaterialButton(
            shape: CircleBorder(),
            fillColor: Theme.of(context).accentColor,
            onPressed: null,
            child: Icon(PhosphorIcons.voicemail, size: 36, color: Colors.white),
          ),
        ));
  }
}

class SkipButton extends ViewModelWidget<ChatViewModel> {
  SkipButton() : super(reactive: true);

  @override
  Widget build(BuildContext context, ChatViewModel viewModel) {
    return SizedBox(
      width: 72,
      height: 72,
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        viewModel.poked
            ? CircleAvatar(
                backgroundColor: Colors.transparent,
                radius: 72,
                child: Icon(
                  PhosphorIcons.handWavingThin,
                  size: 60,
                  color: Theme.of(context).accentColor,
                ),
              )
            : viewModel.iAmRecording
                ? RecordingDisplay()
                : viewModel.sendingShout
                    ? CircleAvatar(
                        backgroundColor: Colors.transparent,
                        radius: 72,
                        child: Stack(children: [
                          Center(
                            child: Icon(
                              PhosphorIcons.paperPlaneThin,
                              size: 60,
                              color: Theme.of(context).accentColor,
                            ),
                          ),
                          Center(
                            child: Container(
                              width: 144,
                              height: 144,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                        ]),
                      )
                    : viewModel.shoutQueue.length == 0
                        ? CircularStatusAvatar()
                        : ShoutsPlayerDisplay(),
      ],
    );
  }
}

class RecordingDisplay extends ViewModelWidget<ChatViewModel> {
  @override
  Widget build(BuildContext context, ChatViewModel viewModel) {
    return CircleAvatar(
      backgroundColor: Colors.transparent,
      radius: 72,
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
          viewModel.poked
              ? "You waved at ${viewModel.yourName}"
              : viewModel.iAmRecording
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
          height: 4,
        ),
        Text(
          viewModel.iAmRecording ||
                  viewModel.poked ||
                  viewModel.sendingShout ||
                  viewModel.showClear()
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
      backgroundColor: Colors.transparent,
      radius: 72,
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
      backgroundColor: Colors.transparent,
      radius: 72,
      child: Icon(
        viewModel.showClear()
            ? PhosphorIcons.voicemailThin
            : viewModel.showSent()
                ? PhosphorIcons.paperPlaneThin
                : viewModel.showShoutPlayed()
                    ? PhosphorIcons.speakerSimpleHighThin
                    : PhosphorIcons.voicemailThin,
        size: 60,
        color: Colors.grey,
      ),
    );
  }
}
