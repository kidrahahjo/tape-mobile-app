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
          body: Column(children: [
            Expanded(
              child: CustomScrollView(
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
            ),
            Footer(),
          ]),
        );
      },
    );
  }
}

class Footer extends ViewModelWidget<ChatViewModel> {
  @override
  Widget build(BuildContext context, ChatViewModel viewModel) {
    return Container(
      color: Colors.grey.shade900,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [RecordButton()],
          ),
        ),
      ),
    );
  }
}

class TapeArea extends ViewModelWidget<ChatViewModel> {
  TapeArea() : super(reactive: true);

  @override
  Widget build(BuildContext context, ChatViewModel viewModel) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (BuildContext context, int index) {
            return Column(
              children: [
                viewModel.showTape(index, context),
                SizedBox(height: 4),
              ],
            );
          },
          childCount: viewModel.allTapes.length,
        ),
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
        viewModel.iAmRecording
            ? Text(
                "Recording...",
                style: TextStyle(
                    color: Theme.of(context).accentColor,
                    fontWeight: FontWeight.bold),
              )
            : Text('Hold to talk', style: TextStyle(color: Colors.grey)),
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
            },
            onHorizontalDragEnd: (value) {
              viewModel.stopRecording();
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
