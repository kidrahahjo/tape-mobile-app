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
                    viewModel.iAmRecording
                        ? Text(
                            "Recording... ${viewModel.recordingTimer}",
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          )
                        : Text('Hold to talk',
                            style: TextStyle(color: Colors.grey)),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            PokeButton(),
                            SizedBox(width: 120),
                            MoodButton()
                          ],
                        ),
                        RecordButton(),
                      ],
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
                                initCategory: Category.RECENT,
                                bgColor: Color(0xFF000000),
                                indicatorColor: Theme.of(context).accentColor,
                                iconColor: Colors.grey.shade700,
                                iconColorSelected:
                                    Theme.of(context).accentColor,
                                progressIndicatorColor:
                                    Theme.of(context).accentColor,
                                showRecentsTab: true,
                                recentsLimit: 48,
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
    viewModel.showPokeSnackBar(context);
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
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      width: viewModel.boxLength,
      height: 72,
      decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(100)),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: DragTarget<bool>(onMove: (data) {
              viewModel.deleteRecording();
              viewModel.contractBox();
            }, builder: (context, button, rejects) {
              return button.length > 0
                  ? null
                  : Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.transparent,
                          child: Icon(
                            PhosphorIcons.trashFill,
                            size: 28,
                            color: Colors.deepOrange,
                          )),
                    );
            }),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: DragTarget<bool>(
              onMove: (value) {
                if (viewModel.boxExpanded) {
                  viewModel.contractBox();
                  viewModel.stopRecording();
                }
              },
              builder: (context, button, rejects) {
                return button.length > 0
                    ? null
                    : Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: CircleAvatar(
                            radius: 32,
                            backgroundColor: Colors.transparent,
                            child: Icon(
                              PhosphorIcons.paperPlaneFill,
                              size: 28,
                              color: Theme.of(context).accentColor,
                            )),
                      );
              },
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Draggable<bool>(
              onDragStarted: () {
                if (!viewModel.boxExpanded) {
                  viewModel.startRecording();
                  viewModel.expandBox();
                }
              },
              data: true,
              axis: Axis.horizontal,
              feedback: SizedBox(
                height: 64,
                width: 64,
                child: RawMaterialButton(
                    shape: CircleBorder(),
                    fillColor: Colors.white,
                    onPressed: null,
                    child: Icon(
                      PhosphorIcons.microphoneFill,
                      color: Theme.of(context).accentColor,
                    )),
              ),
              child: SizedBox(
                height: 64,
                width: 64,
                child: RawMaterialButton(
                  shape: CircleBorder(),
                  fillColor: viewModel.boxExpanded
                      ? Colors.white
                      : Theme.of(context).accentColor,
                  onPressed: null,
                  child: Icon(
                    PhosphorIcons.microphoneFill,
                    color: viewModel.boxExpanded
                        ? Theme.of(context).accentColor
                        : Colors.white,
                  ),
                ),
              ),
              childWhenDragging: CircleAvatar(
                radius: 32,
                backgroundColor: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
