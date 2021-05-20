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
                onPressed: () => Navigator.of(context).pop(),
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

// class MainHeader extends ViewModelWidget<ChatViewModel> {
//   MainHeader() : super(reactive: false);

//   @override
//   Widget build(BuildContext context, ChatViewModel viewModel) {
//     return Container(
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: <Widget>[
//           IconButton(
//               icon: Icon(
//                 PhosphorIcons.caretLeft,
//                 size: 32,
//               ),
//               onPressed: () {
//                 viewModel.backToHome();
//               }),
//           Column(children: [
//             SizedBox(
//               height: 8,
//             ),
//             Text(
//               viewModel.yourName,
//               style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
//             ),
//             SizedBox(
//               height: 8,
//             ),
//             CurrentStatus(),
//           ]),
//           SizedBox(
//             height: 48,
//             width: 48,
//           ),
//         ],
//       ),
//     );
//   }
// }

class CurrentStatus extends ViewModelWidget<ChatViewModel> {
  CurrentStatus() : super(reactive: true);

  @override
  Widget build(BuildContext context, ChatViewModel viewModel) {
    return (viewModel.youAreRecording || viewModel.youAreListening)
        ? Text(
            viewModel.youAreRecording ? "Recording..." : "Listening...",
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
              : viewModel.shoutQueue.length == 0
                  ? (viewModel.numberOfLonelyShouts == null &&
                          viewModel.myFirstShoutSent == null)
                      ? "Hold to record, and release to send!"
                      : viewModel.hasPlayed
                          ? "${viewModel.yourName} played your shouts!"
                          : viewModel.numberOfLonelyShouts == 0
                              ? ""
                              : "You sent ${viewModel.numberOfLonelyShouts} shouts!"
                  : viewModel.shoutQueue.length == 1
                      ? "${viewModel.yourName} sent a shout!"
                      : "${viewModel.currentShoutPlaying.toString()} of ${viewModel.shoutQueue.length.toString()}",
          style: TextStyle(),
        ),
        SizedBox(
          height: 4,
        ),
        Text('5m ago')
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
                viewModel.showReplay
                    ? PhosphorIcons.arrowCounterClockwise
                    : viewModel.iAmListening
                        ? PhosphorIcons.stop
                        : PhosphorIcons.play,
                size: 36,
              ),
              onPressed: () {
                if (viewModel.showReplay) {
                  viewModel.replayShouts();
                } else if (viewModel.iAmListening) {
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
        (viewModel.numberOfLonelyShouts == null &&
                viewModel.myFirstShoutSent == null)
            ? PhosphorIcons.microphoneFill
            : viewModel.hasPlayed
                ? PhosphorIcons.paperPlaneTiltFill
                : viewModel.numberOfLonelyShouts == 0
                    ? PhosphorIcons.microphoneFill
                    : PhosphorIcons.paperPlaneTiltFill,
        size: 72,
      ),
    );
  }
}
