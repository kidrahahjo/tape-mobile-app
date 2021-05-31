import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:stacked/stacked.dart';
import 'package:tapemobileapp/viewmodel/chat_view_model.dart';
import 'package:avatar_glow/avatar_glow.dart';

class ChatPageView extends StatelessWidget {
  final String yourUID;
  final String yourName;

  ChatPageView(this.yourUID, this.yourName);

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<ChatViewModel>.reactive(
      viewModelBuilder: () => ChatViewModel(yourUID, yourName, context),
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
                      SizedBox(
                        height: 64,
                        width: 64,
                        child: AvatarGlow(
                          animate: model.showGlow,
                          curve: Curves.easeOutCubic,
                          glowColor: Colors.white,
                          endRadius: 32.0,
                          duration: Duration(milliseconds: 1500),
                          repeat: false,
                          showTwoGlows: true,
                          repeatPauseDuration: Duration(milliseconds: 100),
                          child: Center(
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
                        ),
                      ),
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
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        AppBar(
                          automaticallyImplyLeading: false,
                          centerTitle: false,
                          title: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 12,
                            children: [
                              Text("React with earmojis"),
                              Icon(
                                PhosphorIcons.speakerSimpleHighFill,
                                color: Colors.white,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          height: 360,
                          child: GridView.builder(
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: viewModel.moodEmojiMapping.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 5),
                            itemBuilder: (context, index) {
                              return RawMaterialButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  viewModel.updateMyMood(viewModel
                                      .moodEmojiMapping.keys
                                      .toList()[index]);
                                },
                                shape: CircleBorder(),
                                child: Text(
                                  viewModel.moodEmojiMapping.keys
                                              .toList()[index] ==
                                          "heart"
                                      ? "❤️"
                                      : viewModel.moodEmojiMapping.keys
                                          .toList()[index],
                                  style: TextStyle(fontSize: 40),
                                ),
                              );
                            },
                          ),
                        ),
                      ]));
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
