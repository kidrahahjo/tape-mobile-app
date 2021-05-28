import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:stacked/stacked.dart';
import 'package:tapemobileapp/viewmodel/chat_view_model.dart';

import 'package:flutter_svg/flutter_svg.dart';

class ChatPageView extends StatelessWidget {
  final String yourUID;
  final String yourName;

  ChatPageView(this.yourUID, this.yourName);

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<ChatViewModel>.reactive(
      viewModelBuilder: () => ChatViewModel(yourUID, yourName),
      builder: (context, model, child) {
        return Scaffold(
          bottomNavigationBar: BottomAppBar(
            color: Colors.grey.shade900,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: RecordButton(),
            ),
          ),
          body: CustomScrollView(
            controller: model.scrollController,
            slivers: [
              SliverAppBar(
                actions: [PokeButton()],
                leading: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(PhosphorIcons.caretLeft)),
                pinned: true,
                stretch: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(yourName),
                ),
              ),
              TapeArea(),
            ],
          ),
        );
      },
    );
  }
}

class TapeArea extends ViewModelWidget<ChatViewModel> {
  TapeArea() : super(reactive: true);
  @override
  Widget build(BuildContext context, ChatViewModel viewModel) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (BuildContext context, int index) {
            return Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color:
                        viewModel.tapeList.elementAt(index).containsValue(true)
                            ? Theme.of(context).accentColor
                            : Colors.grey.shade900,
                  ),
                  padding: EdgeInsets.all(12),
                  child: viewModel.tapeList.elementAt(index).containsValue(true)
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                                onPressed: () {
                                  viewModel.playMyTape(viewModel.tapeList
                                      .elementAt(index)
                                      .keys
                                      .first);
                                },
                                icon: Icon(PhosphorIcons.playFill)),
                            CircleAvatar(
                              backgroundColor: Colors.white,
                              radius: 24,
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.white,
                              radius: 24,
                            ),
                            IconButton(
                                onPressed: () {
                                  viewModel.playYourTape(viewModel.tapeList
                                      .elementAt(index)
                                      .keys
                                      .first);
                                },
                                icon: Icon(PhosphorIcons.playFill)),
                          ],
                        ),
                ),
                SizedBox(height: 8),
              ],
            );
          },
          childCount:
              viewModel.tapeList == null ? 0 : viewModel.tapeList.length,
        ),
      ),
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
          ),
        ));
  }
}

class RecordButton extends ViewModelWidget<ChatViewModel> {
  RecordButton() : super(reactive: true);
  final String tapeIcon = 'assets/icon/tape_icon.svg';

  @override
  Widget build(BuildContext context, ChatViewModel viewModel) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Hold to talk',
          style: TextStyle(color: Colors.grey),
        ),
        SizedBox(height: 12),
        GestureDetector(
            onTapDown: (details) {
              viewModel.startRecording();
            },
            onTapUp: (details) {
              viewModel.stopRecording();
            },
            onVerticalDragEnd: (value) {
              viewModel.stopRecording();
              print("vertical");
            },
            onHorizontalDragEnd: (value) {
              viewModel.stopRecording();

              print("horizontal");
            },
            child: SizedBox(
              height: 64,
              width: 64,
              child: RawMaterialButton(
                shape: CircleBorder(),
                fillColor: Theme.of(context).accentColor,
                onPressed: null,
                child: SvgPicture.asset(
                  tapeIcon,
                  semanticsLabel: 'Tape Logo',
                  height: 48,
                  width: 48,
                ),
              ),
            )),
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
