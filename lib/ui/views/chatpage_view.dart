import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:stacked/stacked.dart';
import 'package:tapemobileapp/viewmodel/chat_view_model.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

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
                physics: BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics()),
                slivers: [
                  SliverAppBar(
                    expandedHeight: 250,
                    actions: [
                      Center(
                        child: model.yourMood == null
                            ? Icon(
                                PhosphorIcons.smiley,
                                color: Colors.grey.shade700,
                                size: 28,
                              )
                            : Text(
                                model.yourMood,
                                style: TextStyle(fontSize: 28),
                              ),
                      ),
                      SizedBox(width: 16)
                    ],
                    leading: IconButton(
                        onPressed: () => model.backToHome(),
                        icon: Icon(PhosphorIcons.caretLeft)),
                    pinned: true,
                    stretch: true,
                    flexibleSpace: FlexibleSpaceBar(
                      collapseMode: CollapseMode.pin,
                      centerTitle: true,
                      background: Center(child: ProfilePic(yourName)),
                      title: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        children: [
                          Icon(
                            PhosphorIcons.circleFill,
                            color: Colors.transparent,
                            size: 8,
                          ),
                          Text(
                            yourName,
                            overflow: TextOverflow.fade,
                          ),
                          Icon(
                            PhosphorIcons.circleFill,
                            color: model.youAreOnline
                                ? Colors.green
                                : Colors.transparent,
                            size: 8,
                          )
                        ],
                      ),
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

class ProfilePic extends ViewModelWidget<ChatViewModel> {
  final String yourName;
  ProfilePic(this.yourName);
  @override
  Widget build(BuildContext context, ChatViewModel viewModel) {
    return CircleAvatar(
      radius: 60,
      child: viewModel.profilePic == null
          ? Text(
              '${this.yourName[0]}'.toUpperCase(),
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
      backgroundImage: viewModel.profilePic == null
          ? null
          : NetworkImage(viewModel.profilePic),
    );
  }
}

class Footer extends ViewModelWidget<ChatViewModel> {
  Footer() : super(reactive: true);
  @override
  Widget build(BuildContext context, ChatViewModel viewModel) {
    return Container(
      height: 180,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            children: [
              Divider(),
              SizedBox(height: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    viewModel.drawerOpen
                        ? Text(
                            "Recording... ${viewModel.recordingTimer}",
                            style: TextStyle(
                              color: Theme.of(context).accentColor,
                              fontSize: 14,
                            ),
                          )
                        : Text('Hold to talk',
                            style: TextStyle(color: Colors.grey)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [PokeButton(), RecordButton(), MoodButton()],
                    ),
                    SizedBox(height: 0),
                  ],
                ),
              ),
            ],
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
                SizedBox(height: viewModel.getGap(index)),
                viewModel.showTape(index, context),
              ],
            );
          },
          childCount: viewModel.allTapes.length,
        ),
      ),
    );
  }
}

class MoodButton extends ViewModelWidget<ChatViewModel> {
  @override
  Widget build(BuildContext context, ChatViewModel viewModel) {
    return SizedBox(
      height: 48,
      width: 48,
      child: RawMaterialButton(
          onPressed: () {
            showModalBottomSheet(
                isDismissible: true,
                isScrollControlled: true,
                context: context,
                enableDrag: true,
                builder: (BuildContext context) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SafeArea(
                            child: SizedBox(
                          height: 320,
                          child: EmojiPicker(
                            onEmojiSelected: (category, emoji) {
                              viewModel.updateMyMood(emoji.emoji);
                              Navigator.pop(context);
                              // Do something when emoji is tapped
                            },
                            // onBackspacePressed: () {
                            //   // Backspace-Button tapped logic
                            //   // Remove this line to also remove the button in the UI
                            // },
                            config: Config(
                                columns: 8,
                                emojiSizeMax: 32.0,
                                verticalSpacing: 0,
                                horizontalSpacing: 0,
                                initCategory: Category.SMILEYS,
                                bgColor: Color(0xFF000000),
                                indicatorColor: Theme.of(context).accentColor,
                                iconColor: Colors.grey.shade700,
                                iconColorSelected:
                                    Theme.of(context).accentColor,
                                progressIndicatorColor:
                                    Theme.of(context).accentColor,
                                showRecentsTab: true,
                                recentsLimit: 28,
                                noRecentsText: "No Recents",
                                noRecentsStyle: const TextStyle(
                                    fontSize: 20, color: Colors.grey),
                                categoryIcons: const CategoryIcons(),
                                buttonMode: ButtonMode.CUPERTINO),
                          ),
                        )),
                      ],
                    ),
                  );
                });
          },
          child: CircleAvatar(
            backgroundColor: Colors.grey.shade900,
            child: viewModel.myMood == null
                ? Icon(
                    PhosphorIcons.smiley,
                    color: Colors.white,
                    size: 28,
                  )
                : Text(
                    viewModel.myMood,
                    style: TextStyle(fontSize: 28),
                  ),
            radius: 24,
          )),
    );
  }
}

class PokeButton extends ViewModelWidget<ChatViewModel> {
  @override
  Widget build(BuildContext context, ChatViewModel viewModel) {
    return SizedBox(
        width: 48,
        height: 48,
        child: RawMaterialButton(
          fillColor: Colors.grey.shade900,
          onPressed: () {
            viewModel.poke();
          },
          shape: CircleBorder(),
          child: Icon(
            PhosphorIcons.handWavingLight,
            size: 28,
          ),
        ));
  }
}

class RecordButton extends ViewModelWidget<ChatViewModel> {
  RecordButton() : super(reactive: true);
  final String tapeIcon = 'assets/icon/tape_icon.svg';

  @override
  Widget build(BuildContext context, ChatViewModel viewModel) {
    return GestureDetector(
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
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          height: viewModel.buttonSize,
          child: RawMaterialButton(
            shape: CircleBorder(),
            fillColor: Theme.of(context).accentColor,
            onPressed: null,
            child: SvgPicture.asset(
              tapeIcon,
              semanticsLabel: 'Tape Logo',
              height: 44,
              width: 44,
            ),
          ),
        ));
  }
}
